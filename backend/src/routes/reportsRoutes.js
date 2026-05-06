const express = require("express");
const router = express.Router();
const Attendance = require("../models/Attendance");
const Class = require("../models/Class");
const authMiddleware = require("../middleware/authMiddleware");
const roleMiddleware = require("../middleware/roleMiddleware");

router.use(authMiddleware);
router.use(roleMiddleware.isStaffOrAdmin);

// GET /api/reports/summary?classId=&subjectCode=&type=&from=&to=
router.get("/summary", async (req, res) => {
  try {
    const { classId, subjectCode, from, to } = req.query;
    const staffId = req.user.id;

    // Build filter
    const filter = { markedBy: staffId };
    if (classId) filter.class = classId;
    if (subjectCode) filter.subject = subjectCode;
    if (from || to) {
      filter.date = {};
      if (from) filter.date.$gte = from;
      if (to)   filter.date.$lte = to;
    }

    const records = await Attendance.find(filter);

    const total    = records.length;
    const present  = records.filter(r => r.status === "PRESENT").length;
    const od       = records.filter(r => r.status === "OD").length;
    const absent   = records.filter(r => r.status === "ABSENT").length;
    const average  = total > 0 ? Math.round(((present + od) / total) * 100) : 0;

    // Count unique students
    const studentIds = [...new Set(records.map(r => r.studentId))];
    const above75    = studentIds.filter(sid => {
      const stuRecs  = records.filter(r => r.studentId === sid);
      const stuPres  = stuRecs.filter(r => r.status === "PRESENT" || r.status === "OD").length;
      return stuRecs.length > 0 && (stuPres / stuRecs.length) * 100 >= 75;
    }).length;
    const defaulters = studentIds.length - above75;

    res.json({
      success: true,
      total,
      present,
      absent,
      od,
      average,
      above75,
      defaulters,
      students: studentIds.length
    });
  } catch (err) {
    console.error("Reports summary error:", err);
    res.status(500).json({ success: false, message: "Failed to generate summary" });
  }
});

// GET /api/reports/classes — list all classes this staff manages
router.get("/classes", async (req, res) => {
  try {
    const staffId = req.user.id;
    const classes = await Class.find({
      $or: [
        { "subjects.instructor": staffId },
        { staff: staffId },
        { createdBy: staffId }
      ]
    }).select("classCode className department semester subjects");

    res.json({ success: true, classes });
  } catch (err) {
    console.error("Reports classes error:", err);
    res.status(500).json({ success: false, message: "Failed to fetch classes" });
  }
});

// GET /api/reports/students?classId=&date=&subject=
router.get("/students", async (req, res) => {
  try {
    const { classId, date, subject } = req.query;
    const staffId = req.user.id;

    const filter = { markedBy: staffId };
    if (classId) filter.class = classId;
    if (date)    filter.date  = date;
    if (subject) filter.subject = subject;

    const records = await Attendance.find(filter).sort({ studentName: 1 });

    res.json({ success: true, records });
  } catch (err) {
    console.error("Reports students error:", err);
    res.status(500).json({ success: false, message: "Failed to fetch student records" });
  }
});

// POST /api/reports/:type — placeholder for PDF/Excel export
router.post("/:type", async (req, res) => {
  res.json({ success: true, message: `${req.params.type} report queued. Export feature coming soon.` });
});

module.exports = router;
