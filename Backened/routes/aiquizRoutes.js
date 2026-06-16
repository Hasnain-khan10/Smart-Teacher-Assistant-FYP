const express = require("express");
const router = express.Router();
const upload = require("../middleware/upload");

// Controllers Import
const { createAIQuestionQuiz } = require("../controllers/aiQuizController");
const { createAIMCQQuiz } = require("../controllers/aiMcqQuizController");

// ====================================================
// 🤖 AI QUIZ GENERATION ENDPOINTS
// ====================================================

// 🔥 FIX 1: "/question" ko "/descriptive" kar diya taake Flutter ki request yahan puhanch sakay!
router.post("/descriptive", upload.single("book"), createAIQuestionQuiz);

// MCQ Route
router.post("/mcq", upload.single("book"), createAIMCQQuiz);

module.exports = router;