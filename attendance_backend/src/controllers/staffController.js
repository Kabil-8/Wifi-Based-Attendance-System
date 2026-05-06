const Class = require("../models/Class");
const Attendance = require("../models/Attendance");
const User = require("../models/User");


// ==========================
// GET STAFF DASHBOARD
// ==========================
// Returns { staffName, department, stats: { classes, students, today } }
exports.getDashboard = async (req, res) => {
  try {
    const staffId = req.user.id;

    // Fetch staff user for name & department
    const staffUser = await User.findById(staffId).lean();
    if (!staffUser) {
      return res.status(404).json({ message: "Staff user not found" });
    }

    // Find classes where this staff is an instructor in ANY subject
    const classes = await Class.find({
      "subjects.instructor": staffId,
    }).lean();

    // Count unique students across all those classes
    const studentIdSet = new Set();
    classes.forEach((cls) => {
      (cls.students || []).forEach((sid) => studentIdSet.add(sid.toString()));
    });

    // Count today's attendance across the staff's class codes
    const classCodes = classes.map((c) => c.classCode);
    const today = new Date().toISOString().split("T")[0];
    const todayCount = await Attendance.countDocuments({
      class: { $in: classCodes },
      date: today,
    });

    res.json({
      staffName: staffUser.name,
      department: staffUser.department || "",
      stats: {
        classes: classes.length,
        students: studentIdSet.size,
        today: todayCount,
      },
    });
  } catch (err) {
    console.error("getDashboard error:", err);
    res.status(500).json({ message: "Failed to load dashboard" });
  }
};


// ==========================
// GET STAFF CLASSES
// ==========================
exports.getStaffClasses = async (req, res) => {
  try {
    const staffId = req.user.id;

    // Query classes where this user is an instructor on any subject
    const classes = await Class.find({
      "subjects.instructor": staffId,
    }).populate("students", "name email studentId rollNo");

    res.json(classes);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Failed to fetch classes" });
  }
};

// ==========================
// GET CLASS ATTENDANCE
// ==========================
exports.getClassAttendance = async (req, res) => {
  try {
    const { classId } = req.params;

    const attendance = await Attendance.find({ class: classId })
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

    // Find all class codes for this staff member
    const classes = await Class.find({
      "subjects.instructor": staffId,
    }).lean();

    const classCodes = classes.map((c) => c.classCode);

    const reports = await Attendance.find({
      class: { $in: classCodes },
    }).sort({ date: -1 });

    res.json(reports);
  } catch (err) {
    res.status(500).json({ message: "Failed to load reports" });
  }
};

// ==========================
// GET CLASS STUDENTS
// ==========================
exports.getClassStudents = async (req, res) => {
  try {
    const { classId } = req.params;
    const targetClass = await Class.findOne({ classCode: classId }).populate("students", "name studentId rollNo email");
    
    if (!targetClass) {
      return res.status(404).json({ message: "Class not found" });
    }

    res.json({
      success: true,
      students: targetClass.students.map(s => ({
        id: s._id,
        name: s.name,
        studentId: s.studentId,
        roll: s.rollNo,
        email: s.email
      }))
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Failed to fetch students" });
  }
};
