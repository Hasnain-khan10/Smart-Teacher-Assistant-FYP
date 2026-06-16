const path = require("path");
const fs = require("fs");
const { GoogleGenAI } = require("@google/genai");
const Quiz = require("../models/Quiz");
const { generateQuizPDF } = require("../utils/quizPdfGenerator");

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

function fileToGenerativePart(filePath, mimeType) {
  return { inlineData: { data: Buffer.from(fs.readFileSync(filePath)).toString("base64"), mimeType } };
}

exports.createAIMCQQuiz = async (req, res) => {
  try {
    // 🔥 DYNAMIC KEY MAPPING: Accepts any variant from frontend
    let { courseId, course, teacherId, teacher, topic, prompt, courseTitle, difficulty = "medium", questionCount, marksPerQuestion } = req.body;

    const finalCourseId = courseId || course;
    const finalTeacherId = teacherId || teacher || "6a2b27ef72643f1a4b2e7b2f"; // Fallback to safe ID if null

    // Fallback topic selection
    let finalTopic = topic || prompt || courseTitle || "";

    if (!finalCourseId) {
      return res.status(400).json({ success: false, message: "Validation Failed: courseId or course identifier is missing." });
    }

    // 🔥 FIX: Either topic OR book file must be present
    if (finalTopic.trim() === "" && !req.file) {
      return res.status(400).json({ success: false, message: "Validation Failed: Please provide a Topic/Prompt OR upload a Reference Book." });
    }

    // If topic is empty but book is uploaded, give it a default context
    if (finalTopic.trim() === "" && req.file) {
      finalTopic = "Comprehensive evaluation based strictly on the attached reference material.";
    }

    const count = Number(questionCount) || 10;
    const perMark = Number(marksPerQuestion) || 1;

    let attachedFilePart = null;
    let isGroundingEnabled = true;

    if (req.file) {
      isGroundingEnabled = false; // Disable web search if reference material is provided
      let mimeType = "application/pdf";
      if (req.file.originalname.toLowerCase().endsWith(".docx")) mimeType = "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
      else if (req.file.mimetype !== "application/octet-stream") mimeType = req.file.mimetype;
      attachedFilePart = fileToGenerativePart(req.file.path, mimeType);
    }

    const systemInstruction = `
You are a Lead Examination Board Setter for top-tier Ivy League universities.
1. Create highly analytical, scenario-based multiple-choice questions. Avoid simple rote-memorization.
2. Provide a detailed explanation/rationale for WHY the correct answer is correct.
3. If a reference file is provided, STRICTLY extract concepts from it. If not, use your internet tools to find authentic facts.
4. Output STRICTLY as a valid JSON object.
`;

    const userPromptText = `
Design a premium MCQ Exam.
Topic/Context Focus: ${finalTopic}
Difficulty Level: ${difficulty}
Total MCQs Required: ${count}

Return a single JSON object structured EXACTLY like this:
{
  "title": "Analytical Assessment",
  "description": "High-level cognitive evaluation paper.",
  "questions": [
    {
      "question": "A real-world scenario or deep analytical question...",
      "options": { "A": "Option A", "B": "Option B", "C": "Option C", "D": "Option D" },
      "correctAnswer": "A",
      "explanation": "Detailed pedagogical rationale explaining why A is the correct choice."
    }
  ]
}
Generate exactly ${count} objects inside the questions array.
`;

    let contentsPayload = [];
    if (attachedFilePart) contentsPayload.push(attachedFilePart);
    contentsPayload.push(userPromptText);

    const response = await ai.models.generateContent({
      model: "gemini-3.5-flash",
      contents: contentsPayload,
      config: {
        systemInstruction: systemInstruction,
        responseMimeType: "application/json",
        temperature: 0.3,
        tools: isGroundingEnabled ? [{ googleSearch: {} }] : []
      }
    });

    let aiData;
    try {
      aiData = JSON.parse(response.text.trim());
    } catch (err) {
      return res.status(500).json({ success: false, message: "AI response processing layer collapsed into invalid JSON structure." });
    }

    const formattedQuestions = aiData.questions.map(q => ({
      question: q.question,
      options: { A: q.options?.A || "", B: q.options?.B || "", C: q.options?.C || "", D: q.options?.D || "" },
      correctAnswer: q.correctAnswer || "A",
      explanation: q.explanation || "Correct answer based on premium academic evaluation.",
      marks: perMark
    }));

    const uploadDir = path.join(__dirname, "../uploads");
    if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

    const fileName = `mcq-${Date.now()}.pdf`;
    const filePath = path.join(uploadDir, fileName);

    aiData.questions = formattedQuestions;
    aiData.examMeta = { marksPerQuestion: perMark, totalMarks: count * perMark };

    await generateQuizPDF(aiData, filePath);

    const dbQuiz = new Quiz({
      course: finalCourseId,
      teacher: finalTeacherId,
      title: aiData.title || `${finalTopic} Assessment`,
      description: aiData.description || "Premium AI Generated Quiz Workspace",
      type: "mcq",
      questions: formattedQuestions,
      totalMarks: count * perMark,
      marksPerQuestion: perMark,
      examMeta: { type: "MCQ_EXAM", generatedBy: "AI_PREMIUM" }
    });

    const savedQuiz = await dbQuiz.save();
    if (req.file && fs.existsSync(req.file.path)) fs.unlinkSync(req.file.path);

    return res.status(200).json({
      success: true,
      message: "MCQ evaluation sheet generated perfectly",
      pdfUrl: `${req.protocol}://${req.get("host")}/uploads/${fileName}`,
      quiz: savedQuiz
    });

  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};