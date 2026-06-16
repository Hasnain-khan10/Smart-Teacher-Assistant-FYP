const path = require("path");
const fs = require("fs");
const { GoogleGenAI } = require("@google/genai");
const WeekPlan = require("../models/WeekPlan");
const { generatePlanDocument } = require("../utils/planExportGenerator");

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

function fileToGenerativePart(filePath, mimeType) {
  return { inlineData: { data: Buffer.from(fs.readFileSync(filePath)).toString("base64"), mimeType } };
}

exports.createAIPlan = async (req, res) => {
  try {
    let { courseId, teacherId, topic, teacherCustomPrompt = "", format = "PDF" } = req.body;

    if (!courseId || !teacherId) {
      return res.status(400).json({ success: false, message: "Valid relational IDs are mandatory" });
    }

    if (!topic && !req.file) {
      return res.status(400).json({ success: false, message: "Please provide either a reference book or a topic focus." });
    }

    let attachedFilePart = null;
    let isGroundingEnabled = true; // Use Google Search by default

    // AI ROUTING RULE 1 & 3: Book attached
    if (req.file) {
      isGroundingEnabled = false; // Disable Google Search to strictly focus on Book
      let mimeType = "application/pdf";
      if (req.file.originalname.toLowerCase().endsWith(".docx")) mimeType = "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
      else if (req.file.mimetype !== "application/octet-stream") mimeType = req.file.mimetype;
      attachedFilePart = fileToGenerativePart(req.file.path, mimeType);
    }

    const systemInstruction = `
You are a Lead Academic Professor & Technical Writer for Ivy League Universities.
Operational Directives:
1. Generate exactly 18 weeks of comprehensive textbook-style lecture content. DO NOT generate basic CLOs or advantages.
2. If a document is attached, extract deep knowledge strictly from it and map it into 18 logical weeks.
3. If no document is attached, use your live internet tools to gather the most authentic, modern computer science and academic facts.
4. Output STRICTLY as a valid JSON block without markdown formatting or introductory text.
`;

    const promptInstructions = `
Design an 18-Week deep-lecture curriculum.
Course/Topic: ${topic || "Uploaded Book Topics"}
Special Instructions: ${teacherCustomPrompt || "None"}

Format Requirement - Return a single JSON object structured EXACTLY like this:
{
  "title": "Comprehensive 18-Week Lecture Series: ${topic}",
  "description": "An intensive blueprint constructed for top-tier university standards.",
  "weeks": [
    {
      "weekNumber": 1,
      "title": "Topic Name",
      "definition": "A strong, comprehensive 3-4 sentence definition.",
      "detailedExplanation": "A deep 2-3 paragraph professional explanation of the concepts.",
      "subTopics": ["Subtopic 1", "Subtopic 2"],
      "typesOrClassifications": ["Type A", "Type B"],
      "codeOrQuerySnippet": "Valid Syntax Code Snippet or SQL Query demonstrating the concept (Leave empty if not a technical subject)",
      "realWorldAnalogy": "Explain this to a beginner using a real-world example."
    }
  ]
}
Generate exactly 18 objects inside the weeks array.
`;

    let contentsPayload = [];
    if (attachedFilePart) contentsPayload.push(attachedFilePart);
    contentsPayload.push(promptInstructions);

    const response = await ai.models.generateContent({
      model: "gemini-3.5-flash",
      contents: contentsPayload,
      config: {
        systemInstruction: systemInstruction,
        responseMimeType: "application/json",
        temperature: 0.3,
        tools: isGroundingEnabled ? [{ googleSearch: {} }] : [] // 🔥 Live Internet Search Active!
      }
    });

    let aiData;
    try {
      aiData = JSON.parse(response.text.trim());
    } catch (parseErr) {
      return res.status(500).json({ success: false, message: "AI response decoding crashed" });
    }

    if (!aiData.weeks || aiData.weeks.length !== 18) {
      return res.status(500).json({ success: false, message: `Expected 18 weeks, received ${aiData.weeks?.length || 0}` });
    }

    // Generate Requested File Format
    const uploadDir = path.join(__dirname, "../uploads");
    if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

    const fileExtension = format.toLowerCase();
    const docFileName = `lecture-plan-${Date.now()}.${fileExtension}`;
    const docFilePath = path.join(uploadDir, docFileName);

    // Call the universal exporter
    await generatePlanDocument(aiData, format, docFilePath);
    const documentUrl = `${req.protocol}://${req.get("host")}/uploads/${docFileName}`;

    const newWeekPlan = new WeekPlan({
      course: courseId, teacher: teacherId,
      title: aiData.title, description: aiData.description,
      prompt: teacherCustomPrompt, outputFormat: format,
      generationSource: req.file ? "book" : "prompt",
      weeks: aiData.weeks, documentUrl: documentUrl
    });

    const savedPlan = await newWeekPlan.save();

    if (req.file && fs.existsSync(req.file.path)) fs.unlinkSync(req.file.path);

    return res.status(200).json({
      success: true, message: `18-week plan generated perfectly in ${format} format.`,
      documentUrl, plan: savedPlan
    });

  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};