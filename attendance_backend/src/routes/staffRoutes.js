const express = require("express");
const router = express.Router();
const staffController = require("../controllers/staffController");
const authMiddleware = require("../middleware/authMiddleware");
const roleMiddleware = require("../middleware/roleMiddleware");

// All routes require staff or admin authentication
router.use(authMiddleware);
router.use(roleMiddleware.isStaffOrAdmin);

// Dashboard
router.get("/dashboard", staffController.getDashboard);

// Class management
router.get("/classes", staffController.getStaffClasses);
router.get("/class/:classId/students", staffController.getClassStudents);
router.get("/class/:classId/attendance", staffController.getClassAttendance);
router.post("/class/:classId/attendance", staffController.markClassAttendance);

// Attendance management
router.put("/attendance/:attendanceId", staffController.modifyAttendance);

// Reports
router.get("/reports", staffController.getAttendanceReports);

module.exports = router;