const express = require("express");
const router = express.Router();
const studentController = require("../controllers/studentController");
const authMiddleware = require("../middleware/authMiddleware");
const roleMiddleware = require("../middleware/roleMiddleware");

console.log("✅ studentRoutes loaded");

// All routes require student authentication
router.use(authMiddleware);
router.use(roleMiddleware.isStudent);

// Student dashboard
router.get("/dashboard", studentController.getDashboard);
router.get("/schedule", studentController.getClassSchedule);

module.exports = router;