const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, "Name is required"],
    trim: true
  },
  email: {
    type: String,
    required: [true, "Email is required"],
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^\S+@\S+\.\S+$/, "Please enter a valid email"]
  },
  password: {
    type: String,
    required: [true, "Password is required"],
    minlength: 6
  },
  studentId: {
    type: String,
    unique: true,
    sparse: true
  },
  rollNo: String,
  role: {
    type: String,
    enum: ["STUDENT", "STAFF", "ADMIN"],
    default: "STUDENT"
  },
  department: String,
  semester: {
    type: Number,
    min: 1,
    max: 8
  },
  phone: String,
  profileImage: String,
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

// Hash password before saving
userSchema.pre("save", async function(next) {
  if (!this.isModified("password")) return next();
  
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    this.updatedAt = Date.now();
    next();
  } catch (error) {
    next(error);
  }
});

// Method to compare password
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

// Update timestamp on update
userSchema.pre("findOneAndUpdate", function(next) {
  this.set({ updatedAt: Date.now() });
  next();
});

module.exports = mongoose.model("User", userSchema);