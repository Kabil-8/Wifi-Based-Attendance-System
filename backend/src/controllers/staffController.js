const Class = require("../models/Class");
const Attendance = require("../models/Attendance");
const User = require("../models/User");

// ==========================
// GET STAFF DASHBOARD
// ==========================
exports.getDashboard = async (req, res) => {
  try {
    const staffId = req.user.id;

    const staff = await User.findById(staffId).select("name department");

    // Count classes where this staff is instructor or creator
    const classCount = await Class.countDocuments({
      $or: [
        { "subjects.instructor": staffId },
        { staff: staffId },
        { createdBy: staffId }
      ]
    });

    const classes = await Class.find({
      $or: [
        { "subjects.instructor": staffId },
        { staff: staffId },
        { createdBy: staffId }
      ]
    }).select("students");

    const studentSet = new Set();
    for (const cls of classes) {
      (cls.students || []).forEach(s => studentSet.add(s.toString()));
    }

    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);
    const todayCount = await Attendance.countDocuments({
      staff: staffId,
      date: { $gte: startOfDay }
    });

    res.json({
      success: true,
      staffName: staff?.name ?? req.user.name ?? "Staff",
      department: staff?.department ?? req.user.department ?? "",
      stats: {
        classes: classCount,
        students: studentSet.size,
        today: todayCount
      }
    });
  } catch (err) {
    console.error("Dashboard error:", err);
    res.status(500).json({ success: false, message: "Failed to load dashboard" });
  }
};

// ==========================
// GET STAFF CLASSES
// ==========================
exports.getStaffClasses = async (req, res) => {
  try {
    const staffId = req.user.id;

    const classes = await Class.find({
      $or: [
        { "subjects.instructor": staffId },
        { staff: staffId },
        { createdBy: staffId }
      ]
    }).select("classCode className department semester subjects location");

    res.json({ success: true, classes });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: "Failed to fetch classes" });
  }
};

// ==========================
// GET CLASS ATTENDANCE
// ==========================
exports.getClassAttendance = async (req, res) => {
  try {
    const { classId } = req.params;

    const attendance = await Attendance.find({ class: classId })
      .populate("student", "name rollNo")
      .sort({ date: -1 });

    res.json(attendance);
  } catch (err) {
    res.status(500).json({ message: "Failed to fetch attendance" });
  }
};

// ==========================
// MARK CLASS ATTENDANCE
// ==========================
exports.markClassAttendance = async (req, res) => {
  try {
    const { classId } = req.params;
    const { date, records } = req.body;

    const created = await Attendance.create({
      class: classId,
      staff: req.user.id,
      date,
      records,
    });

    res.status(201).json(created);
  } catch (err) {
    res.status(500).json({ message: "Failed to mark attendance" });
  }
};

// ==========================
// MODIFY ATTENDANCE
// ==========================
exports.modifyAttendance = async (req, res) => {
  try {
    const { attendanceId } = req.params;

    const updated = await Attendance.findByIdAndUpdate(
      attendanceId,
      req.body,
      { new: true }
    );

    res.json(updated);
  } catch (err) {
    res.status(500).json({ message: "Failed to modify attendance" });
  }
};

// ==========================
// GET ATTENDANCE REPORTS
// ==========================
exports.getAttendanceReports = async (req, res) => {
  try {
    const staffId = req.user.id;

    const reports = await Attendance.find({ staff: staffId })
      .populate("class", "name")
      .populate("student", "name");

    res.json(reports);
  } catch (err) {
    res.status(500).json({ message: "Failed to load reports" });
  }
};

// ==========================
// UPDATE CLASS WIFI SSID & ROOM
// ==========================
exports.updateClassWifi = async (req, res) => {
  try {
    const { classId } = req.params;
    const { wifiSSID, room, building } = req.body;

    if (!wifiSSID) {
      return res.status(400).json({ success: false, message: "wifiSSID is required" });
    }

    const updated = await Class.findByIdAndUpdate(
      classId,
      {
        $set: {
          "location.wifiRouter": wifiSSID,
          "location.room": room || "",
          "location.building": building || "",
          updatedAt: Date.now()
        }
      },
      { new: true }
    );

    if (!updated) {
      return res.status(404).json({ success: false, message: "Class not found" });
    }

    res.json({ success: true, message: "WiFi SSID updated successfully", class: updated });
  } catch (err) {
    console.error("Update WiFi error:", err);
    res.status(500).json({ success: false, message: "Failed to update WiFi SSID" });
  }
};

// ==========================
// GET CLASS SUBJECTS
// ==========================
exports.getClassSubjects = async (req, res) => {
  try {
    const { classId } = req.params;

    const cls = await Class.findById(classId)
      .populate("subjects.instructor", "name email")
      .select("subjects className classCode");

    if (!cls) {
      return res.status(404).json({ success: false, message: "Class not found" });
    }

    res.json({
      success: true,
      subjects: cls.subjects,
      className: cls.className,
      classCode: cls.classCode
    });
  } catch (err) {
    console.error("Get subjects error:", err);
    res.status(500).json({ success: false, message: "Failed to fetch subjects" });
  }
};

// ==========================
// ADD SUBJECT TO CLASS
// ==========================
exports.addSubject = async (req, res) => {
  try {
    const { classId } = req.params;
    const { code, name, schedule } = req.body;

    if (!code || !name) {
      return res.status(400).json({ success: false, message: "Subject code and name are required" });
    }

    const cls = await Class.findById(classId);
    if (!cls) {
      return res.status(404).json({ success: false, message: "Class not found" });
    }

    const exists = cls.subjects.some(s => s.code === code);
    if (exists) {
      return res.status(409).json({ success: false, message: "Subject with this code already exists" });
    }

    cls.subjects.push({
      code,
      name,
      instructor: req.user.id,
      schedule: schedule || {}
    });
    cls.updatedAt = Date.now();
    await cls.save();

    res.status(201).json({ success: true, message: "Subject added successfully", subjects: cls.subjects });
  } catch (err) {
    console.error("Add subject error:", err);
    res.status(500).json({ success: false, message: "Failed to add subject" });
  }
};

// ==========================
// DELETE SUBJECT FROM CLASS
// ==========================
exports.deleteSubject = async (req, res) => {
  try {
    const { classId, subjectCode } = req.params;

    const cls = await Class.findById(classId);
    if (!cls) {
      return res.status(404).json({ success: false, message: "Class not found" });
    }

    const initialLength = cls.subjects.length;
    cls.subjects = cls.subjects.filter(s => s.code !== subjectCode);

    if (cls.subjects.length === initialLength) {
      return res.status(404).json({ success: false, message: "Subject not found" });
    }

    cls.updatedAt = Date.now();
    await cls.save();

    res.json({ success: true, message: "Subject deleted successfully", subjects: cls.subjects });
  } catch (err) {
    console.error("Delete subject error:", err);
    res.status(500).json({ success: false, message: "Failed to delete subject" });
  }
};
