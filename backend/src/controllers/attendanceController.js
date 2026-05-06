const Attendance = require("../models/Attendance");
const User = require("../models/User");
const Class = require("../models/Class");
const AttendanceRequest = require("../models/AttendanceRequest");
const jwt = require("jsonwebtoken");

// @desc    Mark attendance
exports.markAttendance = async (req, res) => {
  try {
    const { method, router: wifiRouter, class: className, subject } = req.body;
    const studentId = req.user.studentId || req.user.id;
    
    if (!studentId) {
      return res.status(400).json({
        success: false,
        message: "Student ID is required"
      });
    }

    // Get today's date
    const today = new Date();
    const dateString = today.toISOString().split('T')[0];
    const timeString = today.toTimeString().split(' ')[0];

    // Check if attendance already marked today
    const existingAttendance = await Attendance.findOne({
      studentId,
      date: dateString,
      class: className || "General"
    });

    if (existingAttendance) {
      return res.status(400).json({
        success: false,
        message: "Attendance already marked for today"
      });
    }

    // Get student details
    const student = await User.findById(req.user.id);
    if (!student) {
      return res.status(404).json({
        success: false,
        message: "Student not found"
      });
    }

    // Create attendance record
    const attendance = new Attendance({
      studentId,
      studentName: student.name,
      date: dateString,
      time: timeString,
      class: className || "General",
      subject: subject || "General",
      method: method || "manual",
      status: "PRESENT",
      wifiRouter: wifiRouter || "unknown",
      semester: student.semester || 1,
      courseCode: subject || "GEN101",
      markedBy: req.user.id,
      faceVerified: method === "face",
      fingerprintVerified: method === "fingerprint",
      notes: "Marked via app"
    });

    await attendance.save();

    res.status(201).json({
      success: true,
      message: "Attendance marked successfully",
      data: attendance
    });
  } catch (error) {
    console.error("Mark attendance error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};

// @desc    Mark attendance with face recognition
exports.markAttendanceWithFace = async (req, res) => {
  try {
    const { router: wifiRouter, class: className, subject } = req.body;
    
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: "Image is required for face recognition"
      });
    }

    const studentId = req.user.studentId || req.user.id;
    const today = new Date();
    const dateString = today.toISOString().split('T')[0];
    const timeString = today.toTimeString().split(' ')[0];

    // Check existing attendance
    const existingAttendance = await Attendance.findOne({
      studentId,
      date: dateString,
      class: className || "General"
    });

    if (existingAttendance) {
      return res.status(400).json({
        success: false,
        message: "Attendance already marked for today"
      });
    }

    // Get student details
    const student = await User.findById(req.user.id);
    if (!student) {
      return res.status(404).json({
        success: false,
        message: "Student not found"
      });
    }

    // For demo, always verify face
    const faceVerified = true;

    if (!faceVerified) {
      return res.status(400).json({
        success: false,
        message: "Face recognition failed"
      });
    }

    // Create attendance record
    const attendance = new Attendance({
      studentId,
      studentName: student.name,
      date: dateString,
      time: timeString,
      class: className || "General",
      subject: subject || "General",
      method: "face",
      status: "PRESENT",
      wifiRouter: wifiRouter || "unknown",
      semester: student.semester || 1,
      courseCode: subject || "GEN101",
      imageUrl: `/uploads/${req.file.filename}`,
      faceVerified: true,
      markedBy: req.user.id,
      notes: "Marked via face recognition"
    });

    await attendance.save();

    res.status(201).json({
      success: true,
      message: "Face attendance marked successfully",
      data: attendance
    });
  } catch (error) {
    console.error("Face attendance error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};

// @desc    Get attendance history
exports.getAttendanceHistory = async (req, res) => {
  try {
    const studentId = req.user.studentId || req.user.id;
    
    const attendance = await Attendance.find({ studentId }).sort({ date: -1 });

    res.json({
      success: true,
      data: attendance
    });
  } catch (error) {
    console.error("Get attendance history error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};

// @desc    Get today's attendance
exports.getTodayAttendance = async (req, res) => {
  try {
    const studentId = req.user.studentId || req.user.id;
    const today = new Date().toISOString().split('T')[0];
    
    const attendance = await Attendance.findOne({
      studentId,
      date: today
    });

    res.json({
      success: true,
      marked: !!attendance,
      data: attendance || null
    });
  } catch (error) {
    console.error("Get today attendance error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};

// @desc    Get attendance statistics
exports.getAttendanceStats = async (req, res) => {
  try {
    const studentId = req.user.studentId || req.user.id;
    
    const attendance = await Attendance.find({ studentId });
    const total = attendance.length;
    const present = attendance.filter(a => a.status === "PRESENT").length;
    const percentage = total > 0 ? Math.round((present / total) * 100) : 0;

    res.json({
      success: true,
      stats: {
        total,
        present,
        percentage
      }
    });
  } catch (error) {
    console.error("Get stats error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};

// @desc    Get semester attendance
exports.getSemesterAttendance = async (req, res) => {
  try {
    const { semesterNo } = req.params;
    const studentId = req.user.studentId || req.user.id;
    
    const attendance = await Attendance.find({
      studentId,
      semester: parseInt(semesterNo)
    }).sort({ date: -1 });

    res.json({
      success: true,
      data: attendance
    });
  } catch (error) {
    console.error("Get semester attendance error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};

// @desc    Generate a time-limited QR token for attendance
// @route   GET /api/attendance/generate-qr?classCode=&period=
// @access  Staff / Admin
exports.generateQR = async (req, res) => {
  try {
    const { classCode, period } = req.query;

    if (!classCode || !period) {
      return res.status(400).json({
        success: false,
        message: "classCode and period are required"
      });
    }

    const EXPIRES_IN_SECONDS = 60;

    // Build a short-lived token payload
    const payload = {
      type: "qr-attendance",
      classCode,
      period: parseInt(period),
      staffId: req.user.id,
      issuedAt: Date.now()
    };

    const token = jwt.sign(payload, process.env.JWT_SECRET, {
      expiresIn: EXPIRES_IN_SECONDS
    });

    res.json({
      success: true,
      token,
      classCode,
      period: parseInt(period),
      expiresIn: EXPIRES_IN_SECONDS
    });
  } catch (error) {
    console.error("Generate QR error:", error);
    res.status(500).json({
      success: false,
      message: "Server error generating QR"
    });
  }
};

// @desc    Get today's class for staff
// @route   GET /api/attendance/today-class
exports.getTodayClass = async (req, res) => {
  try {
    const staffId = req.user.id;
    const today = new Date().toISOString().split('T')[0];

    // Get today's attendance records created by this staff
    const records = await Attendance.find({
      markedBy: staffId,
      date: today
    }).sort({ time: 1 });

    if (!records || records.length === 0) {
      return res.json({
        className: "",
        subjectName: "",
        isFreeHour: true,
        students: []
      });
    }

    // Group by class/subject — use the first record's class as context
    const firstRecord = records[0];

    // Build student list
    const students = records.map(r => ({
      id: r.studentId,
      name: r.studentName || r.studentId,
      roll: r.courseCode || r.studentId,
      status: r.status // "PRESENT" | "ABSENT" | "OD"
    }));

    res.json({
      className: firstRecord.class || "",
      subjectName: firstRecord.subject || "",
      isFreeHour: false,
      students
    });
  } catch (error) {
    console.error("getTodayClass error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

// @desc    Bulk update attendance records
// @route   POST /api/attendance/bulk-update
exports.bulkUpdate = async (req, res) => {
  try {
    const { records } = req.body;
    if (!records || !Array.isArray(records)) {
      return res.status(400).json({ success: false, message: "records array is required" });
    }

    const today = new Date().toISOString().split('T')[0];
    const staffId = req.user.id;

    const ops = records.map(r => ({
      updateOne: {
        filter: { studentId: r.id || r.studentId, date: r.date || today, class: r.class || "General" },
        update: {
          $set: {
            status: (r.status || "ABSENT").toUpperCase(),
            modifiedBy: staffId,
            modifiedAt: new Date()
          }
        },
        upsert: false
      }
    }));

    if (ops.length > 0) {
      await Attendance.bulkWrite(ops);
    }

    res.json({ success: true, message: `Updated ${ops.length} records` });
  } catch (error) {
    console.error("Bulk update error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

// @desc    Update single student attendance status
// @route   POST /api/attendance/update-status
exports.updateStatus = async (req, res) => {
  try {
    const { studentId, status, className, date } = req.body;
    if (!studentId || !status) {
      return res.status(400).json({ success: false, message: "studentId and status are required" });
    }

    const today = date || new Date().toISOString().split('T')[0];
    const normalized = status.toUpperCase();

    const updated = await Attendance.findOneAndUpdate(
      { studentId, date: today, ...(className ? { class: className } : {}) },
      { $set: { status: normalized, modifiedBy: req.user.id, modifiedAt: new Date() } },
      { new: true }
    );

    if (!updated) {
      return res.status(404).json({ success: false, message: "Attendance record not found for today" });
    }

    res.json({ success: true, message: `Status updated to ${normalized}`, data: updated });
  } catch (error) {
    console.error("Update status error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

// ─── Phase 7: QR Real-Time Approval Flow ─────────────────────────────────────

// @desc   Student requests attendance via QR token
// @route  POST /api/attendance/request
// @access Student (auth required)
exports.requestAttendance = async (req, res) => {
  try {
    const { token } = req.body;
    if (!token) {
      return res.status(400).json({ success: false, message: "Token is required" });
    }

    const studentId = req.user.studentId || req.user.id;
    const student = await User.findById(req.user.id);
    if (!student) {
      return res.status(404).json({ success: false, message: "Student not found" });
    }

    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (err) {
      return res.status(403).json({ success: false, message: "Invalid or expired QR Token" });
    }
    
    const { classCode, period, staffId } = decoded;

    // Check if a request already exists
    const existingReq = await AttendanceRequest.findOne({
      studentId,
      classCode,
      period,
      status: "pending"
    });

    if (existingReq) {
      return res.status(400).json({ success: false, message: "Request already pending for this class" });
    }

    // Create a new request
    const newRequest = new AttendanceRequest({
      studentId,
      studentName: student.name,
      classCode,
      period,
      token
    });

    await newRequest.save();

    // Emit event to staff
    const io = req.app.get("io");
    if (io && staffId) {
      io.to(`room:teacher:${staffId}`).emit("new_request", newRequest);
    }

    res.status(201).json({
      success: true,
      message: "Attendance request submitted.",
      data: newRequest
    });
  } catch (error) {
    console.error("requestAttendance error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

// @desc   Get pending requests for staff's class
// @route  GET /api/attendance/pending
// @access Staff / Admin
exports.getPendingRequests = async (req, res) => {
  try {
    const staffId = req.user.id;
    // Find class for this staff
    const staffClass = await Class.findOne({ "subjects.instructor": staffId }).lean();
    if (!staffClass) {
       return res.json({ success: true, count: 0, data: [] });
    }

    const pendingRequests = await AttendanceRequest.find({
      classCode: staffClass.classCode,
      status: "pending"
    }).sort({ createdAt: -1 });

    res.json({ success: true, count: pendingRequests.length, data: pendingRequests });
  } catch (error) {
    console.error("getPendingRequests error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

// @desc   Approve a pending request
// @route  POST /api/attendance/approve
// @access Staff / Admin
exports.approveRequest = async (req, res) => {
  try {
    const { requestId } = req.body;
    if (!requestId) return res.status(400).json({ success: false, message: "Request ID is required" });

    const attendanceReq = await AttendanceRequest.findById(requestId);
    if (!attendanceReq) {
      return res.status(404).json({ success: false, message: "Request not found" });
    }

    if (attendanceReq.status !== "pending") {
       return res.status(400).json({ success: false, message: "Request already processed" });
    }

    attendanceReq.status = "approved";
    await attendanceReq.save();

    // Extract student user id
    const studentUser = await User.findOne({ studentId: attendanceReq.studentId });
    const realStudentId = studentUser ? studentUser._id.toString() : attendanceReq.studentId;

    // Create the final Attendance record
    const today = new Date();
    const dateString = today.toISOString().split("T")[0];
    const timeString = today.toTimeString().split(" ")[0];

    // Check if record exists for this period
    let finalRecord = await Attendance.findOne({
      studentId: attendanceReq.studentId,
      date: dateString,
      period: attendanceReq.period || 1,
    });

    const attendanceData = {
      studentId: attendanceReq.studentId,
      studentName: attendanceReq.studentName,
      date: dateString,
      time: timeString,
      class: attendanceReq.classCode,
      subject: "General",
      period: attendanceReq.period || 1,
      method: "qr",
      verificationMethod: "Teacher Approved",
      status: "PRESENT",
      markedBy: req.user.id,
      semester: studentUser && studentUser.semester ? studentUser.semester : 1,
    };

    if (finalRecord) {
      Object.assign(finalRecord, attendanceData);
      await finalRecord.save();
    } else {
      finalRecord = new Attendance(attendanceData);
      await finalRecord.save();
    }

    // Emit event back to student
    const io = req.app.get("io");
    if (io) {
      io.to(`room:student:${realStudentId}`).emit("request_approved", { requestId });
    }

    res.json({ success: true, message: "Request approved", data: attendanceReq });
  } catch (error) {
    console.error("approveRequest error:", error);
    res.status(500).json({ success: false, message: error.message || "Server error" });
  }
};

// @desc   Reject a pending request
// @route  POST /api/attendance/reject
// @access Staff / Admin
exports.rejectRequest = async (req, res) => {
  try {
    const { requestId } = req.body;
    if (!requestId) return res.status(400).json({ success: false, message: "Request ID is required" });

    const attendanceReq = await AttendanceRequest.findById(requestId);
    if (!attendanceReq) {
      return res.status(404).json({ success: false, message: "Request not found" });
    }

    if (attendanceReq.status !== "pending") {
       return res.status(400).json({ success: false, message: "Request already processed" });
    }

    attendanceReq.status = "rejected";
    await attendanceReq.save();

    const studentUser = await User.findOne({ studentId: attendanceReq.studentId });
    const realStudentId = studentUser ? studentUser._id.toString() : attendanceReq.studentId;

    // Emit event back to student
    const io = req.app.get("io");
    if (io) {
      io.to(`room:student:${realStudentId}`).emit("request_rejected", { requestId });
    }

    res.json({ success: true, message: "Request rejected", data: attendanceReq });
  } catch (error) {
    console.error("rejectRequest error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};