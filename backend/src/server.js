const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");
const path = require("path");
const fs = require("fs");

// Load environment variables
dotenv.config();

// Import database connection
const connectDB = require("./config/database");

// Initialize express app
const app = express();
const http = require("http");
const { Server } = require("socket.io");

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

app.set("io", io);

io.on("connection", (socket) => {
  console.log("New client connected: " + socket.id);

  socket.on("join_teacher_room", (userId) => {
    const roomName = `room:teacher:${userId}`;
    socket.join(roomName);
    console.log(`Socket ${socket.id} joined ${roomName}`);
  });

  socket.on("join_student_room", (userId) => {
    const roomName = `room:student:${userId}`;
    socket.join(roomName);
    console.log(`Socket ${socket.id} joined ${roomName}`);
  });

  socket.on("disconnect", () => {
    console.log("Client disconnected: " + socket.id);
  });
});

// Create uploads directory if it doesn't exist
const uploadsDir = path.join(__dirname, "../uploads");
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Middleware
app.use(cors({
  origin: "*",
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use("/uploads", express.static(uploadsDir));

// Connect to MongoDB
connectDB();

// Import routes
const authRoutes = require("./routes/authRoutes");
const attendanceRoutes = require("./routes/attendanceRoutes");
const adminRoutes = require("./routes/adminRoutes");
const staffRoutes = require("./routes/staffRoutes");
const studentRoutes = require("./routes/studentRoutes");
const classRoutes = require("./routes/classRoutes");
const reportsRoutes = require("./routes/reportsRoutes");

// Use routes
app.use("/api/auth", authRoutes);
app.use("/api/attendance", attendanceRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/staff", staffRoutes);
app.use("/api/student", studentRoutes);
app.use("/api/class", classRoutes);
app.use("/api/reports", reportsRoutes);

// SIMPLE TEST ROUTES (Remove other route imports temporarily)
app.get("/api/health", (req, res) => {
  res.json({
    success: true,
    message: "Server is running",
    timestamp: new Date().toISOString()
  });
});

/*app.get("/api/student/dashboard", (req, res) => {
  res.json({ test: "DIRECT ROUTE WORKING" });
});*/


app.get("/api/test", (req, res) => {
  res.json({
    success: true,
    message: "Test endpoint working"
  });
});

// Basic auth test route
/*app.post("/api/auth/login", (req, res) => {
  const { email, password } = req.body;
  if (email && password) {
    res.json({
      success: true,
      message: "Login successful (demo)",
      token: "demo-token",
      user: { name: "Demo User", email: email, role: "STUDENT" }
    });
  } else {
    res.status(400).json({ success: false, message: "Email and password required" });
  }
});*/

// 404 handler
app.use((req, res) => {
  res.status(404).json({ success: false, message: "Route not found" });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error("Server Error:", err.message);
  res.status(500).json({
    success: false,
    message: "Internal server error",
    error: process.env.NODE_ENV === "development" ? err.message : undefined
  });
});

const PORT = process.env.PORT || 5000;

server.listen(PORT, "0.0.0.0", () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`🔗 Health check: http://localhost:${PORT}/api/health`);
  console.log(`🔗 Test endpoint: http://localhost:${PORT}/api/test`);
});