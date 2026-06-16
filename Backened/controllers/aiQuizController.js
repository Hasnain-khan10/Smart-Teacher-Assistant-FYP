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

exports.createAIQuestionQuiz = async (req, res) => {
  try {
    let { courseId, topic, prompt, courseTitle, difficulty = "medium", shortCount = 0, longCount = 0, shortEachMark = 2, longEachMark = 5, type = "long" } = req.body;

    const finalCourseId = (courseId && courseId !== "UNKNOWN") ? courseId : null;
    let finalTopic = topic || prompt || courseTitle || "";

    if (finalTopic.trim() === "") {
        finalTopic = req.file ? "Analytical assessment of attached file." : "General Subjective Assessment";
    }

    let finalTeacherId = "6a2b27ef72643f1a4b2e7b2f";
    if (req.user && req.user._id) {
       finalTeacherId = req.user._id;
    } else if (finalCourseId) {
       const courseRecord = await Course.findById(finalCourseId);
       if (courseRecord && courseRecord.teacher) finalTeacherId = courseRecord.teacher;
    }

    const sCount = Number(shortCount) || 0;
    const lCount = Number(longCount) || 0;
    const sEach = Number(shortEachMark) || 2;
    const lEach = Number(longEachMark) || 5;

    let extractedText = "";
    let attachedFilePart = null;

    if (req.file) {
      if (req.file.mimetype === "application/pdf") {
        try {
            const dataBuffer = fs.readFileSync(req.file.path);
            const pdfData = await pdfParse(dataBuffer);
            extractedText = pdfData.text ? pdfData.text.substring(0, 7000) : "";
        } catch(e) {}
      } else if (req.file.mimetype.startsWith("image/")) {
        attachedFilePart = fileToGenerativePart(req.file.path, req.file.mimetype);
      }
    }

    const systemInstruction = `You are a Senior Academic Assessor. Generate descriptive exam questions.\nSTRICT RULE 1: Respond with clean raw JSON only. Do not wrap code blocks in markdown formatting.\nSTRICT RULE 2: Keep 'idealAnswer' and 'rubric' strictly to 1-2 short sentences to avoid crashes.`;

    let formatRequirementText = "";
    if (type === "short") {
      formatRequirementText = `Generate EXACTLY ${sCount} short questions. \nJSON Format Layout:\n{ "title": "Short Paper", "description": "...", "shortQuestions": [{ "question": "...", "marks": ${sEach}, "idealAnswer": "solution context", "rubric": "points blueprint" }] }`;
    } else if (type === "long") {
      formatRequirementText = `Generate EXACTLY ${lCount} long questions. \nJSON Format Layout:\n{ "title": "Long Paper", "description": "...", "longQuestions": [{ "question": "...", "marks": ${lEach}, "idealAnswer": "solution blueprint", "rubric": "grading framework" }] }`;
    } else {
      formatRequirementText = `Generate ${sCount} short and ${lCount} long questions. \nJSON Format Layout:\n{ "title": "Mixed Paper", "description": "...", "shortQuestions": [{ "question": "...", "marks": ${sEach}, "idealAnswer": "...", "rubric": "..." }], "longQuestions": [{ "question": "...", "marks": ${lEach}, "idealAnswer": "...", "rubric": "..." }] }`;
    }

    const userPromptText = `Subject Focus Area: ${finalTopic}\nDifficulty Tier: ${difficulty}\n${extractedText ? `Reference Text Context:\n${extractedText}\n\n` : ''}\n${formatRequirementText}`;

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
        // 🔥 FIX: Safe Bracket Extraction (No syntax errors during copy-paste)
        const startIndex = cleanResponse.indexOf("{");
        const endIndex = cleanResponse.lastIndexOf("}");
        if (startIndex !== -1 && endIndex !== -1) {
           cleanResponse = cleanResponse.substring(startIndex, endIndex + 1);
        }
        aiData = JSON.parse(cleanResponse);
    } catch (parseErr) {
      return res.status(500).json({ success: false, message: "AI response failed to parse. Try with fewer questions." });
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
      description: aiData.description || "Descriptive Assessment",
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
      message: "Quiz generated perfectly",
      pdfUrl: `${req.protocol}://${req.get("host")}/uploads/${fileName}`,
      quiz: savedQuizModel
    });

  } catch (error) {
    console.error("AI Generation Error:", error.message);
    let msg = error.message.includes("429") ? "API Quota exceeded! Please check your Google account limits." : error.message;
    return res.status(500).json({ success: false, message: msg });
  }
};