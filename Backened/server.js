const express = require("express");
const dotenv = require("dotenv");
const cors = require("cors");
const connectDB = require("./config/db");
const fs = require("fs");
const path = require("path");

dotenv.config();

connectDB();

const app = express();

// ✅ Ensure uploads folder exists (safe even if already created)
const uploadPath = path.join(__dirname, "uploads");
if (!fs.existsSync(uploadPath)) {
  fs.mkdirSync(uploadPath, { recursive: true });
}

// Middlewares
app.use(express.json());
app.use(cors());

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
app.use("/api/plans", aiplanWeekRoutes);

const aiQuizRoutes = require("./routes/aiquizRoutes");
app.use("/api/quizzes", aiQuizRoutes);

// app.use("/api/quizzes", aiQuizRoutes);
// ✅ Serve static PDFs
app.use("/uploads", express.static(uploadPath));

app.get("/", (req, res) => {
  res.send("API is running...");
});

const PORT = process.env.PORT || 5002;

// localhost hatakar '0.0.0.0' lazmi likhna hai taake network ke saare devices connect ho sakein
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server is running on port ${PORT}`);
});