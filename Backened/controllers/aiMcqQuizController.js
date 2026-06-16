const path = require("path");
const fs = require("fs");
const { GoogleGenAI } = require("@google/genai");
const Quiz = require("../models/Quiz");
const Course = require("../models/Course");
const { generateQuizPDF } = require("../utils/quizPdfGenerator");
const pdfParse = require("pdf-parse");

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

function fileToGenerativePart(filePath, mimeType) {
  return { inlineData: { data: Buffer.from(fs.readFileSync(filePath)).toString("base64"), mimeType } };
}

exports.createAIMCQQuiz = async (req, res) => {
  try {
    let { courseId, topic, prompt, courseTitle, difficulty = "medium", questionCount, marksPerQuestion } = req.body;

    const finalCourseId = (courseId && courseId !== "UNKNOWN") ? courseId : null;
    let finalTopic = topic || prompt || courseTitle || "General Evaluation";

    if (finalTopic.trim() === "") {
        finalTopic = req.file ? "Evaluation strictly based on attached file" : "General Course Evaluation";
    }

    let finalTeacherId = "6a2b27ef72643f1a4b2e7b2f";
    if (req.user && req.user._id) {
       finalTeacherId = req.user._id;
    } else if (finalCourseId) {
       const courseRecord = await Course.findById(finalCourseId);
       if (courseRecord && courseRecord.teacher) finalTeacherId = courseRecord.teacher;
    }

    const count = Number(questionCount) || 10;
    const perMark = Number(marksPerQuestion) || 1;

    let extractedText = "";
    let attachedFilePart = null;

    if (req.file) {
      if (req.file.mimetype === "application/pdf") {
        try {
            const dataBuffer = fs.readFileSync(req.file.path);
            const pdfData = await pdfParse(dataBuffer);
            extractedText = pdfData.text ? pdfData.text.substring(0, 7000) : "";
        } catch(e) {
            console.log("PDF parse warning:", e.message);
        }
      } else if (req.file.mimetype.startsWith("image/")) {
        attachedFilePart = fileToGenerativePart(req.file.path, req.file.mimetype);
      }
    }

    const systemInstruction = `You are a Lead Examination Board Setter.
STRICT RULE 1: Output MUST be strictly valid raw JSON matching the schema precisely.
STRICT RULE 2: No markdown formatting, no code block backticks.
STRICT RULE 3: Explanations must be a single brief sentence maximum.`;

    const userPromptText = `Subject Focus Tier: ${finalTopic}\nDifficulty Matrix: ${difficulty}\nTotal MCQs Required: ${count}\n${extractedText ? `Reference Context Data:\n${extractedText}\n\n` : ''}\nReturn a single clean parseable JSON object matching exactly this layout:\n{ "title": "Analytical MCQ Assessment", "description": "High-level cognitive evaluation paper.", "questions": [ { "question": "Scenario or analytical question?", "options": { "A": "Option A", "B": "Option B", "C": "Option C", "D": "Option D" }, "correctAnswer": "A", "explanation": "Brief rationale." } ] }`;

    let contentsPayload = [];
    if (attachedFilePart) contentsPayload.push(attachedFilePart);
    contentsPayload.push(userPromptText);

    const response = await ai.models.generateContent({
      model: "gemini-3.5-flash",
      contents: contentsPayload,
      config: {
        systemInstruction: systemInstruction,
        responseMimeType: "application/json",
        temperature: 0.2,
        tools: []
      }
    });

    let aiData;
    try {
      let cleanResponse = response.text || "";
      // 🔥 FIX: Backticks use karne ki bajaye hum direct { } brackets dhoondh rahe hain (100% Safe)
      const startIndex = cleanResponse.indexOf("{");
      const endIndex = cleanResponse.lastIndexOf("}");
      if (startIndex !== -1 && endIndex !== -1) {
         cleanResponse = cleanResponse.substring(startIndex, endIndex + 1);
      }
      aiData = JSON.parse(cleanResponse);
    } catch (err) {
      return res.status(500).json({ success: false, message: "AI response processing crashed. Try smaller input." });
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
      course: finalCourseId,
      teacher: finalTeacherId,
      title: aiData.title || `${finalTopic} Assessment`,
      description: aiData.description || "Premium AI Workspace Grid",
      type: "mcq",
      questions: formattedQuestions,
      totalMarks: formattedQuestions.length * perMark,
      marksPerQuestion: perMark,
      examMeta: { type: "MCQ_EXAM", generatedBy: "AI_PREMIUM" }
    });

    await dbQuiz.save();
    if (req.file && fs.existsSync(req.file.path)) fs.unlinkSync(req.file.path);

    return res.status(200).json({
      success: true,
      message: "MCQ generated perfectly",
      pdfUrl: `${req.protocol}://${req.get("host")}/uploads/${fileName}`,
      quiz: dbQuiz
    });

  } catch (error) {
    console.error("AI Generation Error:", error.message);
    let msg = error.message.includes("429") ? "API Quota exceeded! Please check your Google account limits." : error.message;
    return res.status(500).json({ success: false, message: msg });
  }
};