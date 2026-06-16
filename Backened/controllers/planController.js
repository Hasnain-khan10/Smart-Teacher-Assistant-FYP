const WeekPlan = require("../models/WeekPlan");
const Course = require("../models/Course");
const PDFDocument = require("pdfkit");
const fs = require("fs");
const pdfParse = require("pdf-parse");
const Tesseract = require("tesseract.js");
const { callAI } = require("../services/aiService");

// ===============================
// CREATE WEEK PLAN (MANUAL)
// ===============================
exports.generatePlan = async (req, res) => {
  try {
    const { courseId, weeks, semesterDuration } = req.body;

    if (!courseId || !weeks || !Array.isArray(weeks)) {
      return res.status(400).json({ success: false, message: "courseId and weeks array are required" });
    }

    const course = await Course.findOne({ _id: courseId, teacher: req.user._id });
    if (!course) {
      return res.status(404).json({ success: false, message: "Course not found or not authorized" });
    }

    const existingPlan = await WeekPlan.findOne({ course: courseId, teacher: req.user._id });
    if (existingPlan) {
      return res.status(400).json({ success: false, message: "Week plan already exists for this course" });
    }

    const formattedWeeks = weeks.map((w) => ({
      weekNumber: w.weekNumber,
      topic: w.topic,
      clo: w.clo,
      activity: w.activity || "Lecture",
    }));

    const plan = await WeekPlan.create({
      course: courseId,
      teacher: req.user._id,
      weeks: formattedWeeks,
      semesterDuration: semesterDuration || 18,
    });

    return res.status(201).json({ success: true, message: "Week plan created successfully", plan });
  } catch (error) {
    return res.status(500).json({ success: false, error: error.message });
  }
};

// ===============================
// GET PLAN BY COURSE
// ===============================
exports.getPlanByCourse = async (req, res) => {
  try {
    const { courseId } = req.params;
    let plan;

    if (req.user.role === "teacher") {
      plan = await WeekPlan.findOne({ course: courseId, teacher: req.user._id }).populate("course", "title courseCode syllabus");
    } else {
      plan = await WeekPlan.findOne({ course: courseId }).populate("course", "title courseCode syllabus");
    }

    if (!plan) return res.status(404).json({ success: false, message: "No weekly plan found" });
    return res.json({ success: true, plan });
  } catch (error) {
    return res.status(500).json({ success: false, error: error.message });
  }
};

// ===============================
// GENERATE SINGLE WEEK PDF
// ===============================
exports.generateWeekPDF = async (req, res) => {
  try {
    const { courseId, weekNumber } = req.params;

    const course = await Course.findById(courseId).populate("teacher", "name");
    if (!course) return res.status(404).json({ message: "Course not found" });

    const plan = await WeekPlan.findOne({ course: courseId });
    if (!plan) return res.status(404).json({ message: "Week plan not found" });

    const week = plan.weeks.find((w) => w.weekNumber == weekNumber);
    if (!week) return res.status(404).json({ message: "Week not found" });

    if (req.user.role === "teacher" && course.teacher._id.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: "Access denied" });
    }

    const doc = new PDFDocument({ margin: 50 });
    res.setHeader("Content-Type", "application/pdf");
    res.setHeader("Content-Disposition", `attachment; filename=AI_Week_${week.weekNumber}_${course.title}.pdf`);
    doc.pipe(res);

    doc.fontSize(20).text("AI Generated Weekly Plan", { align: "center" });
    doc.moveDown();
    doc.fontSize(14).text(`Course: ${course.title}`);
    doc.text(`Code: ${course.courseCode || "N/A"}`);
    doc.text(`Instructor: ${course.teacher?.name || "N/A"}`);
    doc.text(`Semester: ${plan.semesterDuration} Weeks`);
    doc.moveDown(2);

    doc.fontSize(16).text(`Week ${week.weekNumber}: ${week.title}`, { underline: true });
    doc.moveDown();
    doc.fontSize(12);

    if (week.topics?.length) {
      doc.text("Topics & Sub-topics:");
      week.topics.forEach((t) => doc.text(`• ${t}`, { indent: 20 }));
    }

    const cloList = Array.isArray(week.clo) ? week.clo : week.clo ? [week.clo] : [];
    doc.moveDown(0.5);
    doc.text("CLO:");
    if (cloList.length > 0) {
      cloList.forEach((c) => doc.text(`• ${c}`, { indent: 20 }));
    } else {
      doc.text("• Not defined", { indent: 20 });
    }

    if (week.objectives?.length) {
      doc.moveDown(0.5);
      doc.text("Objectives:");
      week.objectives.forEach((o) => doc.text(`• ${o}`, { indent: 20 }));
    }

    if (week.tasks?.length) {
      doc.moveDown(0.5);
      doc.text("Tasks & Practical Application:");
      week.tasks.forEach((t) => doc.text(`• ${t}`, { indent: 20 }));
    }

    if (week.advantages) { doc.moveDown(0.5); doc.text("Advantages:"); doc.text(week.advantages); }
    if (week.disadvantages) { doc.moveDown(0.5); doc.text("Disadvantages:"); doc.text(week.disadvantages); }

    doc.moveDown(2);
    doc.fontSize(10).fillColor("gray").text("Generated by AI Academic System", { align: "center" });
    doc.end();
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

