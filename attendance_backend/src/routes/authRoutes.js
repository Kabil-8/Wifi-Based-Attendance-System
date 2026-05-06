const express = require("express");
const router = express.Router();
const authController = require("../controllers/authController");
const authMiddleware = require("../middleware/authMiddleware");

// Public routes
router.post("/register", authController.register);

// 🔥 DEBUG WRAPPER
router.post("/login", (req, res, next) => {
  console.log("🔥 LOGIN ROUTE HIT");
  next();
}, authController.login);

// Protected routes
router.get("/profile", authMiddleware, authController.getProfile);
router.put("/profile", authMiddleware, authController.updateProfile);
router.put("/change-password", authMiddleware, authController.changePassword);

module.exports = router;
