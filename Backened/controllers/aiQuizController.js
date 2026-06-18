const path = require("path");
const fs = require("fs");
const Quiz = require("../models/Quiz");
const Course = require("../models/Course");
const { generateQuizPDF } = require("../utils/quizPdfGenerator");
const { callAI } = require("../services/aiService");
const pdfParse = require("pdf-parse");

exports.createAIQuestionQuiz = async (req, res) => {
  try {
    let { courseId, topic, prompt, courseTitle, difficulty = "hard", shortCount = 0, longCount = 0, shortEachMark = 2, longEachMark = 5, type = "long" } = req.body;

    const finalCourseId = (courseId && courseId !== "UNKNOWN") ? courseId : null;
    let finalTopic = topic || prompt || courseTitle || "General Subjective Assessment";

    let finalTeacherId = "6a2b27ef72643f1a4b2e7b2f";
    if (req.user && req.user._id) {
       finalTeacherId = req.user._id;
    }

    const sCount = Number(shortCount) || 0;
    const lCount = Number(longCount) || 0;
    const sEach = Number(shortEachMark) || 2;
    const lEach = Number(longEachMark) || 5;

    let extractedText = "";

    // 🔥 HIGH LIMIT PDF EXTRACTION
    if (req.file && req.file.mimetype === "application/pdf") {
      try {
          const dataBuffer = fs.readFileSync(req.file.path);
          const pdfData = await pdfParse(dataBuffer);
          extractedText = pdfData.text ? pdfData.text.substring(0, 25000) : "";
      } catch(e) {}
    }

    let formatRequirementText = "";
    if (type === "short") {
      formatRequirementText = `Generate EXACTLY ${sCount} short questions. \nJSON Layout:\n{ "title": "Short Paper", "description": "...", "shortQuestions": [{ "question": "...", "marks": ${sEach}, "idealAnswer": "Detailed technical answer.", "rubric": "Step-by-step marks allocation." }] }`;
    } else if (type === "long") {
      formatRequirementText = `Generate EXACTLY ${lCount} long questions. \nJSON Layout:\n{ "title": "Long Paper", "description": "...", "longQuestions": [{ "question": "...", "marks": ${lEach}, "idealAnswer": "In-depth multi-paragraph solution blueprint.", "rubric": "Detailed grading framework (e.g., 2 marks for intro, 3 marks for core logic)." }] }`;
    } else {
      formatRequirementText = `Generate ${sCount} short and ${lCount} long questions. \nJSON Layout:\n{ "title": "Mixed Paper", "description": "...", "shortQuestions": [{ "question": "...", "marks": ${sEach}, "idealAnswer": "...", "rubric": "..." }], "longQuestions": [{ "question": "...", "marks": ${lEach}, "idealAnswer": "...", "rubric": "..." }] }`;
    }

    // 🔥 HIGH-LEVEL UNIVERSITY PROMPT
    const groqPrompt = `You are a Senior Academic Assessor. Generate descriptive exam questions.
Topic: ${finalTopic}
Difficulty: ${difficulty}
${extractedText ? `Reference Text Context:\n${extractedText}\n\n` : ''}
STRICT RULE: Respond with clean raw JSON only. Provide deeply detailed 'idealAnswer' and a specific 'rubric' for fair grading.
${formatRequirementText}`;

    // 🔥 CALL GROQ AI
const aiData = await callAI({ prompt: groqPrompt, model: "llama-3.1-70b-versatile" });
    if (!aiData || (!aiData.shortQuestions && !aiData.longQuestions)) {
      return res.status(500).json({ success: false, message: "Invalid JSON structure from Groq" });
    }

    const dbShortArray = (aiData.shortQuestions || []).slice(0, sCount).map(q => ({ question: q.question, marks: sEach, idealAnswer: q.idealAnswer || "Brief solution.", rubric: q.rubric || "Standard marks." }));
    const dbLongArray = (aiData.longQuestions || []).slice(0, lCount).map(q => ({ question: q.question, marks: lEach, idealAnswer: q.idealAnswer || "Detailed solution.", rubric: q.rubric || "Full architectural details." }));
    const totalMarks = (dbShortArray.length * sEach) + (dbLongArray.length * lEach);

    const uploadDir = path.join(__dirname, "../uploads");
    if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

    const fileName = `quiz-${Date.now()}.pdf`;
    const filePath = path.join(uploadDir, fileName);

    aiData.shortQuestions = dbShortArray;
    aiData.longQuestions = dbLongArray;
    aiData.grandTotalMarks = totalMarks;

    await generateQuizPDF(aiData, filePath);

    const savedQuizModel = new Quiz({
      course: finalCourseId,
      teacher: finalTeacherId,
      title: aiData.title || `Written Exam Paper for ${finalTopic}`,
      description: aiData.description || "In-Depth Descriptive Assessment",
      type: type === "both" ? "mixed" : "question",
      shortQuestions: dbShortArray,
      longQuestions: dbLongArray,
      totalMarks: totalMarks,
      isAIScanned: false
    });

    await savedQuizModel.save();
    if (req.file && fs.existsSync(req.file.path)) fs.unlinkSync(req.file.path);

    return res.status(200).json({
      success: true,
      message: "Quiz generated perfectly using Groq",
      pdfUrl: `${req.protocol}://${req.get("host")}/uploads/${fileName}`,
      quiz: savedQuizModel
    });

  } catch (error) {
    console.error("AI Generation Error:", error.message);
    return res.status(500).json({ success: false, message: error.message });
  }
};