// ===============================
// UPDATE PLAN (FULL CONTROL)
// ===============================
exports.updatePlan = async (req, res) => {
  try {
    const plan = await WeekPlan.findOne({ _id: req.params.id, teacher: req.user._id });
    if (!plan) return res.status(404).json({ success: false, message: "Plan not found" });

    if (req.body.weeks) plan.weeks = req.body.weeks;
    await plan.save();
    return res.json({ success: true, message: "Plan updated successfully", plan });
  } catch (error) {
    return res.status(500).json({ success: false, error: error.message });
  }
};

// ===============================
// DELETE PLAN
// ===============================
exports.deletePlan = async (req, res) => {
  try {
    const plan = await WeekPlan.findOne({ _id: req.params.id, teacher: req.user._id });
    if (!plan) return res.status(404).json({ success: false, message: "Plan not found" });
    await plan.deleteOne();
    return res.json({ success: true, message: "Plan deleted successfully" });
  } catch (error) {
    return res.status(500).json({ success: false, error: error.message });
  }
};

// ===============================
// UPDATE WEEK VIA AI (CONCISE PROMPT)
// ===============================
exports.updateWeekAI = async (req, res) => {
  try {
    const { courseId, weekNumber, prompt } = req.body;
    if (!courseId || !weekNumber) return res.status(400).json({ success: false, message: "courseId and weekNumber required" });

    const plan = await WeekPlan.findOne({ course: courseId, teacher: req.user._id });
    if (!plan) return res.status(404).json({ success: false, message: "Week plan not found" });

    const weekIndex = plan.weeks.findIndex((w) => w.weekNumber == weekNumber);
    if (weekIndex === -1) return res.status(404).json({ success: false, message: "Week not found" });

    const currentWeek = plan.weeks[weekIndex];

    const aiPrompt = `
You are an academic AI. Update ONLY this single university week.
CRITICAL: Keep your response CONCISE. If providing code, keep it to 1-2 lines.

CURRENT WEEK:
${JSON.stringify(currentWeek)}

TEACHER REQUEST:
${prompt || "Improve clarity and depth"}

RETURN EXACTLY IN THIS JSON FORMAT:
{
  "title": "string",
  "topics": ["Main Topic", "Sub-topic 1", "Sub-topic 2"],
  "clo": ["string"],
  "objectives": ["string"],
  "tasks": ["string"],
  "advantages": "string",
  "disadvantages": "string"
}
`;

    let aiResponse = await callAI({ prompt: aiPrompt });
    if (typeof aiResponse === "string") {
      aiResponse = aiResponse.replace(/```json/g, "").replace(/```/g, "").trim();
      aiResponse = JSON.parse(aiResponse);
    }

    plan.weeks[weekIndex] = {
      ...plan.weeks[weekIndex]._doc,
      title: aiResponse.title || currentWeek.title,
      topics: Array.isArray(aiResponse.topics) ? aiResponse.topics : aiResponse.topic ? [aiResponse.topic] : currentWeek.topics,
      clo: Array.isArray(aiResponse.clo) ? aiResponse.clo : aiResponse.clo ? [aiResponse.clo] : currentWeek.clo,
      objectives: Array.isArray(aiResponse.objectives) ? aiResponse.objectives : aiResponse.objectives ? [aiResponse.objectives] : currentWeek.objectives,
      tasks: Array.isArray(aiResponse.tasks) ? aiResponse.tasks : aiResponse.tasks ? [aiResponse.tasks] : currentWeek.tasks,
      advantages: aiResponse.advantages || currentWeek.advantages,
      disadvantages: aiResponse.disadvantages || currentWeek.disadvantages,
    };

    await plan.save();
    return res.json({ success: true, message: "Week updated using AI", week: plan.weeks[weekIndex] });
  } catch (error) {
    return res.status(500).json({ success: false, error: error.message });
  }
};

