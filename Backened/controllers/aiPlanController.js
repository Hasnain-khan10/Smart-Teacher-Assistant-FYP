const path = require("path");
const fs = require("fs");
const WeekPlan = require("../models/WeekPlan");
const Course = require("../models/Course");
const User = require("../models/User");
const { generatePlanDocument } = require("../utils/planExportGenerator");
const { callAI } = require("../services/aiService");
const pdfParse = require("pdf-parse");
const NotificationService = require("../services/notificationService");

exports.createAIPlan = async (req, res) => {
  try {
    // 🔒 STRICT GUARD
    if (!req.user || req.user.role !== "teacher") {
      return res.status(403).json({ success: false, message: "Forbidden: Only authorized teachers can build curriculums." });
    }

    let { courseId, teacherId, topic, teacherCustomPrompt = "", format = "PDF" } = req.body;
    const finalCourseId = (courseId && courseId !== "UNKNOWN") ? courseId : null;
    let finalTopic = topic || teacherCustomPrompt || "General Course Plan";

    if (finalTopic.trim() === "") {
        finalTopic = req.file ? "Plan based on attached file" : "General Syllabus";
    }

    const finalTeacherId = req.user._id;
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

    const groqPrompt = `You are a Lead Academic Professor at a top-tier University.
Design a highly detailed, comprehensive 18-Week curriculum.
Course/Topic: ${finalTopic}\nSpecial Instructions: ${teacherCustomPrompt}
${extractedText ? `Reference Context:\n${extractedText}\n\n` : ''}
STRICT RULES:
1. Generate EXACTLY 18 weeks.
2. Output MUST be strictly valid raw JSON.
3. Provide IN-DEPTH and DETAILED academic definitions and explanations.
Return JSON format exactly like:
{ "title": "...", "description": "...", "weeks": [ { "weekNumber": 1, "title": "...", "definition": "...", "detailedExplanation": "...", "subTopics": ["..."], "typesOrClassifications": ["..."], "codeOrQuerySnippet": "...", "realWorldAnalogy": "..." } ] }`;

    const aiData = await callAI({ prompt: groqPrompt, model: "llama-3.1-70b-versatile" });
    if (!aiData.weeks || !Array.isArray(aiData.weeks)) {
      return res.status(500).json({ success: false, message: "AI generated an invalid payload." });
    }

    let formattedWeeks = aiData.weeks.slice(0, 18).map((w, i) => ({
      weekNumber: i + 1, title: w.title || `Week ${i + 1}`,
      definition: w.definition || "Definition pending.", detailedExplanation: w.detailedExplanation || "Explanation pending.",
      subTopics: Array.isArray(w.subTopics) ? w.subTopics : [], typesOrClassifications: Array.isArray(w.typesOrClassifications) ? w.typesOrClassifications : [],
      codeOrQuerySnippet: w.codeOrQuerySnippet || "", realWorldAnalogy: w.realWorldAnalogy || ""
    }));

    while (formattedWeeks.length < 18) {
       formattedWeeks.push({
         weekNumber: formattedWeeks.length + 1, title: `Week ${formattedWeeks.length + 1}`,
         definition: "Pending", detailedExplanation: "Pending", subTopics: [], typesOrClassifications: [], codeOrQuerySnippet: "", realWorldAnalogy: ""
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
      course: finalCourseId, teacher: finalTeacherId,
      title: aiData.title || "18-Week Curriculum", description: aiData.description || "AI Generated Detailed Plan",
      prompt: teacherCustomPrompt, outputFormat: format || "PDF", generationSource: req.file ? "book" : "prompt",
      weeks: formattedWeeks, documentUrl: documentUrl
    });

    const savedPlan = await newWeekPlan.save();
    if (req.file && fs.existsSync(req.file.path)) fs.unlinkSync(req.file.path);

    try {
      if (finalCourseId && finalCourseId !== "UNKNOWN") {
        const courseData = await Course.findById(finalCourseId).lean();
        if (courseData && courseData.students && courseData.students.length > 0) {
          const studentIds = courseData.students.map(s => s.user.toString());
          const users = await User.find({ _id: { $in: studentIds } }).select("fcmToken").lean();

          for (const user of users) {
            if (user.fcmToken && user.fcmToken.trim() !== "") {
              await NotificationService.sendPushNotification(
                user.fcmToken, "New AI Curriculum Published 📚",
                `A highly detailed AI-generated 18-week curriculum has been added to course ${courseData.title || ''}.`,
                { courseId: finalCourseId.toString(), type: "plan" }
              );
            }
          }
        }
      }
    } catch (notifyErr) { console.log("AI Plan notification failed:", notifyErr.message); }

    return res.status(200).json({ success: true, message: "18-week comprehensive plan generated perfectly.", documentUrl, plan: savedPlan });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};