const path = require("path");
const fs = require("fs");
const Quiz = require("../models/Quiz");
const Course = require("../models/Course");
const { generateQuizPDF } = require("../utils/quizPdfGenerator");
const { callAI } = require("../services/aiService");
const pdfParse = require("pdf-parse");

exports.createAIMCQQuiz = async (req, res) => {
  try {
    // 🔒 STRICT GUARD: Prevent unauthorized AI API usage
    if (!req.user || req.user.role !== "teacher") {
      return res.status(403).json({ success: false, message: "Forbidden: AI Exam generation is restricted to instructors." });
    }

    let { courseId, topic, prompt, courseTitle, difficulty = "hard", questionCount, marksPerQuestion } = req.body;
    const finalCourseId = (courseId && courseId !== "UNKNOWN") ? courseId : null;
    let finalTopic = topic || prompt || courseTitle || "General Evaluation";

    if (finalTopic.trim() === "") {
        finalTopic = req.file ? "Evaluation strictly based on attached file" : "General Course Evaluation";
    }

    const finalTeacherId = req.user._id; // Secure context extraction
    const count = Number(questionCount) || 10;
    const perMark = Number(marksPerQuestion) || 1;
    let extractedText = "";

    if (req.file && req.file.mimetype === "application/pdf") {
      try {
          const dataBuffer = fs.readFileSync(req.file.path);
          const pdfData = await pdfParse(dataBuffer);
          extractedText = pdfData.text ? pdfData.text.substring(0, 25000) : "";
      } catch(e) {
          console.log("PDF parse warning:", e.message);
      }
    }

    const groqPrompt = `You are a Lead Examination Board Setter for a University.
Create a highly analytical Multiple Choice Question (MCQ) exam.
Topic: ${finalTopic}\nDifficulty: ${difficulty}\nTotal MCQs: ${count}
${extractedText ? `Reference Context Data:\n${extractedText}\n\n` : ''}
STRICT RULES:
1. Options must contain strong plausible distractors.
2. The explanation must clearly state WHY the correct option is right.
3. Return ONLY clean JSON.
JSON Format Layout:
{ "title": "Analytical MCQ Assessment: ${finalTopic}", "description": "High-level cognitive evaluation paper.", "questions": [ { "question": "Deep analytical question text?", "options": { "A": "Option A", "B": "Option B", "C": "Option C", "D": "Option D" }, "correctAnswer": "A", "explanation": "Detailed rationale explaining the correct concept." } ] }`;

    const aiData = await callAI({ prompt: groqPrompt, model: "llama-3.1-70b-versatile" });
    if (!aiData || !aiData.questions) {
      return res.status(500).json({ success: false, message: "Invalid JSON structure from AI" });
    }

    const formattedQuestions = (aiData.questions || []).slice(0, count).map(q => ({
      question: q.question || "Core evaluation query",
      options: { A: q.options?.A || "N/A", B: q.options?.B || "N/A", C: q.options?.C || "N/A", D: q.options?.D || "N/A" },
      correctAnswer: q.correctAnswer || "A",
      explanation: q.explanation || "Correct answer mapped dynamically.",
      marks: perMark
    }));

    const uploadDir = path.join(__dirname, "../uploads");
    if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

    const fileName = `mcq-${Date.now()}.pdf`;
    const filePath = path.join(uploadDir, fileName);

    aiData.questions = formattedQuestions;
    aiData.examMeta = { marksPerQuestion: perMark, totalMarks: formattedQuestions.length * perMark };

    await generateQuizPDF(aiData, filePath);

    const dbQuiz = new Quiz({
      course: finalCourseId, teacher: finalTeacherId,
      title: aiData.title || `${finalTopic} Assessment`,
      description: aiData.description || "University Level MCQ Exam",
      type: "mcq", questions: formattedQuestions,
      totalMarks: formattedQuestions.length * perMark,
      marksPerQuestion: perMark, examMeta: { type: "MCQ_EXAM", generatedBy: "GROQ_AI" }
    });

    await dbQuiz.save();
    if (req.file && fs.existsSync(req.file.path)) fs.unlinkSync(req.file.path);

    return res.status(200).json({
      success: true, message: "MCQ generated perfectly via Groq",
      pdfUrl: `${req.protocol}://${req.get("host")}/uploads/${fileName}`, quiz: dbQuiz
    });
  } catch (error) {
    console.error("AI Generation Error:", error.message);
    return res.status(500).json({ success: false, message: error.message });
  }
};