// ===============================
// DELETE WEEK
// ===============================
exports.deleteWeek = async (req, res) => {
  try {
    const { courseId, weekNumber } = req.params;
    const weekNum = Number(weekNumber);
    if (!courseId || isNaN(weekNum)) return res.status(400).json({ success: false, message: "Invalid input" });

    const plan = await WeekPlan.findOne({ course: courseId, teacher: req.user._id });
    if (!plan) return res.status(404).json({ success: false, message: "Plan not found" });

    const index = plan.weeks.findIndex((w) => w.weekNumber === weekNum);
    if (index === -1) return res.status(404).json({ success: false, message: "Week not found" });

    plan.weeks.splice(index, 1);
    await plan.save();

    return res.status(200).json({ success: true, message: "Week deleted successfully", weeks: plan.weeks });
  } catch (error) {
    return res.status(500).json({ success: false, message: "Server error", error: error.message });
  }
};

// ===============================
// GENERATE AI PLAN FROM BOOK (TOKEN OPTIMIZED)
// ===============================
exports.generateAIPlanFromBook = async (req, res) => {
  try {
    const { courseId } = req.body;
    if (!courseId || !req.file) return res.status(400).json({ success: false, message: "courseId and book file required" });

    const course = await Course.findOne({ _id: courseId, teacher: req.user._id });
    if (!course) return res.status(404).json({ success: false, message: "Course not found" });

    const existingPlan = await WeekPlan.findOne({ course: courseId, teacher: req.user._id });
    if (existingPlan) return res.status(400).json({ success: false, message: "Week plan already exists" });

    const filePath = req.file.path;
    const fileType = req.file.mimetype;
    let extractedText = "";

    try {
      if (fileType.includes("pdf")) {
        const dataBuffer = fs.readFileSync(filePath);
        const pdfData = await pdfParse(dataBuffer);
        extractedText = pdfData.text || "";
      } else if (fileType.includes("image")) {
        const result = await Tesseract.recognize(filePath, "eng");
        extractedText = result.data.text || "";
      }
    } catch (err) {
      extractedText = "";
    }

    if (!extractedText || extractedText.length < 50) {
      extractedText = "Analyze academic material and generate a structured university semester plan.";
    }

    // 🔥 LIMIT INPUT TO AVOID CRASHES (1500 chars is safe for context without killing token limit)
    extractedText = extractedText.substring(0, 1500);

    // 🔥 STRICT CONCISE PROMPT TO PREVENT OUTPUT CRASH
    const finalPrompt = `
You are a STRICT UNIVERSITY CURRICULUM DESIGN AI.
COURSE: ${course.title} (${course.courseCode || "N/A"})
MATERIAL SUMMARY: ${extractedText}

TASK: Generate EXACTLY 18 WEEK UNIVERSITY PLAN.

CRITICAL INSTRUCTION TO PREVENT TIMEOUTS/CRASHES:
Provide data in VERY SHORT BULLET POINTS. Do not write paragraphs. Keep code examples to maximum 1 line. Max 2 objectives per week.

RETURN ONLY VALID JSON:
{
  "title": "string",
  "description": "string",
  "weeks": [
    {
      "title": "string",
      "topics": ["Main topic", "Sub-topic 1", "Sub-topic 2"],
      "clo": ["1 Short CLO"],
      "objectives": ["Obj 1", "Obj 2"],
      "tasks": ["Task 1", "Short code if any"],
      "advantages": "1 Short sentence",
      "disadvantages": "1 Short sentence"
    }
  ]
}
`;

    let aiResponse = await callAI({ prompt: finalPrompt });
    let aiData;

    try {
      if (typeof aiResponse === "string") {
        aiData = JSON.parse(aiResponse.replace(/```json/g, "").replace(/```/g, "").trim());
      } else {
        aiData = aiResponse;
      }
    } catch (err) {
      return res.status(500).json({ success: false, message: "AI output was too long and broke the JSON format. Try with a shorter request." });
    }

    if (!aiData?.weeks || !Array.isArray(aiData.weeks)) return res.status(500).json({ success: false, message: "Invalid weeks array from AI" });

    // FORCE EXACT 18 WEEKS
    if (aiData.weeks.length !== 18) {
      aiData.weeks = aiData.weeks.slice(0, 18);
      while (aiData.weeks.length < 18) {
        aiData.weeks.push({
            title: `Week ${aiData.weeks.length + 1}`,
            topics: ["To be completed"],
            clo: ["TBD"], objectives: ["TBD"], tasks: ["TBD"], advantages: "", disadvantages: ""
        });
      }
    }

    const formattedWeeks = aiData.weeks.map((w, i) => ({
      weekNumber: i + 1,
      title: w.title || `Week ${i + 1}`,
      topics: Array.isArray(w.topics) ? w.topics : Array.isArray(w.topic) ? w.topic : w.topic ? [w.topic] : ["Topic pending"],
      clo: Array.isArray(w.clo) && w.clo.length ? w.clo : ["Analyze core concepts"],
      objectives: Array.isArray(w.objectives) && w.objectives.length ? w.objectives : ["Understand the material"],
      tasks: Array.isArray(w.tasks) ? w.tasks : w.tasks ? [w.tasks] : [],
      advantages: w.advantages || "",
      disadvantages: w.disadvantages || "",
    }));

    const plan = await WeekPlan.create({
      course: courseId, teacher: req.user._id,
      title: aiData.title || "AI Book-Based Plan", description: aiData.description || "Generated from uploaded book",
      weeks: formattedWeeks, semesterDuration: 18,
      bookFileUrl: filePath, bookFileType: fileType.includes("image") ? "image" : "pdf", bookExtractedText: extractedText,
      generationSource: "book", prompt: "",
    });

    return res.status(201).json({ success: true, message: "AI plan generated", plan });
  } catch (error) {
    return res.status(500).json({ success: false, error: error.message });
  }
};

