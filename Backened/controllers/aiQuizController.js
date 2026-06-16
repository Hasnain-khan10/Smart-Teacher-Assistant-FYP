const path = require("path");
const fs = require("fs");
const { GoogleGenAI } = require("@google/genai");
const Quiz = require("../models/Quiz");
const { generateQuizPDF } = require("../utils/quizPdfGenerator");

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

function fileToGenerativePart(filePath, mimeType) {
  return { inlineData: { data: Buffer.from(fs.readFileSync(filePath)).toString("base64"), mimeType } };
}

exports.createAIQuestionQuiz = async (req, res) => {
  try {
    // 🔥 DYNAMIC KEY MAPPING
    let { courseId, course, teacherId, teacher, topic, prompt, courseTitle, difficulty = "medium", shortCount = 0, longCount = 0, shortEachMark = 2, longEachMark = 5, type = "long" } = req.body;

    const finalCourseId = courseId || course;
    const finalTeacherId = teacherId || teacher || "6a2b27ef72643f1a4b2e7b2f";
    let finalTopic = topic || prompt || courseTitle || "";

    if (!finalCourseId) {
      return res.status(400).json({ success: false, message: "Validation Failed: courseId/course mapping key is mandatory." });
    }

    if (finalTopic.trim() === "" && !req.file) {
      return res.status(400).json({ success: false, message: "Validation Failed: Please provide a Topic/Prompt OR upload a Reference Book." });
    }

    if (finalTopic.trim() === "" && req.file) {
      finalTopic = "Comprehensive written assessment map from attached files.";
    }

    const sCount = Number(shortCount) || 0;
    const lCount = Number(longCount) || 0;
    const sEach = Number(shortEachMark) || 2;
    const lEach = Number(longEachMark) || 5;

    let attachedFilePart = null;
    let isGroundingEnabled = true;

    if (req.file) {
      isGroundingEnabled = false;
      let mimeType = "application/pdf";
      if (req.file.originalname.toLowerCase().endsWith(".docx")) mimeType = "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
      else if (req.file.mimetype !== "application/octet-stream") mimeType = req.file.mimetype;
      attachedFilePart = fileToGenerativePart(req.file.path, mimeType);
    }

    const systemInstruction = `
You are a Senior Academic Assessor for premier technical institutions. Set formal descriptive examination papers.
1. Generate analytical, problem-solving, and architectural thinking questions.
2. Provide an 'idealAnswer' (solution blueprint) and a comprehensive 'rubric' for the teacher's grading matrix.
3. Respond strictly inside a valid JSON object structure.
`;

    let formatRequirementText = "";
    if (type === "short") {
      formatRequirementText = `Generate exactly ${sCount} short questions. Layout:
      { "title": "Short Answer Assessment", "description": "...", "shortQuestions": [{ "question": "...", "marks": ${sEach}, "idealAnswer": "...", "rubric": "..." }] }`;
    } else if (type === "long") {
      formatRequirementText = `Generate exactly ${lCount} long detailed analytical questions. Layout:
      { "title": "Long Essay Examination", "description": "...", "longQuestions": [{ "question": "...", "marks": ${lEach}, "idealAnswer": "...", "rubric": "..." }] }`;
    } else {
      formatRequirementText = `Generate ${sCount} short and ${lCount} long questions. Layout:
      { "title": "Mixed Written Paper", "description": "...", "shortQuestions": [{ "question": "...", "marks": ${sEach}, "idealAnswer": "...", "rubric": "..." }], "longQuestions": [{ "question": "...", "marks": ${lEach}, "idealAnswer": "...", "rubric": "..." }] }`;
    }

    const userPromptText = `
Construct a professional written descriptive examination:
Subject Focus Area: ${finalTopic}
Difficulty Tier: ${difficulty}
${formatRequirementText}
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
    } catch (parseErr) {
      return res.status(500).json({ success: false, message: "AI response structural parsing crashed." });
    }

    const dbShortArray = (aiData.shortQuestions || []).map(q => ({ question: q.question, marks: sEach, idealAnswer: q.idealAnswer || "Descriptive solution criteria.", rubric: q.rubric || "Award points based on accuracy." }));
    const dbLongArray = (aiData.longQuestions || []).map(q => ({ question: q.question, marks: lEach, idealAnswer: q.idealAnswer || "Descriptive solution criteria.", rubric: q.rubric || "Award points based on accuracy." }));
    const totalMarks = (sCount * sEach) + (lCount * lEach);

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
      description: aiData.description || "Descriptive Written Assessment Blueprints",
      type: type === "both" ? "mixed" : "question",
      shortQuestions: dbShortArray,
      longQuestions: dbLongArray,
      totalMarks: totalMarks,
      isAIScanned: false
    });

    const finalCatalogedData = await savedQuizModel.save();
    if (req.file && fs.existsSync(req.file.path)) fs.unlinkSync(req.file.path);

    return res.status(200).json({
      success: true,
      message: "Written assessment blueprint indexed perfectly",
      pdfUrl: `${req.protocol}://${req.get("host")}/uploads/${fileName}`,
      quiz: finalCatalogedData
    });

  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};