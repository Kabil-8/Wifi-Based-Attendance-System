const mongoose = require("mongoose");

const classSchema = new mongoose.Schema({
  classCode: {
    type: String,
    required: true,
    unique: true
  },
  className: {
    type: String,
    required: true
  },
  department: {
    type: String,
    required: true
  },
  semester: {
    type: Number,
    required: true
  },
  subjects: [{
    code: String,
    name: String,
    instructor: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User"
    },
    schedule: {
      day: String,
      time: String,
      room: String
    }
  }],
  students: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: "User"
  }],
  totalStrength: Number,
  location: {
    room: String,
    building: String,
    latitude: Number,
    longitude: Number,
    wifiRouter: String
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User"
  },
  isActive: {
    type: Boolean,
    default: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model("Class", classSchema);