const roleMiddleware = {
  isAdmin: (req, res, next) => {
    if (req.user.role !== "ADMIN") {
      return res.status(403).json({
        success: false,
        message: "Access denied. Administrator privileges required."
      });
    }
    next();
  },

  isStaff: (req, res, next) => {
    if (!["STAFF", "ADMIN"].includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: "Access denied. Staff or Administrator privileges required."
      });
    }
    next();
  },

  isStudent: (req, res, next) => {
    if (req.user.role !== "STUDENT") {
      return res.status(403).json({
        success: false,
        message: "Access denied. Student privileges required."
      });
    }
    next();
  },

  isStaffOrAdmin: (req, res, next) => {
    if (!["STAFF", "ADMIN"].includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: "Access denied. Staff or Administrator privileges required."
      });
    }
    next();
  }
};

module.exports = roleMiddleware;