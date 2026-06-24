const express = require("express");
const dotenv = require("dotenv");
const cors = require("cors");
const connectDB = require("./config/db");
const fs = require("fs");
const path = require("path");

// 🔥 SOCKET & FIREBASE INTEGRATION MODULES
const http = require("http");
const { Server } = require("socket.io");
const admin = require("firebase-admin");

dotenv.config();

connectDB();

const app = express();

// 🔥 Create HTTP Server to wrap Express and Socket.io together
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE"],
  },
});

// ========================================================
// 🔥 FIREBASE ADMIN INITIALIZATION (BULLETPROOF FIX)
// ========================================================
let isFcmInitialized = false;
try {
  const serviceAccountPath = path.join(__dirname, "firebase-service-account.json");
  if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = require(serviceAccountPath);

    // 🔥 Direct fallback method check to read cert properties safely
    const credentialObj = admin.credential
      ? admin.credential.cert(serviceAccount)
      : require("firebase-admin/app").cert(serviceAccount);

    admin.initializeApp({
      credential: credentialObj
    });

    isFcmInitialized = true;
    console.log("🔥 Firebase Admin (FCM) Initialized for Background Pushes & Sounds!");
  } else {
    console.log("⚠️ FCM Warning: 'firebase-service-account.json' missing. Background pushes paused (Socket running).");
  }
} catch (error) {
  console.log("⚠️ FCM Initialization Error:", error.message);
}

// Ensure uploads folder exists
const uploadPath = path.join(__dirname, "uploads");
if (!fs.existsSync(uploadPath)) {
  fs.mkdirSync(uploadPath, { recursive: true });
}

// Middlewares
app.use(express.json());
app.use(cors());

// ========================================================
// 🔥 UNIVERSAL NOTIFICATION ENGINE (Socket + Background FCM)
// ========================================================
app.use((req, res, next) => {
  req.io = io;

  req.sendUniversalNotification = async ({ courseId, title, message, type, fcmTokens = [] }) => {

    // 1. IN-APP FOREGROUND (Socket.io)
    if (courseId) {
      io.to(courseId.toString()).emit("new_notification", { title, message, type, courseId });
    }

    // 2. BACKGROUND / TERMINATED (Firebase FCM with Custom Sound)
    if (isFcmInitialized && fcmTokens.length > 0) {
      const payload = {
        notification: {
          title: title,
          body: message,
        },
        data: {
          type: type || "general",
          courseId: courseId ? courseId.toString() : ""
        },
        android: {
          priority: "high",
          notification: {
            sound: "smart_sound",
            channelId: "smart_teacher_channel"
          }
        },
        tokens: fcmTokens
      };

      try {
        const response = await admin.messaging().sendEachForMulticast(payload);
        console.log(`✅ FCM Sent: ${response.successCount} successful, ${response.failureCount} failed.`);
      } catch (error) {
        console.log("❌ FCM Push Error:", error.message);
      }
    }
  };

  next();
});

// Real-Time Socket Connection Handlers
io.on("connection", (socket) => {
  console.log(`🔌 Local Ecosystem Device Connected: ${socket.id}`);

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

app.use("/uploads", express.static(uploadPath));

app.get("/", (req, res) => {
  res.send("API is running with Universal Real-time Notification Engine...");
});

const PORT = process.env.PORT || 5002;

server.listen(PORT, '0.0.0.0', () => {
    console.log(`Server is running on port ${PORT} with Universal Live Notification Engine.`);
});