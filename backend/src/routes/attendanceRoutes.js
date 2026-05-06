const express = require("express");
const router = express.Router();
const attendanceController = require("../controllers/attendanceController");
const authMiddleware = require("../middleware/authMiddleware");
const roleMiddleware = require("../middleware/roleMiddleware");
const upload = require("../middleware/uploadMiddleware");

// All routes require authentication
router.use(authMiddleware);

// Staff / Admin routes
router.get("/generate-qr", roleMiddleware.isStaffOrAdmin, attendanceController.generateQR);
router.get("/today-class", roleMiddleware.isStaffOrAdmin, attendanceController.getTodayClass);
router.post("/bulk-update", roleMiddleware.isStaffOrAdmin, attendanceController.bulkUpdate);
router.post("/update-status", roleMiddleware.isStaffOrAdmin, attendanceController.updateStatus);

// Student attendance routes
router.post("/mark", roleMiddleware.isStudent, attendanceController.markAttendance);
router.post("/mark/face", 
  upload.single("image"), 
  roleMiddleware.isStudent, 
  attendanceController.markAttendanceWithFace
);
router.get("/history", roleMiddleware.isStudent, attendanceController.getAttendanceHistory);
router.get("/today", roleMiddleware.isStudent, attendanceController.getTodayAttendance);
router.get("/stats", roleMiddleware.isStudent, attendanceController.getAttendanceStats);
router.get("/semester/:semesterNo", roleMiddleware.isStudent, attendanceController.getSemesterAttendance);
// ─── Phase 7: Real-Time QR Approval Flow ─────────────────────────────────────
router.post(
  "/request",
  roleMiddleware.isStudent,
  attendanceController.requestAttendance
);

router.get(
  "/pending",
  roleMiddleware.isStaffOrAdmin,
  attendanceController.getPendingRequests
);

router.post(
  "/approve",
  roleMiddleware.isStaffOrAdmin,
  attendanceController.approveRequest
);

router.post(
  "/reject",
  roleMiddleware.isStaffOrAdmin,
  attendanceController.rejectRequest
);

module.exports = router;