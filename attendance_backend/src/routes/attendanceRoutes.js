const express = require("express");
const router = express.Router();
const attendanceController = require("../controllers/attendanceController");
const authMiddleware = require("../middleware/authMiddleware");
const roleMiddleware = require("../middleware/roleMiddleware");
const upload = require("../middleware/uploadMiddleware");
const publicIpCheck = require("../middleware/publicIpMiddleware");

// All routes require authentication
router.use(authMiddleware);

// ─── Triple-Lock Security Protocol Routes ────────────────────────────────────
// The primary attendance route — accepts optional audit selfie
router.post(
  "/verify-attendance",
  upload.single("auditSelfie"),
  roleMiddleware.isStudent,
  attendanceController.verifyAttendance
);

// New Complex Multi-Factor Endpoint
router.post(
  "/verify-complex",
  publicIpCheck,
  upload.single("selfieImage"), // optional based on exact payload shape but requested as multipart
  roleMiddleware.isStudent,
  attendanceController.verifyComplex
);

// Get the authorized BSSID for a class (client fetches before marking)
router.get(
  "/authorized-bssid",
  roleMiddleware.isStudent,
  attendanceController.getAuthorizedBssid
);

// Get all flagged records (for staff audit dashboard)
router.get(
  "/flagged",
  attendanceController.getFlaggedRecords
);

// Bulk update (Staff)
router.post(
  "/bulk-update",
  roleMiddleware.isStaffOrAdmin,
  attendanceController.bulkUpdate
);

// Generate QR (Staff)
router.get(
  "/generate-qr",
  roleMiddleware.isStaffOrAdmin,
  attendanceController.generateQrToken
);

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

// ─── Legacy Routes (backward compatible) ─────────────────────────────────────
router.post("/mark", roleMiddleware.isStudent, attendanceController.markAttendance);
router.post(
  "/mark/face",
  upload.single("image"),
  roleMiddleware.isStudent,
  attendanceController.markAttendanceWithFace
);

// ─── Read Routes ─────────────────────────────────────────────────────────────
router.get("/today-class", roleMiddleware.isStaffOrAdmin, attendanceController.getTodayClassAttendance);
router.post("/update-status", roleMiddleware.isStaffOrAdmin, attendanceController.updateStudentStatus);
router.get("/history", roleMiddleware.isStudent, attendanceController.getAttendanceHistory);
router.get("/today", roleMiddleware.isStudent, attendanceController.getTodayAttendance);
router.get("/stats", roleMiddleware.isStudent, attendanceController.getAttendanceStats);
router.get("/semester/:semesterNo", roleMiddleware.isStudent, attendanceController.getSemesterAttendance);

module.exports = router;