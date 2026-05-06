const Class = require("../models/Class");
const Attendance = require("../models/Attendance");
const User = require("../models/User");

// @desc    Get student dashboard data
exports.getDashboard = async (req, res) => {
  try {
    const studentId = req.user.studentId || req.user.id;
    
    // Fetch user for name
    const user = await User.findById(req.user.id).select('name');
    
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
        user: {
          name: user?.name || "Student"
        },
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