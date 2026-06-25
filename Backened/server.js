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

// 🔥 TASK SCHEDULER FOR EXAM DEADLINES
const cron = require("node-cron");
const Quiz = require("./models/Quiz");
const User = require("./models/User");
const NotificationService = require("./services/notificationService");

dotenv.config();

connectDB();

const app = express();

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE"],
  },
});

// ========================================================
// 🔥 FIREBASE ADMIN INITIALIZATION (BULLETPROOF CONFIG)
// ========================================================
let isFcmInitialized = false;
try {
  const serviceAccountPath = path.join(__dirname, "firebase-service-account.json");
  if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = require(serviceAccountPath);

    const credentialObj = admin.credential
      ? admin.credential.cert(serviceAccount)
      : require("firebase-admin/app").cert(serviceAccount);

    admin.initializeApp({
      credential: credentialObj
    });

    isFcmInitialized = true;
    console.log("🔥 Firebase Admin (FCM) Initialized globally for Background Pushes & Sounds!");
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
// 🔥 DUAL NOTIFICATION SYNC ROUTE MIDDLEWARE
// ========================================================
app.use((req, res, next) => {
  req.io = io;

  // 🔥 Bridge to trigger real-time socket updates for in-app context synchronously
  req.sendUniversalNotification = async ({ courseId, title, message, type, fcmTokens = [] }) => {
    if (courseId) {
      io.to(courseId.toString()).emit("new_notification", { title, message, type, courseId });
      console.log(`🔌 Sync Socket Alert broadcasted to Course Room: ${courseId}`);
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

// ==========================================================================
// 🔥 AUTOMATIC BACKGROUND WORKER: Runs every single minute safely
// ==========================================================================
// ==========================================================================
// 🔥 AUTOMATIC BACKGROUND WORKER: Runs every single minute safely
// ==========================================================================
// 🔥 AUTOMATIC BACKGROUND WORKER: MEMORY-LOCKED SINGLE BLAST ENGINE
// ==========================================================================
// Server memory mein notified quizzes ki IDs track karne ke liye set
const notifiedQuizzesCache = new Set();

cron.schedule("* * * * *", async () => {
  try {
    const now = new Date();
    const twoMinutesAgo = new Date(now.getTime() - 2 * 60 * 1000);

    // 1. Sirf unhi quizzes ko find karein jo window ke andar hain
    const expiredQuizzes = await Quiz.find({
      deadlineDateTime: { $gte: twoMinutesAgo, $lte: now },
      isExpiryNotified: { $ne: true }
    }).populate("course");

    for (const quiz of expiredQuizzes) {
      const quizIdStr = quiz._id.toString();

      // 🛑 CRITICAL SAFETY GUARD: Agar server memory cache mein ID maujood hai, toh foreign skip karo!
      if (notifiedQuizzesCache.has(quizIdStr)) {
        console.log(`⚠️ Blocked duplicate attempt for Quiz: "${quiz.title}" via Memory Cache.`);
        continue;
      }

      // 🔥 INSTANT MEMORY LOCK: Pehle memory mein block lagao, notification baad mein bhejenge
      notifiedQuizzesCache.add(quizIdStr);
      console.log(`🎯 Processing strict single notification for quiz: "${quiz.title}"`);

      if (quiz.course && quiz.course.students) {
        const studentIds = quiz.course.students.map(s => s.user.toString());

        if (studentIds.length > 0) {
          const users = await User.find({ _id: { $in: studentIds } }).select("fcmToken").lean();

          for (const user of users) {
            if (user.fcmToken && user.fcmToken.trim() !== "") {
              await NotificationService.sendPushNotification(
                user.fcmToken,
                "Exam Deadline Reached! 🕒",
                `The submission window for "${quiz.title}" is now officially closed.`,
                { courseId: quiz.course._id.toString(), type: "quiz_expired" }
              );
            }
          }
        }
      }

      // Database ko backup ke taur par update kar dein
      await Quiz.updateOne({ _id: quiz._id }, { $set: { isExpiryNotified: true } });
      console.log(`✅ Auto-Expiry Notification Sent & Memory Locked for Quiz: "${quiz.title}"`);

      // Memory clean karne ke liye: 5 minute baad cache se ID nikal dein taake ram full na ho
      setTimeout(() => {
        notifiedQuizzesCache.delete(quizIdStr);
      }, 5 * 60 * 1000);
    }
  } catch (cronErr) {
    console.log("Background Deadline Scheduler Exception Error:", cronErr.message);
  }
});

const PORT = process.env.PORT || 5002;

server.listen(PORT, '0.0.0.0', () => {
    console.log(`Server is running on port ${PORT} with Universal Live Notification Engine.`);
});