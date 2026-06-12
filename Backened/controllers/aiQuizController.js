const path = require("path");
const { callAI } = require("../services/aiService");
const { generateQuizPDF } = require("../utils/quizPdfGenerator");

exports.createAIQuestionQuiz = async (req, res) => {
  try {
    const {
      topic,
      difficulty,

      shortCount,
      longCount,

      shortMarks,
      longMarks,

      shortEachMark,
      longEachMark,

      type
    } = req.body;

    if (!topic) {
      return res.status(400).json({ message: "Topic is required" });
    }

    const mode = type || "long";

    const sCount = Number(shortCount) || 0;
    const lCount = Number(longCount) || 10;

    const sEach = Number(shortEachMark) || 1;
    const lEach = Number(longEachMark) || 5;

    const sTotal = Number(shortMarks) || sCount * sEach;
    const lTotal = Number(longMarks) || lCount * lEach;

    const grandTotal = sTotal + lTotal;

    // 🧠 PROMPT BUILDER
    let prompt = `
You are a strict university exam paper generator.

TOPIC: ${topic}
DIFFICULTY: ${difficulty || "medium"}

CRITICAL RULES:
- Follow exact counts
- DO NOT add extra questions
- DO NOT include answers
- DO NOT include explanations
- This is a printable exam paper
`;

    if (mode === "short") {
      prompt += `
Generate EXACTLY ${sCount} SHORT questions.

FORMAT:
{
  "title": "",
  "description": "",
  "questions": [
    {
      "question": "",
      "marks": ${sEach}
    }
  ]
}
`;
    }

    else if (mode === "long") {
      prompt += `
Generate EXACTLY ${lCount} LONG questions.

FORMAT:
{
  "title": "",
  "description": "",
  "questions": [
    {
      "question": "",
      "marks": ${lEach}
    }
  ]
}
`;
    }

    else if (mode === "both") {
      prompt += `
Generate EXACTLY:
- ${sCount} SHORT questions
- ${lCount} LONG questions

FORMAT:

{
  "title": "",
  "description": "",
  "shortQuestions": [
    { "question": "", "marks": ${sEach} }
  ],
  "longQuestions": [
    { "question": "", "marks": ${lEach} }
  ]
}
`;
    }

    // 🤖 AI CALL
    const aiResponse = await callAI(prompt);

    let aiData;
    try {
      aiData =
        typeof aiResponse === "string"
          ? JSON.parse(aiResponse)
          : aiResponse;
    } catch (err) {
      return res.status(500).json({
        message: "AI returned invalid JSON"
      });
    }

    // 🛑 VALIDATION
    const validate = (arr, expected, label) => {
      if (expected > 0 && (!arr || arr.length !== expected)) {
        throw new Error(`${label} mismatch: expected ${expected}`);
      }
    };

    if (mode === "short") validate(aiData.questions, sCount, "Short");
    if (mode === "long") validate(aiData.questions, lCount, "Long");
    if (mode === "both") {
      validate(aiData.shortQuestions, sCount, "Short");
      validate(aiData.longQuestions, lCount, "Long");
    }

    // 🧠 TOTAL SCORE CALCULATION (IMPORTANT PART)
    const studentScoreSystem = {
      shortTotal: sTotal,
      longTotal: lTotal,
      grandTotal,

      gradingScale: {
        A: 0.85 * grandTotal,
        B: 0.70 * grandTotal,
        C: 0.50 * grandTotal,
        F: 0
      }
    };

    // 📄 PDF GENERATION
    const fileName = `quiz-${Date.now()}.pdf`;
    const filePath = path.join(__dirname, `../uploads/${fileName}`);

    await generateQuizPDF(aiData, filePath);

    const pdfUrl = `${req.protocol}://${req.get("host")}/uploads/${fileName}`;

    return res.status(200).json({
      message: `${mode} quiz generated successfully`,
      pdfUrl,
      quiz: aiData,

      // 🔥 NEW SCORING SYSTEM OUTPUT
      scoring: studentScoreSystem
    });

  } catch (error) {
    console.log("QUIZ ERROR:", error);
    res.status(500).json({ message: error.message });
  }
};