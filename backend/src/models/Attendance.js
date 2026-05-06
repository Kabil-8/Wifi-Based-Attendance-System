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
    enum: ["fingerprint", "face", "manual", "qr", "staff"],
    default: "manual"
  },
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

// Compound index for unique attendance per student per day per class
attendanceSchema.index({ studentId: 1, date: 1, class: 1 }, { unique: true });

module.exports = mongoose.model("Attendance", attendanceSchema);