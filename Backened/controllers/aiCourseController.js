const path = require("path");
const fs = require("fs");
const { callAI } = require("../services/aiService");
const { generateCoursePDF } = require("../utils/pdfGenerator");

// 👉 CREATE COURSE VIA AI
exports.createAICourse = async (req, res) => {
  try {
    // 🔒 STRICT GUARD: Only authorized teachers
    if (!req.user || req.user.role !== "teacher") {
      return res.status(403).json({ success: false, message: "Forbidden: Only authorized teachers can generate AI courses." });
    }

    const { topic } = req.body;
    if (!topic) {
      return res.status(400).json({ success: false, message: "Topic is required" });
    }

    const prompt = `Create a professional course on "${topic}".\nReturn JSON:\n{\n  "title": "",\n  "description": "",\n  "modules": [\n    {\n      "title": "",\n      "topics": []\n    }\n  ]\n}`;
    const aiData = await callAI(prompt);

    if (!aiData.title || !aiData.modules) {
      return res.status(500).json({ success: false, message: "Invalid AI response structure" });
    }

    const fileName = `course-${Date.now()}.pdf`;
    const filePath = path.join(__dirname, `../uploads/${fileName}`);

    await generateCoursePDF(aiData, filePath);
    const pdfUrl = `${req.protocol}://${req.get("host")}/uploads/${fileName}`;

    return res.status(200).json({
      success: true,
      message: "Course generated successfully",
      pdfUrl,
      data: aiData,
    });
  } catch (error) {
    console.log("Create AI Course Error:", error.message);
    return res.status(500).json({ success: false, message: error.message });
  }
};