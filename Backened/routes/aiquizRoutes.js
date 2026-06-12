const express = require("express");
const router = express.Router();

const { createAIQuestionQuiz } = require("../controllers/aiQuizController");
const {
  createAIMCQQuiz
} = require("../controllers/aiMcqQuizController");

router.post("/question", createAIQuestionQuiz);
router.post("/mcq", createAIMCQQuiz);

module.exports = router;