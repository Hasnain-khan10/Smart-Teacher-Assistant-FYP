const express = require("express");
const router = express.Router();
const upload = require("../middleware/upload");

const {
  createQuiz,
  getAllQuizzes,
  getQuizResults,
  getQuizzesByCourse,
  generateQuestionQuizPDF,
  updateQuiz,
  deleteQuiz,
  attemptQuiz,
  scanAIQuizMarks,
  updateManualMarks, // 🔥 Imported perfectly

  // AI QUIZ
  createAIMCQQuiz,
  createAIQuestionQuiz,
  generateAIQuestionQuizPDF,
} = require("../controllers/quizController");

const { protect } = require("../middleware/authMiddleware");
const { authorizeRoles } = require("../middleware/roleMiddleware");

// ===============================
// 👨‍🏫 TEACHER ONLY (CRUD)
// ===============================
router.post("/", protect, authorizeRoles("teacher"), createQuiz);
router.put("/:id", protect, authorizeRoles("teacher"), updateQuiz);
router.delete("/:id", protect, authorizeRoles("teacher"), deleteQuiz);

router.get(
   "/pdf/:id",
  protect,
  authorizeRoles("teacher", "student"),
  generateQuestionQuizPDF
);

// ===============================
// 👨‍🏫 + 👨‍🎓 BOTH (VIEW)
// ===============================
router.get("/", protect, authorizeRoles("teacher", "student"), getAllQuizzes);

router.get(
  "/results/:quizId",
  protect,
  authorizeRoles("teacher"),
  getQuizResults
);

router.get(
  "/course/:courseId",
  protect,
  authorizeRoles("teacher", "student"),
  getQuizzesByCourse
);

// ===============================
// 👨‍🎓 STUDENT ONLY (ATTEMPT)
// ===============================
router.post(
  "/attempt/:id",
  protect,
  authorizeRoles("student"),
  attemptQuiz
);

router.post(
  "/scan-ai-marks",
  protect,
  upload.array("files", 50),
  authorizeRoles("teacher"),
  scanAIQuizMarks
);

// ===============================
// 🔥 UPDATE MANUAL MARKS OVERRIDE
// ===============================
router.put(
  "/manual-score/:attemptId",
  protect,
  authorizeRoles("teacher"),
  updateManualMarks
);

// ===============================
// 🤖 AI QUIZ ROUTES (TEACHER)
// ===============================

// MCQ AI Quiz
router.post(
  "/ai/mcq",
  protect,
  upload.single("file"),
  authorizeRoles("teacher"),
  createAIMCQQuiz
);

// Short / Long / Mixed AI Question Quiz
router.post(
  "/ai/question",
  protect,
  upload.single("file"),
  authorizeRoles("teacher"),
  createAIQuestionQuiz
);

// ===============================
// 📄 AI QUESTION PDF (FROM DB QUIZ)
// ===============================
router.get(
  "/ai/question/pdf/:quizId",
  protect,
  authorizeRoles("teacher", "student"),
  generateAIQuestionQuizPDF
);

module.exports = router;