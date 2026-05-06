const router = require("express").Router();

router.use("/auth", require("./authRoutes"));
router.use("/attendance", require("./attendanceRoutes"));
router.use("/admin", require("./adminRoutes"));

module.exports = router;
