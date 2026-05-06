const express = require("express");
const router = express.Router();
const adminController = require("../controllers/adminController");
const authMiddleware = require("../middleware/authMiddleware");
const roleMiddleware = require("../middleware/roleMiddleware");

// All routes require admin authentication
/*router.use(authMiddleware);
router.use(roleMiddleware.isAdmin);*/

// Dashboard route
router.get("/dashboard", adminController.getSystemStats);

// User management
router.get("/users", adminController.getAllUsers);
router.get("/users/:id", adminController.getUserById);
router.put("/users/:id", adminController.updateUser);
router.delete("/users/:id", adminController.deleteUser);
router.put("/users/:id/role", adminController.changeUserRole);
router.put("/users/:id/status", adminController.toggleUserStatus);

// Class management
router.post("/classes", adminController.createClass);
router.get("/classes", adminController.getAllClasses);
router.get("/classes/:id", adminController.getClassById);
router.put("/classes/:id", adminController.updateClass);
router.delete("/classes/:id", adminController.deleteClass);
router.post("/classes/:id/students", adminController.addStudentsToClass);

// System management
router.get("/stats", adminController.getSystemStats);
router.get("/logs", adminController.getSystemLogs);

module.exports = router;