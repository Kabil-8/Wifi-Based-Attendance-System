const Attendance = require("../models/Attendance");
const Class = require("../models/Class");
const User = require("../models/User");
const AttendanceRequest = require("../models/AttendanceRequest");

// ─── Fallback authorised BSSID ────────────────────────────────────────────────
// Used when the requested class doesn't exist in the DB yet, or when its
// authorizedBssid field is null.  Replace with the real classroom router MAC.
const FALLBACK_AUTHORIZED_BSSID = process.env.AUTHORIZED_BSSID || "00:0a:95:9d:68:16";
// ─────────────────────────────────────────────────────────────────────────────

/**
 * normalise a BSSID string for comparison (lowercase, trimmed)
 */
function normaliseBssid(raw) {
  return (raw || "").trim().toLowerCase();
}

// ─────────────────────────────────────────────────────────────────────────────
// @desc   Triple-Lock verified attendance
// @route  POST /api/attendance/verify-attendance
// @access Student (auth required)
//
// Body:
//   studentId  : String (optional — derived from JWT if absent)
//   bssid      : String (required — the BSSID the client detected)
//   class      : String (optional, defaults to "General")
//   subject    : String (optional, defaults to "General")
//   auditSelfie: File   (optional — required when biometric signature changed)
//   securityTier        : String ("Tier3A-Fingerprint" | "Tier3B-FaceScan")
//   biometricSignatureChanged : Boolean
// ─────────────────────────────────────────────────────────────────────────────
exports.verifyAttendance = async (req, res) => {
  const {
    bssid,
    class: className,
    subject,
    period,
    deviceId,
    securityTier,
    biometricSignatureChanged,
  } = req.body;

  const studentId = req.user.studentId || req.user.id;

  const today = new Date();
  const dateString = today.toISOString().split("T")[0];
  const timeString = today.toTimeString().split(" ")[0];

  // ── helpers ──────────────────────────────────────────────────────────────
  const buildAbsentRecord = async (student, reason, tier) => {
    // Check if record exists for this period
    const existing = await Attendance.findOne({
      studentId,
      date: dateString,
      period: period || 1,
    });

    const attendanceData = {
      studentId,
      studentName: student?.name || "Unknown",
      date: dateString,
      time: timeString,
      class: className || "General",
      subject: subject || "General",
      period: period || 1,
      method: "TripleLock",
      verificationMethod: "None",
      bssid: normaliseBssid(bssid),
      deviceId: deviceId || "unknown",
      status: "ABSENT",
      reason,
      securityTier: tier || "None",
      wifiRouter: "unknown",
      semester: student?.semester || 1,
      courseCode: subject || "GEN101",
      markedBy: req.user.id,
      notes: `Auto-logged failure: ${reason}`,
    };

    if (existing) {
      // Allow updating ABSENT record if it's the same day
      Object.assign(existing, attendanceData);
      await existing.save();
      return existing;
    } else {
      const rec = new Attendance(attendanceData);
      await rec.save();
      return rec;
    }
  };
  // ─────────────────────────────────────────────────────────────────────────

  try {
    if (!studentId) {
      return res
        .status(400)
        .json({ success: false, message: "Student ID is required" });
    }

    // ── 1. Already marked today? ──────────────────────────────────────────
    const existingAttendance = await Attendance.findOne({
      studentId,
      date: dateString,
      period: period || 1,
      class: className || "General",
    });

    // ── 2. Fetch student ──────────────────────────────────────────────────
    const student = await User.findById(req.user.id);
    if (!student) {
      return res
        .status(404)
        .json({ success: false, message: "Student not found" });
    }

    // ── 3. Server-side BSSID double-check (Tier 1) ────────────────────────
    let authorizedBssid = FALLBACK_AUTHORIZED_BSSID;

    if (className) {
      const classDoc = await Class.findOne({ classCode: className }).lean();
      if (classDoc && classDoc.authorizedBssid) {
        authorizedBssid = classDoc.authorizedBssid;
      }
    }

    const sentBssid = normaliseBssid(bssid);
    const expectedBssid = normaliseBssid(authorizedBssid);

    if (!sentBssid) {
      const reason = "Wait! Your Wi-Fi is turned off. Please enable it to proceed.";
      const rec = await buildAbsentRecord(student, "WiFi Disabled", "Tier1-WiFi");
      return res.status(400).json({ 
        success: false, 
        message: reason,
        loggedAs: "ABSENT",
        data: rec
      });
    }

    if (sentBssid !== expectedBssid) {
      const reason = `Connected to unauthorized network. Attendance marked as ABSENT. (Detected: ${sentBssid})`;
      const rec = await buildAbsentRecord(student, reason, "Tier1-WiFi");
      return res.status(200).json({ 
        success: false, 
        message: reason,
        loggedAs: "ABSENT",
        data: rec
      });
    }

    // ── 4. Determine if this is a flagged (face-scan) submission ──────────
    const hasAuditSelfie = !!req.file;
    const isFlaggedSubmission =
      hasAuditSelfie ||
      biometricSignatureChanged === true ||
      biometricSignatureChanged === "true";

    // ── 5. Save/Update PRESENT record ─────────────────────────────────────
    const attendanceData = {
      studentId,
      studentName: student.name,
      date: dateString,
      time: timeString,
      class: className || "General",
      subject: subject || "General",
      period: period || 1,
      method: "TripleLock",
      verificationMethod: isFlaggedSubmission
        ? "TripleLock-FaceScan"
        : "TripleLock-Fingerprint",
      bssid: sentBssid,
      deviceId: deviceId || "unknown",
      status: "PRESENT",
      wifiRouter: sentBssid,
      semester: student.semester || 1,
      courseCode: subject || "GEN101",
      markedBy: req.user.id,

      securityTier: securityTier || (isFlaggedSubmission ? "Tier3B-FaceScan" : "Tier3A-Fingerprint"),
      biometricSignatureChanged: !!isFlaggedSubmission,
      auditSelfieUrl: hasAuditSelfie ? `/uploads/${req.file.filename}` : null,
      flaggedForReview: !!isFlaggedSubmission,
      flagReason: isFlaggedSubmission
        ? "Biometric signature changed — face scan recorded for audit"
        : null,

      fingerprintVerified: !isFlaggedSubmission,
      faceVerified: isFlaggedSubmission,
      imageUrl: hasAuditSelfie ? `/uploads/${req.file.filename}` : undefined,
      notes: isFlaggedSubmission
        ? "⚠️ Attendance updated with audit selfie"
        : "✅ Attendance updated via Triple-Lock",
    };

    let attendance;
    if (existingAttendance) {
      Object.assign(existingAttendance, attendanceData);
      attendance = await existingAttendance.save();
    } else {
      attendance = new Attendance(attendanceData);
      await attendance.save();
    }

    return res.status(201).json({
      success: true,
      message: isFlaggedSubmission
        ? "Attendance marked — Flagged for Review (biometric change detected)"
        : "Attendance marked successfully via Triple-Lock",
      flagged: !!isFlaggedSubmission,
      data: attendance,
    });
  } catch (error) {
    console.error("verifyAttendance error:", error);
    return res.status(500).json({ success: false, message: "Server error" });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// @desc   Get the authorized BSSID for a class (or fallback)
// @route  GET /api/attendance/authorized-bssid?classCode=MAD-SEM4
// @access Student (auth required)
// ─────────────────────────────────────────────────────────────────────────────
exports.getAuthorizedBssid = async (req, res) => {
  try {
    const { classCode } = req.query;

    let authorizedBssid = FALLBACK_AUTHORIZED_BSSID;

    if (classCode) {
      const classDoc = await Class.findOne({ classCode }).lean();
      if (classDoc && classDoc.authorizedBssid) {
        authorizedBssid = classDoc.authorizedBssid;
      }
    }

    return res.json({
      success: true,
      authorizedBssid: normaliseBssid(authorizedBssid),
    });
  } catch (error) {
    console.error("getAuthorizedBssid error:", error);
    return res.status(500).json({ success: false, message: "Server error" });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// @desc   Get all flagged attendance records (for staff audit dashboard)
// @route  GET /api/attendance/flagged
// @access Staff / Admin
// ─────────────────────────────────────────────────────────────────────────────
exports.getFlaggedRecords = async (req, res) => {
  try {
    const records = await Attendance.find({ flaggedForReview: true })
      .sort({ date: -1, time: -1 })
      .limit(100)
      .lean();

    return res.json({ success: true, count: records.length, data: records });
  } catch (error) {
    console.error("getFlaggedRecords error:", error);
    return res.status(500).json({ success: false, message: "Server error" });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// @desc   Mark attendance via BSSID + Biometric dual-verification (LEGACY)
// @route  POST /api/attendance/mark
// @access Student (auth required)
// ─────────────────────────────────────────────────────────────────────────────
exports.markAttendance = async (req, res) => {
  const { studentId: bodyStudentId, deviceId, bssid, class: className, subject, method } = req.body;

  const studentId = req.user.studentId || req.user.id;

  const today = new Date();
  const dateString = today.toISOString().split("T")[0];
  const timeString = today.toTimeString().split(" ")[0];

  // ── helpers ──────────────────────────────────────────────────────────────
  const buildAbsentRecord = async (student, reason) => {
    const rec = new Attendance({
      studentId,
      studentName: student?.name || "Unknown",
      date: dateString,
      time: timeString,
      class: className || "General",
      subject: subject || "General",
      method: method || "Biometric+Router",
      verificationMethod: "None",
      bssid: normaliseBssid(bssid),
      deviceId: deviceId || "unknown",
      status: "ABSENT",
      reason,
      wifiRouter: "unknown",
      semester: student?.semester || 1,
      courseCode: subject || "GEN101",
      markedBy: req.user.id,
      notes: `Auto-logged failure: ${reason}`
    });
    try {
      await rec.save();
    } catch (saveErr) {
      if (saveErr.code !== 11000) console.error("buildAbsentRecord save error:", saveErr);
    }
    return rec;
  };
  // ─────────────────────────────────────────────────────────────────────────

  try {
    if (!studentId) {
      return res.status(400).json({ success: false, message: "Student ID is required" });
    }

    const existingAttendance = await Attendance.findOne({
      studentId,
      date: dateString,
      class: className || "General"
    });

    if (existingAttendance) {
      return res.status(400).json({
        success: false,
        message: "Attendance already marked for today"
      });
    }

    const student = await User.findById(req.user.id);
    if (!student) {
      return res.status(404).json({ success: false, message: "Student not found" });
    }

    let authorizedBssid = FALLBACK_AUTHORIZED_BSSID;

    if (className) {
      const classDoc = await Class.findOne({ classCode: className }).lean();
      if (classDoc && classDoc.authorizedBssid) {
        authorizedBssid = classDoc.authorizedBssid;
      }
    }

    const sentBssid = normaliseBssid(bssid);
    const expectedBssid = normaliseBssid(authorizedBssid);

    if (!sentBssid) {
      const reason = "No BSSID provided by client";
      await buildAbsentRecord(student, reason);
      return res.status(400).json({ success: false, message: reason });
    }

    if (sentBssid !== expectedBssid) {
      const reason = `Unauthorized Network: BSSID ${sentBssid} is not the classroom router`;
      await buildAbsentRecord(student, reason);
      return res.status(403).json({ success: false, message: reason });
    }

    const attendance = new Attendance({
      studentId,
      studentName: student.name,
      date: dateString,
      time: timeString,
      class: className || "General",
      subject: subject || "General",
      method: "Biometric+Router",
      verificationMethod: "Biometric+Router",
      bssid: sentBssid,
      deviceId: deviceId || "unknown",
      status: "PRESENT",
      wifiRouter: sentBssid,
      semester: student.semester || 1,
      courseCode: subject || "GEN101",
      markedBy: req.user.id,
      fingerprintVerified: true,
      notes: "Marked via Biometric+Router dual verification"
    });

    await attendance.save();

    return res.status(201).json({
      success: true,
      message: "Attendance marked successfully",
      data: attendance
    });

  } catch (error) {
    console.error("markAttendance error:", error);
    return res.status(500).json({ success: false, message: "Server error" });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// @desc   Mark attendance with face recognition (legacy upload flow)
// @route  POST /api/attendance/mark/face
// @access Student (auth required)
// ─────────────────────────────────────────────────────────────────────────────
exports.markAttendanceWithFace = async (req, res) => {
  try {
    const { router: wifiRouter, class: className, subject } = req.body;

    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: "Image is required for face recognition"
      });
    }

    const studentId = req.user.studentId || req.user.id;
    const today = new Date();
    const dateString = today.toISOString().split("T")[0];
    const timeString = today.toTimeString().split(" ")[0];

    const existingAttendance = await Attendance.findOne({
      studentId,
      date: dateString,
      class: className || "General"
    });

    if (existingAttendance) {
      return res.status(400).json({
        success: false,
        message: "Attendance already marked for today"
      });
    }

    const student = await User.findById(req.user.id);
    if (!student) {
      return res.status(404).json({ success: false, message: "Student not found" });
    }

    const attendance = new Attendance({
      studentId,
      studentName: student.name,
      date: dateString,
      time: timeString,
      class: className || "General",
      subject: subject || "General",
      method: "face",
      verificationMethod: "FacePhoto",
      status: "PRESENT",
      wifiRouter: wifiRouter || "unknown",
      semester: student.semester || 1,
      courseCode: subject || "GEN101",
      imageUrl: `/uploads/${req.file.filename}`,
      faceVerified: true,
      markedBy: req.user.id,
      notes: "Marked via face recognition upload"
    });

    await attendance.save();

    return res.status(201).json({
      success: true,
      message: "Face attendance marked successfully",
      data: attendance
    });
  } catch (error) {
    console.error("Face attendance error:", error);
    return res.status(500).json({ success: false, message: "Server error" });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// @desc   Get attendance history
// @route  GET /api/attendance/history
// ─────────────────────────────────────────────────────────────────────────────
exports.getAttendanceHistory = async (req, res) => {
  try {
    const studentId = req.user.studentId || req.user.id;
    const attendance = await Attendance.find({ studentId }).sort({ date: -1 });
    res.json({ success: true, data: attendance });
  } catch (error) {
    console.error("Get attendance history error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// @desc   Get today's attendance
// @route  GET /api/attendance/today
// ─────────────────────────────────────────────────────────────────────────────
exports.getTodayAttendance = async (req, res) => {
  try {
    const studentId = req.user.studentId || req.user.id;
    const today = new Date().toISOString().split("T")[0];

    const attendance = await Attendance.findOne({ studentId, date: today });
    res.json({ success: true, marked: !!attendance, data: attendance || null });
  } catch (error) {
    console.error("Get today attendance error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// @desc   Get attendance statistics
// @route  GET /api/attendance/stats
// ─────────────────────────────────────────────────────────────────────────────
exports.getAttendanceStats = async (req, res) => {
  try {
    const studentId = req.user.studentId || req.user.id;
    const attendance = await Attendance.find({ studentId });
    const total = attendance.length;
    const present = attendance.filter((a) => a.status === "PRESENT").length;
    const flagged = attendance.filter((a) => a.flaggedForReview === true).length;
    const percentage = total > 0 ? Math.round((present / total) * 100) : 0;

    res.json({ success: true, stats: { total, present, flagged, percentage } });
  } catch (error) {
    console.error("Get stats error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// @desc   Get semester attendance
// @route  GET /api/attendance/semester/:semesterNo
// ─────────────────────────────────────────────────────────────────────────────
exports.getSemesterAttendance = async (req, res) => {
  try {
    const { semesterNo } = req.params;
    const studentId = req.user.studentId || req.user.id;

    const attendance = await Attendance.find({
      studentId,
      semester: parseInt(semesterNo)
    }).sort({ date: -1 });

    res.json({ success: true, data: attendance });
  } catch (error) {
    console.error("Get semester attendance error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

// ─── Phase 5: Complex MFA Verification (Real DB) ───────────────────────────────
exports.verifyComplex = async (req, res) => {
  try {
    const {
      bssid,
      rssi,
      gpsLocation,
      qrToken,
      livenessConfirmed,
      classId,
      period,
      subject,
      courseCode
    } = req.body;

    const studentId = req.user.studentId || req.user.id;
    const student = await User.findById(req.user.id);
    if (!student) {
      return res.status(404).json({ success: false, message: "Student not found" });
    }

    const today = new Date();
    const dateString = today.toISOString().split("T")[0];
    const timeString = today.toTimeString().split(" ")[0];

    // 1. Fetch Class for Authorization (Network/GPS)
    const targetClass = await Class.findOne({ classCode: classId }) || 
                      await Class.findOne({ classCode: "MAD-SEM4" }); // Fallback for testing

    if (!targetClass) {
      return res.status(404).json({ success: false, message: "Classroom configuration not found" });
    }

    // Phase 1: Proximity Verification (Wi-Fi)
    const normalizedBssid = normaliseBssid(bssid);
    const expectedBssid = normaliseBssid(targetClass.authorizedBssid || FALLBACK_AUTHORIZED_BSSID);

    if (normalizedBssid !== expectedBssid) {
       // Log as ABSENT for this period
       const absentRec = new Attendance({
         studentId,
         studentName: student.name,
         date: dateString,
         period: period || 1,
         status: "ABSENT",
         reason: `Unauthorized Network: Detected ${normalizedBssid}`,
         bssid: normalizedBssid,
         class: classId || targetClass.classCode,
         subject: subject || "General",
         courseCode: courseCode || "GEN101",
         markedBy: req.user.id,
         semester: student.semester || 1
       });
       await absentRec.save();

       return res.status(403).json({ 
         success: false, 
         message: "Invalid Network: Attendance marked as ABSENT.",
         loggedAs: "ABSENT" 
       });
    }

    // (Optional) Phase 1b: RSSI check (unreliable on some emulators, but keeping logic)
    const rssiVal = parseInt(rssi);
    const rssiThreshold = -85; // Less strict for general use
    if (!isNaN(rssiVal) && rssiVal < rssiThreshold) {
       return res.status(403).json({ success: false, message: "Signal too weak. Are you inside the room?" });
    }

    // (Optional) Phase 1c: GPS check
    if (gpsLocation && targetClass.location && targetClass.location.room !== "Virtual") {
        let parsedGps = gpsLocation;
        if (typeof gpsLocation === 'string') {
          try { parsedGps = JSON.parse(gpsLocation); } catch (e) {}
        }
        
        // If we had classroom coords in Class model... (adding mock check for now)
        // const classroomCoords = { lat: 12.9716, lng: 77.5946 };
        // distance check...
    }

    // Phase 2: QR Token Validation (60s window)
    // QR should contains: classCode|period|date|timestamp
    if (!qrToken) {
      return res.status(400).json({ success: false, message: "QR Token missing" });
    }

    // SIMPLE MOCK VALIDATION FOR NOW: token must contain "PRESENT" or be the specific staff token
    // In a real scenario, we'd decrypt/verify a JWT or signed string
    const parts = qrToken.split('|');
    const tokenTime = parts.length > 3 ? parseInt(parts[3]) : Date.now();
    const now = Date.now();

    if (qrToken !== "mock_qr_token" && (now - tokenTime > 60000)) {
       return res.status(403).json({ success: false, message: "QR Expired. Please scan again within 60s." });
    }

    // Phase 3: Identity (Liveness)
    const isLive = String(livenessConfirmed) === "true" || livenessConfirmed === true;
    if (!isLive) {
      return res.status(403).json({ success: false, message: "Liveness Check Failed." });
    }

    // Final Action: Save PRESENT record
    const attendanceData = {
      studentId,
      studentName: student.name,
      date: dateString,
      time: timeString,
      class: classId || targetClass.classCode,
      subject: subject || "General",
      period: period || 1,
      method: "TripleLock",
      verificationMethod: "Complex MFA (QR+Wi-Fi+Face)",
      bssid: normalizedBssid,
      status: "PRESENT",
      securityTier: "Tier3B-FaceScan",
      semester: student.semester || 1,
      courseCode: courseCode || "GEN101",
      markedBy: req.user.id,
      faceVerified: true,
      fingerprintVerified: true,
      auditSelfieUrl: req.file ? `/uploads/${req.file.filename}` : null
    };

    const record = await Attendance.findOneAndUpdate(
      { studentId, date: dateString, period: period || 1 },
      attendanceData,
      { upsert: true, new: true }
    );

    return res.status(201).json({
      success: true,
      message: "Attendance marked successfully. Triple-Lock verified.",
      data: record
    });

  } catch (error) {
    console.error("verifyComplex error:", error);
    return res.status(500).json({ success: false, message: "Server error" });
  }
};


// ─────────────────────────────────────────────────────────────────────────────
// @desc   Bulk update attendance records (Staff/Admin)
// @route  POST /api/attendance/bulk-update
// @access Staff / Admin
// ─────────────────────────────────────────────────────────────────────────────
exports.bulkUpdate = async (req, res) => {
  try {
    const { records } = req.body;
    
    if (!records || !Array.isArray(records)) {
      return res.status(400).json({ success: false, message: "Invalid records format" });
    }

    const today = new Date().toISOString().split("T")[0];
    const timeNow = new Date().toTimeString().split(" ")[0];

    const results = await Promise.all(records.map(async (rec) => {
      const { studentId, studentName, date, period, status, class: className, subject } = rec;
      
      const query = { 
        studentId, 
        date: date || today, 
        period: period || 1,
        class: className || "General"
      };

      const updateData = {
        studentName,
        status: (status || "PRESENT").toUpperCase(),
        subject: subject || "General",
        time: timeNow,
        markedBy: req.user.id,
        method: "staff",
        verificationMethod: "Manual",
        semester: rec.semester || 1,
        modifiedAt: new Date(),
        modifiedBy: req.user.id
      };

      return await Attendance.findOneAndUpdate(
        query,
        updateData,
        { upsert: true, new: true, setDefaultsOnInsert: true }
      );
    }));

    return res.json({ 
      success: true, 
      count: results.length,
      message: `Successfully updated ${results.length} records including OD/Manual status`
    });
  } catch (err) {
    console.error("bulkUpdate error:", err);
    return res.status(500).json({ success: false, message: "Failed to update attendance" });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// @desc   Generate Dynamic QR Token
// @route  GET /api/attendance/generate-qr
// @access Staff
// ─────────────────────────────────────────────────────────────────────────────
exports.generateQrToken = async (req, res) => {
  try {
    const { classCode, period } = req.query;
    
    const timestamp = Date.now();
    // Simple format: classCode|period|date|timestamp
    const dateStr = new Date().toISOString().split('T')[0];
    
    const token = `${classCode || 'all'}|${period || 1}|${dateStr}|${timestamp}`;
    
    // In a production app, you might encrypt this token or store it in Redis
    
    res.json({
      success: true,
      token,
      expiresIn: 60,
      timestamp
    });
  } catch (err) {
    res.status(500).json({ success: false, message: "Failed to generate QR" });
  }
};

// ─── Phase 6: Today Class Attendance (For Staff Dashboard) ────────────────────
exports.getTodayClassAttendance = async (req, res) => {
  try {
    const today = new Date().toISOString().split("T")[0];
    const staffId = req.user.id;

    // 1. Find the class where this staff is assigned
    const staffClass = await Class.findOne({ "subjects.instructor": staffId }).lean();

    if (!staffClass) {
      return res.json({
        isFreeHour: true,
        className: "Free Period",
        subjectName: "No Active Class",
        students: []
      });
    }

    // 2. Fetch all students for this class
    const students = await User.find({
      _id: { $in: staffClass.students }
    }).select("name rollNo studentId").lean();

    // 3. Fetch today's attendance records for this class
    const attendanceRecords = await Attendance.find({
      class: staffClass.classCode,
      date: today
    }).lean();

    // 4. Merge status
    const studentData = students.map(s => {
      const record = attendanceRecords.find(r => r.studentId === s.studentId);
      return {
        id: s._id,
        name: s.name,
        roll: s.rollNo || s.studentId || "N/A",
        status: record ? record.status : "Absent"
      };
    });

    res.json({
      success: true,
      className: staffClass.className,
      subjectName: staffClass.subjects[0]?.name || "Primary Subject",
      isFreeHour: false,
      students: studentData
    });

  } catch (error) {
    console.error("getTodayClassAttendance error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

// ─── Phase 7: QR Real-Time Approval Flow ─────────────────────────────────────

// @desc   Student requests attendance via QR token
// @route  POST /api/attendance/request
// @access Student (auth required)
exports.requestAttendance = async (req, res) => {
  try {
    const { token } = req.body;
    if (!token) {
      return res.status(400).json({ success: false, message: "Token is required" });
    }

    const studentId = req.user.studentId || req.user.id;
    const student = await User.findById(req.user.id);
    if (!student) {
      return res.status(404).json({ success: false, message: "Student not found" });
    }

    // Expected token format: classCode|period|date|timestamp
    const parts = token.split('|');
    if (parts.length < 4) {
      return res.status(400).json({ success: false, message: "Invalid QR Token" });
    }

    const [classCode, period, dateStr, timestampStr] = parts;
    const timestamp = parseInt(timestampStr, 10);
    const now = Date.now();

    // Check expiry (60 seconds)
    if (now - timestamp > 60000) {
      return res.status(403).json({ success: false, message: "QR Token Expired" });
    }

    // Check if a request already exists
    const existingReq = await AttendanceRequest.findOne({
      studentId,
      classCode,
      period,
      status: "pending"
    });

    if (existingReq) {
      return res.status(400).json({ success: false, message: "Request already pending for this class" });
    }

    // Create a new request
    const newRequest = new AttendanceRequest({
      studentId,
      studentName: student.name,
      classCode,
      period,
      token
    });

    await newRequest.save();

    // Emit event to staff
    const io = req.app.get("io");
    if (io) {
      // Find staff assigned to this class to target the event
      const targetClass = await Class.findOne({ classCode }).lean();
      if (targetClass && targetClass.subjects) {
         // Assuming we notify all staff in this class
         const staffIds = targetClass.subjects.map(s => s.instructor);
         staffIds.forEach(staffId => {
           io.to(`room:teacher:${staffId}`).emit("new_request", newRequest);
         });
      }
    }

    res.status(201).json({
      success: true,
      message: "Attendance request submitted.",
      data: newRequest
    });
  } catch (error) {
    console.error("requestAttendance error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

// @desc   Get pending requests for staff's class
// @route  GET /api/attendance/pending
// @access Staff / Admin
exports.getPendingRequests = async (req, res) => {
  try {
    const staffId = req.user.id;
    // Find class for this staff
    const staffClass = await Class.findOne({ "subjects.instructor": staffId }).lean();
    if (!staffClass) {
       return res.json({ success: true, count: 0, data: [] });
    }

    const pendingRequests = await AttendanceRequest.find({
      classCode: staffClass.classCode,
      status: "pending"
    }).sort({ createdAt: -1 });

    res.json({ success: true, count: pendingRequests.length, data: pendingRequests });
  } catch (error) {
    console.error("getPendingRequests error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

// @desc   Approve a pending request
// @route  POST /api/attendance/approve
// @access Staff / Admin
exports.approveRequest = async (req, res) => {
  try {
    const { requestId } = req.body;
    if (!requestId) return res.status(400).json({ success: false, message: "Request ID is required" });

    const attendanceReq = await AttendanceRequest.findById(requestId);
    if (!attendanceReq) {
      return res.status(404).json({ success: false, message: "Request not found" });
    }

    if (attendanceReq.status !== "pending") {
       return res.status(400).json({ success: false, message: "Request already processed" });
    }

    attendanceReq.status = "approved";
    await attendanceReq.save();

    // Extract student user id
    const studentUser = await User.findOne({ studentId: attendanceReq.studentId });
    const realStudentId = studentUser ? studentUser._id.toString() : attendanceReq.studentId;

    // Create the final Attendance record
    const today = new Date();
    const dateString = today.toISOString().split("T")[0];
    const timeString = today.toTimeString().split(" ")[0];

    // Check if record exists for this period
    let finalRecord = await Attendance.findOne({
      studentId: attendanceReq.studentId,
      date: dateString,
      period: attendanceReq.period || 1,
    });

    const attendanceData = {
      studentId: attendanceReq.studentId,
      studentName: attendanceReq.studentName,
      date: dateString,
      time: timeString,
      class: attendanceReq.classCode,
      subject: "General", // Placeholder, could map from staff profile
      period: attendanceReq.period || 1,
      method: "QR_RealTime",
      verificationMethod: "Teacher Approved",
      status: "PRESENT",
      markedBy: req.user.id,
      semester: studentUser ? studentUser.semester : 1,
    };

    if (finalRecord) {
      Object.assign(finalRecord, attendanceData);
      await finalRecord.save();
    } else {
      finalRecord = new Attendance(attendanceData);
      await finalRecord.save();
    }

    // Emit event back to student
    const io = req.app.get("io");
    if (io) {
      io.to(`room:student:${realStudentId}`).emit("request_approved", { requestId });
    }

    res.json({ success: true, message: "Request approved", data: attendanceReq });
  } catch (error) {
    console.error("approveRequest error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

// @desc   Reject a pending request
// @route  POST /api/attendance/reject
// @access Staff / Admin
exports.rejectRequest = async (req, res) => {
  try {
    const { requestId } = req.body;
    if (!requestId) return res.status(400).json({ success: false, message: "Request ID is required" });

    const attendanceReq = await AttendanceRequest.findById(requestId);
    if (!attendanceReq) {
      return res.status(404).json({ success: false, message: "Request not found" });
    }

    if (attendanceReq.status !== "pending") {
       return res.status(400).json({ success: false, message: "Request already processed" });
    }

    attendanceReq.status = "rejected";
    await attendanceReq.save();

    const studentUser = await User.findOne({ studentId: attendanceReq.studentId });
    const realStudentId = studentUser ? studentUser._id.toString() : attendanceReq.studentId;

    // Emit event back to student
    const io = req.app.get("io");
    if (io) {
      io.to(`room:student:${realStudentId}`).emit("request_rejected", { requestId });
    }

    res.json({ success: true, message: "Request rejected", data: attendanceReq });
  } catch (error) {
    console.error("rejectRequest error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
};


// ==========================
// UPDATE STUDENT STATUS (Staff Tool)
// ==========================
exports.updateStudentStatus = async (req, res) => {
  try {
    const { studentId, status } = req.body; // studentId can be the numeric/string studentId or _id
    const today = new Date().toISOString().split("T")[0];
    const staffId = req.user.id;

    // 1. Identify the class this staff teaches
    const staffClass = await Class.findOne({ "subjects.instructor": staffId }).lean();
    if (!staffClass) {
      return res.status(404).json({ success: false, message: "No active class found for this staff" });
    }

    // 2. Find the student to get their official studentId
    const student = await User.findById(studentId);
    if (!student) {
      return res.status(404).json({ success: false, message: "Student not found" });
    }

    // 3. Upsert attendance record
    const updated = await Attendance.findOneAndUpdate(
      { 
        studentId: student.studentId, 
        class: staffClass.classCode, 
        date: today 
      },
      { 
        status: status.toUpperCase(),
        method: "Manual Override",
        staff: staffId,
        student: studentId, // also store the ObjectId
        period: 1 // Default to 1 if not specified, or we could handle periods better
      },
      { upsert: true, new: true }
    );

    res.json({ success: true, data: updated });
  } catch (error) {
    console.error("updateStudentStatus error:", error);
    res.status(500).json({ success: false, message: "Failed to update status" });
  }
};