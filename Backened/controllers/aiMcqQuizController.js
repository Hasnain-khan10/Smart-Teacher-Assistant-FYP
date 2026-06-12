const path = require("path");
const { callAI } = require("../services/aiService");
const { generateQuizPDF } = require("../utils/quizPdfGenerator");


exports.createAIMCQQuiz = async (req, res) => {
  try {
    const {
      topic,
      difficulty,
      questionCount,
      marksPerQuestion
    } = req.body;

    if (!topic) {
      return res.status(400).json({ message: "Topic is required" });
    }

    const count = Number(questionCount) || 10;
    const perMark = Number(marksPerQuestion) || 1;
    const totalMarks = count * perMark;

    // 🧠 STRICT MCQ PROMPT (EXAM PAPER ONLY)
    const prompt = `
You are an expert university exam paper setter.

Create a REAL MCQ EXAM PAPER.

TOPIC: ${topic}
DIFFICULTY: ${difficulty || "medium"}

CRITICAL RULES:
- Generate EXACTLY ${count} MCQ questions
- Each question must have 4 options (A, B, C, D)
- DO NOT include correct answers
- DO NOT include explanations
- This is a PRINTABLE EXAM PAPER for students
- Add NO answer key

IMPORTANT:
- This is a paper for students to attempt manually

OUTPUT ONLY VALID JSON:

{
  "title": "",
  "description": "",
  "questions": [
    {
      "question": "",
      "options": {
        "A": "",
        "B": "",
        "C": "",
        "D": ""
      }
    }
  ]
}
`;

    // 🤖 AI CALL
    const aiResponse = await callAI(prompt);

    // 🧠 SAFE PARSE
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
    if (!aiData.questions || aiData.questions.length !== count) {
      return res.status(500).json({
        message: "Invalid MCQ quiz generated"
      });
    }

    const invalid = aiData.questions.some(q =>
      !q.question ||
      !q.options?.A ||
      !q.options?.B ||
      !q.options?.C ||
      !q.options?.D
    );

    if (invalid) {
      return res.status(500).json({
        message: "Invalid MCQ structure"
      });
    }

    // ❌ CLEAN ANY ANSWERS
    aiData.questions = aiData.questions.map(q => {
      delete q.correctAnswer;
      delete q.answer;
      return {
        ...q,
        marks: perMark // 🔥 EACH QUESTION MARK ADDED
      };
    });

    // 🧠 EXAM METADATA (VERY IMPORTANT FOR SCORING LATER)
    aiData.examMeta = {
      type: "MCQ_EXAM",
      totalQuestions: count,
      marksPerQuestion: perMark,
      totalMarks: totalMarks,
      mode: "student_printable_exam"
    };

    // 📄 PDF GENERATION (PRINTABLE PAPER)
    const fileName = `mcq-${Date.now()}.pdf`;
    const filePath = path.join(__dirname, `../uploads/${fileName}`);

    await generateQuizPDF(aiData, filePath);

    const pdfUrl = `${req.protocol}://${req.get("host")}/uploads/${fileName}`;

    return res.status(200).json({
      message: "MCQ exam paper generated successfully",
      pdfUrl,
      quiz: aiData
    });

  } catch (error) {
    console.log("MCQ ERROR:", error);
    res.status(500).json({ message: error.message });
  }
};