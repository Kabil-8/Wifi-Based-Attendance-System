const Class = require("../models/Class");
const Attendance = require("../models/Attendance");

// @desc    Get student dashboard data
exports.getDashboard = async (req, res) => {
  try {
    const studentId = req.user.studentId || req.user.id;
    
    // Get today's date
    const today = new Date().toISOString().split('T')[0];
    
    // Get today's attendance
    const todayAttendance = await Attendance.findOne({
      studentId,
      date: today
    });

    // Get total attendance stats
    const totalAttendance = await Attendance.find({ studentId });
    const total = totalAttendance.length;
    const present = totalAttendance.filter(a => a.status === "PRESENT").length;
    const percentage = total > 0 ? Math.round((present / total) * 100) : 0;

    res.json({
      success: true,
      data: {
        today: {
          marked: !!todayAttendance,
          status: todayAttendance?.status || "NOT_MARKED"
        },
        stats: {
          total,
          present,
          percentage
        }
      }
    });
  } catch (error) {
    console.error("Get dashboard error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};

// @desc    Get class schedule
exports.getClassSchedule = async (req, res) => {
  try {
    const studentClasses = await Class.find({
      students: req.user.id,
      isActive: true
    });

    res.json({
      success: true,
      data: studentClasses
    });
  } catch (error) {
    console.error("Get schedule error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};

// @desc    Get all attendance for a student
exports.getStudentAttendance = async (req, res) => {
  try {
    const studentId = req.params.studentId;
    const attendance = await Attendance.find({ studentId }).sort({ date: -1 });

    const formatted = attendance.map(a => ({
      date: a.date,
      present: a.status === "PRESENT"
    }));

    res.json({
      success: true,
      attendance: formatted
    });
  } catch (error) {
    console.error("Get student attendance error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};