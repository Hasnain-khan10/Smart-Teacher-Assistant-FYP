const path = require("path");
const fs = require("fs");
const { callAI } = require("../services/aiService");
const { generateCoursePDF } = require("../utils/pdfGenerator");

// 👉 CREATE COURSE VIA AI
exports.createAICourse = async (req, res) => {
  try {
    const { topic } = req.body;

    if (!topic) {
      return res.status(400).json({ message: "Topic is required" });
    }

    const prompt = `
Create a professional course on "${topic}".

Return JSON:
{
  "title": "",
  "description": "",
  "modules": [
    {
      "title": "",
      "topics": []
    }
  ]
}
`;

    const aiData = await callAI(prompt);

    if (!aiData.title || !aiData.modules) {
      return res.status(500).json({ message: "Invalid AI response" });
    }

    const fileName = `course-${Date.now()}.pdf`;
    const filePath = path.join(__dirname, `../uploads/${fileName}`);

    await generateCoursePDF(aiData, filePath);

    const pdfUrl = `${req.protocol}://${req.get("host")}/uploads/${fileName}`;

    return res.status(200).json({
      message: "Course generated successfully",
      pdfUrl,
      data: aiData,
    });
  } catch (error) {
    console.log("Create AI Course Error:", error.message);
    return res.status(500).json({ message: error.message });
  }
};