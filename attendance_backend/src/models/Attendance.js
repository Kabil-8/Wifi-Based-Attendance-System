const mongoose = require("mongoose");

const attendanceSchema = new mongoose.Schema({
  studentId: {
    type: String,
    required: true,
    ref: "User"
  },
  studentName: String,
  date: {
    type: String, // YYYY-MM-DD format
    required: true
  },
  time: {
    type: String, // HH:MM:SS format
    required: true
  },
  class: {
    type: String,
    required: true
  },
  subject: {
    type: String,
    required: true
  },
  method: {
    type: String,
    enum: ["fingerprint", "face", "manual", "qr", "staff", "Biometric+Router", "TripleLock"],
    default: "manual"
  },
  // ─── Verification fields ──────────────────────────────────────────────────
  verificationMethod: {
    type: String,
    default: "None",
    // e.g. "TripleLock-Fingerprint", "TripleLock-FaceScan", "Biometric+Router", "None", "Manual"
  },
  bssid: {
    type: String,
    default: "unknown"
  },
  deviceId: {
    type: String,
    default: "unknown"
  },
  reason: {
    // Only populated on failure/absence. Describes why the record was saved as Absent.
    type: String,
    default: null
  },
  // ─── Triple-Lock Security Fields ──────────────────────────────────────────
  securityTier: {
    type: String,
    enum: ["Tier1-WiFi", "Tier2-BioDomain", "Tier3A-Fingerprint", "Tier3B-FaceScan", "None"],
    default: "None"
  },
  biometricSignatureChanged: {
    type: Boolean,
    default: false
  },
  auditSelfieUrl: {
    type: String,
    default: null
  },
  flaggedForReview: {
    type: Boolean,
    default: false
  },
  flagReason: {
    type: String,
    default: null
    // e.g. "Biometric signature changed — face scan recorded for audit"
  },
  // ─────────────────────────────────────────────────────────────────────────
  status: {
    type: String,
    enum: ["PRESENT", "ABSENT", "OD", "LATE"],
    default: "PRESENT"
  },
  wifiRouter: {
    type: String,
    default: "unknown"
  },
  latitude: Number,
  longitude: Number,
  semester: {
    type: Number,
    required: true
  },
  period: {
    type: Number,
    min: 1,
    max: 8,
    default: 1
  },
  courseCode: String,
  imageUrl: String,
  faceVerified: {
    type: Boolean,
    default: false
  },
  fingerprintVerified: {
    type: Boolean,
    default: false
  },
  markedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true
  },
  notes: String,
  modifiedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User"
  },
  modifiedAt: Date,
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Compound index for unique attendance per student per day per class per period
attendanceSchema.index({ studentId: 1, date: 1, class: 1, period: 1 }, { unique: true });

// Index for quick flagged-record queries (staff audit dashboard)
attendanceSchema.index({ flaggedForReview: 1, date: -1 });

module.exports = mongoose.model("Attendance", attendanceSchema);