// ===============================
// GENERATE AI 18 WEEK PLAN (PROMPT ONLY)
// ===============================
exports.generateAIPlan = async (req, res) => {
  try {
    const { courseId, prompt: userPrompt } = req.body;
    if (!courseId) return res.status(400).json({ success: false, message: "courseId is required" });

    const course = await Course.findOne({ _id: courseId, teacher: req.user._id });
    if (!course) return res.status(404).json({ success: false, message: "Course not found" });

    const existingPlan = await WeekPlan.findOne({ course: courseId, teacher: req.user._id });
    if (existingPlan) return res.status(400).json({ success: false, message: "Week plan already exists" });

    // 🔥 STRICT CONCISE PROMPT TO PREVENT OUTPUT CRASH
    const finalPrompt = `
You are a PROFESSIONAL UNIVERSITY CURRICULUM DESIGN AI.
COURSE: ${course.title} (${course.courseCode || "N/A"})
TEACHER REQUEST: ${userPrompt || "Standard academic progression"}

TASK: Generate a STRICT 18-WEEK UNIVERSITY SEMESTER PLAN.

CRITICAL INSTRUCTION TO AVOID TOKEN LIMIT EXHAUSTION:
Keep everything EXTREMELY CONCISE. Do NOT write paragraphs. Max 2 short bullet points per array. Keep code examples to 1 line inside 'tasks'.

RULES:
- EXACTLY 18 WEEKS. Never skip a week.

RETURN ONLY VALID JSON (No markdown):
{
  "title": "string",
  "description": "string",
  "weeks": [
    {
      "weekNumber": 1,
      "title": "string",
      "topics": ["Main topic", "Sub-topic 1", "Sub-topic 2"],
      "clo": ["1 Short CLO"],
      "objectives": ["Obj 1", "Obj 2"],
      "tasks": ["Task 1", "Code syntax (1 line)"],
      "advantages": "1 Short sentence",
      "disadvantages": "1 Short sentence"
    }
  ]
}
`;

    let aiResponse = await callAI({ prompt: finalPrompt });
    let aiData;

    try {
      if (typeof aiResponse === "string") {
        aiData = JSON.parse(aiResponse.replace(/```json/g, "").replace(/```/g, "").trim());
      } else {
        aiData = aiResponse;
      }
    } catch (err) {
      return res.status(500).json({ success: false, message: "AI output was too long and broke. Try making your prompt shorter." });
    }

    if (!aiData?.weeks || aiData.weeks.length !== 18) {
      return res.status(500).json({ success: false, message: "AI must generate exactly 18 weeks" });
    }

    const formattedWeeks = aiData.weeks.map((w, i) => ({
      weekNumber: i + 1,
      title: w.title || `Week ${i + 1}`,
      topics: Array.isArray(w.topics) ? w.topics : Array.isArray(w.topic) ? w.topic : w.topic ? [w.topic] : ["Topic pending"],
      clo: Array.isArray(w.clo) && w.clo.length ? w.clo : ["Analyze core concepts"],
      objectives: Array.isArray(w.objectives) && w.objectives.length ? w.objectives : ["Understand theoretical definitions"],
      tasks: Array.isArray(w.tasks) ? w.tasks : w.tasks ? [w.tasks] : [],
      advantages: w.advantages || "",
      disadvantages: w.disadvantages || "",
    }));

    const plan = await WeekPlan.create({
      course: courseId, teacher: req.user._id,
      title: aiData.title, description: aiData.description,
      weeks: formattedWeeks, semesterDuration: 18,
      prompt: userPrompt || "", generationSource: "prompt",
    });

    return res.status(201).json({ success: true, message: "AI 18-week plan generated successfully", plan });
  } catch (error) {
    return res.status(500).json({ success: false, error: error.message });
  }
};

