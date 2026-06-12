const path = require("path");
const fs = require("fs");
const { callAI } = require("../services/aiService");
const { generatePlanPDF } = require("../utils/planPdfGenerator");

exports.createAIPlan = async (req, res) => {
  try {
    let {
      topic,
      level = "university",
      focus = "theory + practical",
      include = [],
      exclude = [],
      style = "structured syllabus"
    } = req.body;

    if (!topic) {
      return res.status(400).json({ message: "Topic is required" });
    }

    // 🧠 CLEAN INPUT
    if (typeof include === "string") include = [include];
    if (typeof exclude === "string") exclude = [exclude];

    // 🧠 PROMPT
    const prompt = `
You are an expert university curriculum designer and strict JSON generator.

Generate EXACTLY 18 weeks.

Return ONLY JSON in this format:

{
  "title": "",
  "description": "",
  "weeks": [
    {
      "week": 1,
      "title": "",
      "topics": [],
      "objectives": "",
      "tasks": []
    }
  ]
}

Topic: ${topic}
Level: ${level}
Focus: ${focus}
Style: ${style}
Include: ${include.join(", ") || "standard"}
Exclude: ${exclude.join(", ") || "none"}
`;

    // 🤖 AI CALL WITH RETRY (IMPORTANT)
    let aiData;
    for (let i = 0; i < 2; i++) {
      try {
        aiData = await callAI(prompt);
        if (aiData && Array.isArray(aiData.weeks)) break;
      } catch (err) {
        if (i === 1) throw err;
      }
    }

    // 🛑 VALIDATION
    if (!aiData || !Array.isArray(aiData.weeks)) {
      return res.status(500).json({
        message: "Invalid AI response structure"
      });
    }

    // 🔥 NORMALIZATION
    aiData.weeks = aiData.weeks.slice(0, 18).map((week, index) => ({
      week: index + 1,
      title: week?.title || `Week ${index + 1}`,
      topics: Array.isArray(week?.topics)
        ? week.topics
        : week?.topics
        ? [week.topics]
        : [],
      objectives: week?.objectives || "",
      tasks: Array.isArray(week?.tasks)
        ? week.tasks
        : week?.tasks
        ? [week.tasks]
        : []
    }));

    // 🛑 FINAL CHECK
    if (aiData.weeks.length !== 18) {
      return res.status(500).json({
        message: "AI did not generate exactly 18 weeks"
      });
    }

    // 📁 ENSURE UPLOAD DIRECTORY
    const uploadDir = path.join(__dirname, "../uploads");
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }

    // 📄 GENERATE PDF
    const fileName = `plan-${Date.now()}.pdf`;
    const filePath = path.join(uploadDir, fileName);

    await generatePlanPDF(aiData, filePath);

    // 🌐 FILE URL
    const pdfUrl = `${req.protocol}://${req.get("host")}/uploads/${fileName}`;

    // 🚀 RESPONSE
    return res.status(200).json({
      success: true,
      message: "AI 18-week plan generated successfully",
      pdfUrl,
      plan: aiData
    });

  } catch (error) {
    console.log("AI PLAN ERROR:", error);
    res.status(500).json({
      success: false,
      message: error.message || "Something went wrong"
    });
  }
};