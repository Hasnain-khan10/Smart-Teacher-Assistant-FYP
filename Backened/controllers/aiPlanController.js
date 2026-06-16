const path = require("path");
const fs = require("fs");
const { GoogleGenAI } = require("@google/genai");
const WeekPlan = require("../models/WeekPlan");
const Course = require("../models/Course");
const { generatePlanDocument } = require("../utils/planExportGenerator");
const pdfParse = require("pdf-parse");

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

function fileToGenerativePart(filePath, mimeType) {
  return { inlineData: { data: Buffer.from(fs.readFileSync(filePath)).toString("base64"), mimeType } };
}

exports.createAIPlan = async (req, res) => {
  try {
    let { courseId, teacherId, topic, teacherCustomPrompt = "", format = "PDF" } = req.body;

    const finalCourseId = (courseId && courseId !== "UNKNOWN") ? courseId : null;
    let finalTopic = topic || teacherCustomPrompt || "General Course Plan";

    if (finalTopic.trim() === "") {
        finalTopic = req.file ? "Plan based on attached file" : "General Syllabus";
    }

    // 🔥 FIX: Safe Teacher ID Extraction (Saves plan directly to your account)
    let finalTeacherId = "6a2b27ef72643f1a4b2e7b2f";
    if (req.user && req.user._id) {
       finalTeacherId = req.user._id;
    } else if (finalCourseId) {
       const courseRecord = await Course.findById(finalCourseId);
       if (courseRecord && courseRecord.teacher) finalTeacherId = courseRecord.teacher;
    }

    let extractedText = "";
    let attachedFilePart = null;

    // 🔥 PREVENT 429/503: Keep Text Size Small
    if (req.file) {
      if (req.file.mimetype === "application/pdf") {
        try {
            const dataBuffer = fs.readFileSync(req.file.path);
            const pdfData = await pdfParse(dataBuffer);
            extractedText = pdfData.text ? pdfData.text.substring(0, 6000) : ""; // Safe Token limit
        } catch(e) {
            console.log("PDF parse warning:", e.message);
        }
      } else if (req.file.mimetype.startsWith("image/")) {
        attachedFilePart = fileToGenerativePart(req.file.path, req.file.mimetype);
      }
    }

    const systemInstruction = `You are a Lead Academic Professor.
STRICT RULE 1: Generate EXACTLY 18 weeks.
STRICT RULE 2: Output MUST be strictly valid raw JSON. No markdown backticks.
STRICT RULE 3: Keep definitions, explanations, and analogies extremely brief (1-2 sentences maximum) to avoid token limit crashes.`;

    const promptInstructions = `Design an 18-Week highly concise curriculum.
Course/Topic: ${finalTopic}
Special Instructions: ${teacherCustomPrompt}
${extractedText ? `Reference Context:\n${extractedText}\n\n` : ''}
Return a single JSON object structured EXACTLY like this:
{
  "title": "18-Week Plan: ${finalTopic}",
  "description": "Concise weekly blueprint.",
  "weeks": [
    {
      "weekNumber": 1,
      "title": "Topic Name",
      "definition": "Brief 1-sentence definition.",
      "detailedExplanation": "Brief 2-sentence explanation.",
      "subTopics": ["Subtopic 1", "Subtopic 2"],
      "typesOrClassifications": ["Type A", "Type B"],
      "codeOrQuerySnippet": "1 line code or empty",
      "realWorldAnalogy": "Brief 1-sentence analogy."
    }
  ]
}`;

    let contentsPayload = [];
    if (attachedFilePart) contentsPayload.push(attachedFilePart);
    contentsPayload.push(promptInstructions);

    const response = await ai.models.generateContent({
      model: "gemini-3.5-flash",
      contents: contentsPayload,
      config: {
        systemInstruction: systemInstruction,
        responseMimeType: "application/json",
        temperature: 0.2,
        tools: [] // 🔥 DISABLE Google Search to prevent API quota exhaust
      }
    });

    let aiData;
    try {
      let cleanResponse = response.text || "";
      // 🔥 SMART BRACKET EXTRACTION: Copy-paste syntax errors se bachne ka 100% safe tarika
      const startIndex = cleanResponse.indexOf("{");
      const endIndex = cleanResponse.lastIndexOf("}");
      if (startIndex !== -1 && endIndex !== -1) {
         cleanResponse = cleanResponse.substring(startIndex, endIndex + 1);
      }
      aiData = JSON.parse(cleanResponse);
    } catch (parseErr) {
      return res.status(500).json({ success: false, message: "AI response failed to parse. Try making the prompt smaller." });
    }

    if (!aiData.weeks || !Array.isArray(aiData.weeks)) {
      return res.status(500).json({ success: false, message: "AI generated an invalid payload." });
    }

    // 🔥 FORCE EXACT 18 WEEKS (Protects from incomplete plans)
    let formattedWeeks = aiData.weeks.slice(0, 18).map((w, i) => ({
      weekNumber: i + 1,
      title: w.title || `Week ${i + 1}`,
      definition: w.definition || "Definition pending.",
      detailedExplanation: w.detailedExplanation || "Explanation pending.",
      subTopics: Array.isArray(w.subTopics) ? w.subTopics : [],
      typesOrClassifications: Array.isArray(w.typesOrClassifications) ? w.typesOrClassifications : [],
      codeOrQuerySnippet: w.codeOrQuerySnippet || "",
      realWorldAnalogy: w.realWorldAnalogy || ""
    }));

    while (formattedWeeks.length < 18) {
       formattedWeeks.push({
         weekNumber: formattedWeeks.length + 1,
         title: `Week ${formattedWeeks.length + 1}`,
         definition: "Pending", detailedExplanation: "Pending",
         subTopics: [], typesOrClassifications: [], codeOrQuerySnippet: "", realWorldAnalogy: ""
       });
    }

    const uploadDir = path.join(__dirname, "../uploads");
    if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

    const fileExtension = (format || "PDF").toLowerCase();
    const docFileName = `lecture-plan-${Date.now()}.${fileExtension}`;
    const docFilePath = path.join(uploadDir, docFileName);

    await generatePlanDocument(aiData, format, docFilePath);
    const documentUrl = `${req.protocol}://${req.get("host")}/uploads/${docFileName}`;

    const newWeekPlan = new WeekPlan({
      course: finalCourseId,
      teacher: finalTeacherId,
      title: aiData.title || "18-Week Curriculum",
      description: aiData.description || "AI Generated Short Plan",
      prompt: teacherCustomPrompt,
      outputFormat: format || "PDF",
      generationSource: req.file ? "book" : "prompt",
      weeks: formattedWeeks,
      documentUrl: documentUrl
    });

    const savedPlan = await newWeekPlan.save();
    if (req.file && fs.existsSync(req.file.path)) fs.unlinkSync(req.file.path);

    return res.status(200).json({
      success: true,
      message: "18-week plan generated perfectly.",
      documentUrl,
      plan: savedPlan
    });

  } catch (error) {
    console.error("AI Plan Error:", error.message);
    let msg = error.message.includes("429") ? "API Quota exceeded! Please check your limits." : error.message;
    return res.status(500).json({ success: false, message: msg });
  }
};