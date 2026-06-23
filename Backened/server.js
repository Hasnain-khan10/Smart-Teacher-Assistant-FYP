const express = require("express");
const dotenv = require("dotenv");
const cors = require("cors");
const connectDB = require("./config/db");
const fs = require("fs");
const path = require("path");
// 🔥 SOCKET INTEGRATION MODULES
const http = require("http");
const { Server } = require("socket.io");

dotenv.config();

connectDB();

const app = express();

// 🔥 Create HTTP Server to wrap Express and Socket.io together
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*", // Allows any frontend local machine/device to connect smoothly
    methods: ["GET", "POST", "PUT", "DELETE"],
  },
});

// ✅ Ensure uploads folder exists (safe even if already created)
const uploadPath = path.join(__dirname, "uploads");
if (!fs.existsSync(uploadPath)) {
  fs.mkdirSync(uploadPath, { recursive: true });
}

// Middlewares
app.use(express.json());
app.use(cors());

// 🔥 Share Socket Instance with all routes/controllers globally via req object
app.use((req, res, next) => {
  req.io = io;
  next();
});

// Real-Time Socket Connection Handlers
io.on("connection", (socket) => {
  console.log(`🔌 Local Ecosystem Device Connected: ${socket.id}`);

  // Students will join a room based on their courseId to receive custom push updates
  socket.on("join_course_room", (courseId) => {
    socket.join(courseId);
    console.log(`📁 Device successfully registered to Course Room: ${courseId}`);
  });

  socket.on("disconnect", () => {
    console.log(`❌ Device Disconnected from Socket: ${socket.id}`);
  });
});

// Routes
const authRoutes = require("./routes/authRoutes");
app.use("/api/auth", authRoutes);

const courseRoutes = require("./routes/courseRoutes");
app.use("/api/courses", courseRoutes);

const planRoutes = require("./routes/planRoutes");
app.use("/api/plans", planRoutes);

const slideRoutes = require("./routes/slideRoutes");
app.use("/api/slides", slideRoutes);

const pdfRoutes = require("./routes/pdfRoutes");
app.use("/api/pdf", pdfRoutes);

const quizRoutes = require("./routes/quizRoutes");
app.use("/api/quizzes", quizRoutes);

const aiCourseRoutes = require("./routes/aiCourseRoutes");
app.use("/api/ai", aiCourseRoutes);

const aiplanWeekRoutes = require("./routes/aiplanRoutes");
app.use("/api/ai/plans", aiplanWeekRoutes);

const aiQuizRoutes = require("./routes/aiquizRoutes");
app.use("/api/ai/quizzes", aiQuizRoutes);

// ✅ Serve static PDFs
app.use("/uploads", express.static(uploadPath));

app.get("/", (req, res) => {
  res.send("API is running with Real-time Socket Gateway...");
});

const PORT = process.env.PORT || 5002;

// 🔥 FIXED: app.listen swapped with server.listen to safely execute express + socket events simultaneously
server.listen(PORT, '0.0.0.0', () => {
    console.log(`Server is running on port ${PORT} with Live Notification Engine.`);
});