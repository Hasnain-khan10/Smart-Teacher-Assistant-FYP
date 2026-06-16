const express = require("express");
const router = express.Router();
const upload = require("../middleware/upload"); // 🔥 Multer import kiya file parsing ke liye

// Controllers Import
const { createAIQuestionQuiz } = require("../controllers/aiQuizController");
const { createAIMCQQuiz } = require("../controllers/aiMcqQuizController");

// ====================================================
// 🤖 AI QUIZ GENERATION ENDPOINTS
// ====================================================

// 📝 1. Short / Long / Mixed Questions Generator
// Endpoint: POST /api/ai/quizzes/question (Ya jo aapne server.js mein bind kiya hai)
router.post("/question", upload.single("book"), createAIQuestionQuiz);

// 🎯 2. Multiple Choice Questions (MCQ) Generator
// Endpoint: POST /api/ai/quizzes/mcq
router.post("/mcq", upload.single("book"), createAIMCQQuiz);

module.exports = router;