// ===============================
// DOWNLOAD AI FULL PLAN PDF
// ===============================
exports.downloadAIPlanPDF = async (req, res) => {
  try {
    const { courseId } = req.params;

    const plan = await WeekPlan.findOne({
      course: courseId,
      teacher: req.user._id,
    }).populate({
      path: "course",
      populate: { path: "teacher", select: "name" },
    });

    if (!plan) return res.status(404).json({ message: "AI Plan not found" });

    const doc = new PDFDocument({ margin: 50 });
    res.setHeader("Content-Type", "application/pdf");
    res.setHeader("Content-Disposition", `attachment; filename=AI_18Week_Plan_${courseId}.pdf`);
    doc.pipe(res);

    doc.fontSize(22).text(plan.title || "AI 18 Week Plan", { align: "center" });
    doc.moveDown();
    doc.fontSize(12).text(plan.description || "", { align: "center" });
    doc.moveDown();

    doc.text(`Course: ${plan.course?.title || "N/A"}`);
    doc.text(`Instructor: ${plan.course?.teacher?.name || "N/A"}`);
    doc.text(`Code: ${plan.course?.courseCode || "N/A"}`);
    doc.text(`Duration: ${plan.semesterDuration || 18} Weeks`);
    doc.moveDown(2);

    plan.weeks.forEach((week) => {
      if (doc.y > 700) doc.addPage();

      const titleDisplay = week.title || `Week ${week.weekNumber}`;
      doc.fontSize(14).text(`${titleDisplay}`, { underline: true });
      doc.moveDown(0.5);
      doc.fontSize(12);

      if (week.topics && week.topics.length > 0) {
        doc.text("Topics & Sub-topics:");
        week.topics.forEach((t) => doc.text(`• ${t}`, { indent: 20 }));
        doc.moveDown(0.3);
      }

      const cloList = Array.isArray(week.clo) ? week.clo : week.clo ? [week.clo] : [];
      doc.text("CLO:");
      if (cloList.length > 0) {
        cloList.forEach((c) => doc.text(`• ${c}`, { indent: 20 }));
      } else {
        doc.text("• Not defined", { indent: 20 });
      }
      doc.moveDown(0.3);

      if (week.objectives && week.objectives.length > 0) {
        doc.text("Objectives:");
        week.objectives.forEach((o) => doc.text(`• ${o}`, { indent: 20 }));
        doc.moveDown(0.3);
      }

      if (week.tasks && week.tasks.length > 0) {
        doc.text("Tasks:");
        week.tasks.forEach((t) => doc.text(`• ${t}`, { indent: 20 }));
        doc.moveDown(0.3);
      }

      if (week.advantages) { doc.text("Advantages: " + week.advantages); doc.moveDown(0.3); }
      if (week.disadvantages) { doc.text("Disadvantages: " + week.disadvantages); doc.moveDown(0.3); }

      doc.moveDown(1);
      doc.text("---------------------------------------------");
      doc.moveDown(1);
    });

    doc.fontSize(10).fillColor("gray").text("Generated by AI Academic Curriculum System", { align: "center" });
    doc.end();
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};