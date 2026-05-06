const mongoose = require("mongoose");

const attendanceRequestSchema = new mongoose.Schema({
  studentId: {
    type: String,
    required: true,
  },
  studentName: {
    type: String,
    required: true,
  },
  classCode: {
    type: String,
    required: true,
  },
  period: {
    type: Number,
    required: true,
    default: 1,
  },
  token: {
    type: String,
    required: true,
  },
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected'],
    default: 'pending',
  },
  createdAt: {
    type: Date,
    default: Date.now,
    expires: 600, // 10 minutes TTL document expiration
  }
});

module.exports = mongoose.model("AttendanceRequest", attendanceRequestSchema);
