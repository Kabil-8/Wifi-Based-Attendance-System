const User = require("../models/User");
const Attendance = require("../models/Attendance");
const Class = require("../models/Class");

// @desc    Get all users
exports.getAllUsers = async (req, res) => {
  try {
    const users = await User.find({}).select("-password").sort({ createdAt: -1 });

    res.json({
      success: true,
      data: users
    });
  } catch (error) {
    console.error("Get all users error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};

// @desc    Get user by ID
exports.getUserById = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select("-password");

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found"
      });
    }

    res.json({
      success: true,
      data: user
    });
  } catch (error) {
    console.error("Get user by ID error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};

// @desc    Update user
exports.updateUser = async (req, res) => {
  try {
    const { name, email, department, semester, phone } = req.body;

    const user = await User.findByIdAndUpdate(
      req.params.id,
      {
        name,
        email,
        department,
        semester,
        phone,
        updatedAt: Date.now()
      },
      { new: true }
    ).select("-password");

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found"
      });
    }

    res.json({
      success: true,
      message: "User updated successfully",
      data: user
    });
  } catch (error) {
    console.error("Update user error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};

// @desc    Change user role
exports.changeUserRole = async (req, res) => {
  try {
    const { role } = req.body;

    if (!["STUDENT", "STAFF", "ADMIN"].includes(role)) {
      return res.status(400).json({
        success: false,
        message: "Invalid role"
      });
    }

    const user = await User.findByIdAndUpdate(
      req.params.id,
      { role, updatedAt: Date.now() },
      { new: true }
    ).select("-password");

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found"
      });
    }

    res.json({
      success: true,
      message: `User role changed to ${role}`,
      data: user
    });
  } catch (error) {
    console.error("Change user role error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};

// @desc    Create class
exports.createClass = async (req, res) => {
  try {
    const { classCode, className, department, semester, subjects } = req.body;

    const newClass = new Class({
      classCode,
      className,
      department,
      semester,
      subjects: subjects || [],
      createdBy: req.user.id,
      totalStrength: 0
    });

    await newClass.save();

    res.status(201).json({
      success: true,
      message: "Class created successfully",
      data: newClass
    });
  } catch (error) {
    console.error("Create class error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};

// @desc    Get all classes
exports.getAllClasses = async (req, res) => {
  try {
    const classes = await Class.find({}).sort({ createdAt: -1 });

    res.json({
      success: true,
      data: classes
    });
  } catch (error) {
    console.error("Get all classes error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};

// @desc    Get system statistics
exports.getSystemStats = async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();
    const totalStudents = await User.countDocuments({ role: "STUDENT" });
    const totalStaff = await User.countDocuments({ role: "STAFF" });
    const totalClasses = await Class.countDocuments();
    const totalAttendance = await Attendance.countDocuments();

    res.json({
      success: true,
      data: {
        users: {
          total: totalUsers,
          students: totalStudents,
          staff: totalStaff
        },
        classes: totalClasses,
        attendance: totalAttendance
      }
    });
  } catch (error) {
    console.error("Get system stats error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};

// @desc    Delete user
exports.deleteUser = async (req, res) => {
  try {
    const user = await User.findByIdAndDelete(req.params.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found"
      });
    }

    res.json({
      success: true,
      message: "User deleted successfully"
    });
  } catch (error) {
    console.error("Delete user error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};

// @desc    Toggle user active status
exports.toggleUserStatus = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found"
      });
    }

    user.isActive = !user.isActive;
    user.updatedAt = Date.now();
    await user.save();

    res.json({
      success: true,
      message: `User ${user.isActive ? "activated" : "deactivated"} successfully`,
      data: { isActive: user.isActive }
    });
  } catch (error) {
    console.error("Toggle user status error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};

// @desc    Get class by ID
exports.getClassById = async (req, res) => {
  try {
    const classDoc = await Class.findById(req.params.id);

    if (!classDoc) {
      return res.status(404).json({
        success: false,
        message: "Class not found"
      });
    }

    res.json({
      success: true,
      data: classDoc
    });
  } catch (error) {
    console.error("Get class by ID error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};

// @desc    Update class
exports.updateClass = async (req, res) => {
  try {
    const { className, classCode, department, semester, subjects } = req.body;

    const classDoc = await Class.findByIdAndUpdate(
      req.params.id,
      { className, classCode, department, semester, subjects },
      { new: true }
    );

    if (!classDoc) {
      return res.status(404).json({
        success: false,
        message: "Class not found"
      });
    }

    res.json({
      success: true,
      message: "Class updated successfully",
      data: classDoc
    });
  } catch (error) {
    console.error("Update class error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};

// @desc    Delete class
exports.deleteClass = async (req, res) => {
  try {
    const classDoc = await Class.findByIdAndDelete(req.params.id);

    if (!classDoc) {
      return res.status(404).json({
        success: false,
        message: "Class not found"
      });
    }

    res.json({
      success: true,
      message: "Class deleted successfully"
    });
  } catch (error) {
    console.error("Delete class error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};

// @desc    Add students to class
exports.addStudentsToClass = async (req, res) => {
  try {
    const { studentIds } = req.body;

    const classDoc = await Class.findById(req.params.id);

    if (!classDoc) {
      return res.status(404).json({
        success: false,
        message: "Class not found"
      });
    }

    // Add students that aren't already in the class
    const existingStudents = classDoc.students || [];
    const newStudents = studentIds.filter(id => !existingStudents.includes(id));
    classDoc.students = [...existingStudents, ...newStudents];
    classDoc.totalStrength = classDoc.students.length;
    await classDoc.save();

    res.json({
      success: true,
      message: `${newStudents.length} student(s) added to class`,
      data: classDoc
    });
  } catch (error) {
    console.error("Add students to class error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};

// @desc    Get system logs (placeholder)
exports.getSystemLogs = async (req, res) => {
  try {
    res.json({
      success: true,
      data: [],
      message: "System logs endpoint"
    });
  } catch (error) {
    console.error("Get system logs error:", error);
    res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
};