const path = require("path");
const fs = require("fs");
const WeekPlan = require("../models/WeekPlan");
const Course = require("../models/Course");
const { generatePlanDocument } = require("../utils/planExportGenerator");
const { callAI } = require("../services/aiService"); // 🔥 Groq Service Import
const pdfParse = require("pdf-parse");

exports.createAIPlan = async (req, res) => {
  try {
    let { courseId, teacherId, topic, teacherCustomPrompt = "", format = "PDF" } = req.body;

    const finalCourseId = (courseId && courseId !== "UNKNOWN") ? courseId : null;
    let finalTopic = topic || teacherCustomPrompt || "General Course Plan";

    if (finalTopic.trim() === "") {
        finalTopic = req.file ? "Plan based on attached file" : "General Syllabus";
    }

    let finalTeacherId = "6a2b27ef72643f1a4b2e7b2f";
    if (req.user && req.user._id) {
       finalTeacherId = req.user._id;
    } else if (finalCourseId) {
       const courseRecord = await Course.findById(finalCourseId);
       if (courseRecord && courseRecord.teacher) finalTeacherId = courseRecord.teacher;
    }

    let extractedText = "";

    // 🔥 HIGH LIMIT PDF EXTRACTION (Up to 25,000 characters for Groq)
    if (req.file && req.file.mimetype === "application/pdf") {
      try {
          const dataBuffer = fs.readFileSync(req.file.path);
          const pdfData = await pdfParse(dataBuffer);
          extractedText = pdfData.text ? pdfData.text.substring(0, 25000) : "";
      } catch(e) {
          console.log("PDF parse warning:", e.message);
      }
    }

    // 🔥 HIGH DETAIL SYSTEM INSTRUCTION
    const groqPrompt = `You are a Lead Academic Professor at a top-tier University.
Design a highly detailed, comprehensive 18-Week curriculum.
Course/Topic: ${finalTopic}
Special Instructions: ${teacherCustomPrompt}
${extractedText ? `Reference Context:\n${extractedText}\n\n` : ''}

STRICT RULES:
1. Generate EXACTLY 18 weeks.
2. Output MUST be strictly valid raw JSON.
3. Provide IN-DEPTH and DETAILED academic definitions and explanations (no short sentences).

Return a single JSON object structured EXACTLY like this:
{
  "title": "Comprehensive 18-Week Plan: ${finalTopic}",
  "description": "In-depth university-level curriculum.",
  "weeks": [
    {
      "weekNumber": 1,
      "title": "Topic Name",
      "definition": "Detailed 3-4 sentence comprehensive definition.",
      "detailedExplanation": "Deep academic explanation covering core concepts.",
      "subTopics": ["Detailed Subtopic 1", "Detailed Subtopic 2", "Detailed Subtopic 3"],
      "typesOrClassifications": ["Category A", "Category B", "Category C"],
      "codeOrQuerySnippet": "Provide a meaningful code snippet, formula, or core principle.",
      "realWorldAnalogy": "A strong, detailed real-world industry analogy."
    }
  ]
}`;

    console.log("📅 Generating High-Detail Course Planner via Groq...");

    // 🔥 CALL GROQ AI
const aiData = await callAI({ prompt: groqPrompt, model: "llama-3.1-70b-versatile" });
    if (!aiData.weeks || !Array.isArray(aiData.weeks)) {
      return res.status(500).json({ success: false, message: "AI generated an invalid payload." });
    }

    // 🔥 FORCE EXACT 18 WEEKS & HANDLE MISSING DATA
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
      description: aiData.description || "AI Generated Detailed Plan",
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
      message: "18-week comprehensive plan generated perfectly.",
      documentUrl,
      plan: savedPlan
    });

  } catch (error) {
    console.error("AI Plan Error:", error.message);
    return res.status(500).json({ success: false, message: error.message });
  }
};