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
      return res.status(400).json({
        success: false,
        message: "courseId and weeks array are required",
      });
    }

    // check course belongs to teacher
    const course = await Course.findOne({
      _id: courseId,
      teacher: req.user._id,
    });

    if (!course) {
      return res.status(404).json({
        success: false,
        message: "Course not found or not authorized",
      });
    }

    // prevent duplicate plan
    const existingPlan = await WeekPlan.findOne({
      course: courseId,
      teacher: req.user._id,
    });

    if (existingPlan) {
      return res.status(400).json({
        success: false,
        message: "Week plan already exists for this course",
      });
    }

    // validate weeks
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

    return res.status(201).json({
      success: true,
      message: "Week plan created successfully",
      plan,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};



// ===============================
// GET PLAN BY COURSE (TEACHER + STUDENT)
// ===============================
exports.getPlanByCourse = async (req, res) => {
  try {
    const { courseId } = req.params;

    let plan;

    if (req.user.role === "teacher") {
      plan = await WeekPlan.findOne({
        course: courseId,
        teacher: req.user._id,
      }).populate("course", "title courseCode syllabus");
    } else {
      plan = await WeekPlan.findOne({
        course: courseId,
      }).populate("course", "title courseCode syllabus");
    }

    if (!plan) {
      return res.status(404).json({
        success: false,
        message: "No weekly plan found",
      });
    }

    return res.json({
      success: true,
      plan,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};


// ===============================
// GENERATE SINGLE WEEK PDF
// ===============================
exports.generateWeekPDF = async (req, res) => {
  try {
    const { courseId, weekNumber } = req.params;

    const course = await Course.findById(courseId).populate(
      "teacher",
      "name"
    );

    if (!course) {
      return res.status(404).json({ message: "Course not found" });
    }

    const plan = await WeekPlan.findOne({ course: courseId });

    if (!plan) {
      return res.status(404).json({ message: "Week plan not found" });
    }

    const week = plan.weeks.find(
      (w) => w.weekNumber == weekNumber
    );

    if (!week) {
      return res.status(404).json({ message: "Week not found" });
    }

    if (
      req.user.role === "teacher" &&
      course.teacher._id.toString() !== req.user._id.toString()
    ) {
      return res.status(403).json({ message: "Access denied" });
    }

    const doc = new PDFDocument({ margin: 50 });

    res.setHeader("Content-Type", "application/pdf");
    res.setHeader(
      "Content-Disposition",
      `attachment; filename=AI_Week_${week.weekNumber}_${course.title}.pdf`
    );

    doc.pipe(res);

    // ================= HEADER =================
    doc.fontSize(20).text("AI Generated Weekly Plan", { align: "center" });
    doc.moveDown();

    // ================= COURSE INFO =================
    doc.fontSize(14).text(`Course: ${course.title}`);
    doc.text(`Code: ${course.courseCode || "N/A"}`);
    doc.text(`Instructor: ${course.teacher?.name || "N/A"}`);
    doc.text(`Semester: ${plan.semesterDuration} Weeks`);

    doc.moveDown(2);

    // ================= WEEK INFO =================
    doc.fontSize(16).text(`Week ${week.weekNumber}: ${week.title}`, {
      underline: true,
    });

    doc.moveDown();

    doc.fontSize(12);

    if (week.topics?.length) {
      doc.text("Topics:");
      week.topics.forEach((t) => doc.text(`• ${t}`, { indent: 20 }));
    }

   // ================= CLO (ALWAYS DISPLAY) =================
const cloList = Array.isArray(week.clo)
  ? week.clo
  : week.clo
  ? [week.clo]
  : [];

doc.moveDown(0.5);
doc.text("CLO:");

if (cloList.length > 0) {
  cloList.forEach((c) => {
    doc.text(`• ${c}`, { indent: 20 });
  });
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
      doc.text("Tasks:");
      week.tasks.forEach((t) => doc.text(`• ${t}`, { indent: 20 }));
    }

    // ================= NEW AI FIELDS =================
    if (week.advantages) {
      doc.moveDown(0.5);
      doc.text("Advantages:");
      doc.text(week.advantages);
    }

    if (week.disadvantages) {
      doc.moveDown(0.5);
      doc.text("Disadvantages:");
      doc.text(week.disadvantages);
    }

    // ================= FOOTER =================
    doc.moveDown(2);
    doc
      .fontSize(10)
      .fillColor("gray")
      .text("Generated by AI Academic System", { align: "center" });

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
    const plan = await WeekPlan.findOne({
      _id: req.params.id,
      teacher: req.user._id,
    });

    if (!plan) {
      return res.status(404).json({
        success: false,
        message: "Plan not found",
      });
    }

    if (req.body.weeks) {
      plan.weeks = req.body.weeks;
    }

    await plan.save();

    return res.json({
      success: true,
      message: "Plan updated successfully",
      plan,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};



// ===============================
// DELETE PLAN
// ===============================
exports.deletePlan = async (req, res) => {
  try {
    const plan = await WeekPlan.findOne({
      _id: req.params.id,
      teacher: req.user._id,
    });

    if (!plan) {
      return res.status(404).json({
        success: false,
        message: "Plan not found",
      });
    }

    await plan.deleteOne();

    return res.json({
      success: true,
      message: "Plan deleted successfully",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};




exports.updateWeekAI = async (req, res) => {
  try {
    const { courseId, weekNumber, prompt } = req.body;

    if (!courseId || !weekNumber) {
      return res.status(400).json({
        success: false,
        message: "courseId and weekNumber are required",
      });
    }

    const plan = await WeekPlan.findOne({
      course: courseId,
      teacher: req.user._id,
    });

    if (!plan) {
      return res.status(404).json({
        success: false,
        message: "Week plan not found",
      });
    }

    const weekIndex = plan.weeks.findIndex(
      (w) => w.weekNumber == weekNumber
    );

    if (weekIndex === -1) {
      return res.status(404).json({
        success: false,
        message: "Week not found",
      });
    }

    const currentWeek = plan.weeks[weekIndex];

    const aiPrompt = `
You are an academic AI.

Update ONLY this university week.

CURRENT WEEK:
${JSON.stringify(currentWeek)}

TEACHER REQUEST:
${prompt || "Improve clarity and academic depth"}

RETURN ONLY JSON:
{
  "title": "string",
  "topic": "string",
  "clo": "string",
  "objectives": ["string"],
  "tasks": ["string"],
  "advantages": "string",
  "disadvantages": "string"
}
`;

    let aiResponse = await callAI({
  prompt: aiPrompt,
});

    if (typeof aiResponse === "string") {
      aiResponse = aiResponse.replace(/```json/g, "").replace(/```/g, "").trim();
      aiResponse = JSON.parse(aiResponse);
    }

    // update only that week
    plan.weeks[weekIndex] = {
  ...plan.weeks[weekIndex]._doc,

  title: aiResponse.title || currentWeek.title,

  topics: aiResponse.topic
    ? [aiResponse.topic]
    : currentWeek.topics,

  clo: Array.isArray(aiResponse.clo)
  ? aiResponse.clo
  : aiResponse.clo
    ? [aiResponse.clo]
    : currentWeek.clo || [],

  objectives:
    aiResponse.objectives || currentWeek.objectives,

  tasks:
    aiResponse.tasks || currentWeek.tasks,

  advantages:
    aiResponse.advantages || currentWeek.advantages,

  disadvantages:
    aiResponse.disadvantages || currentWeek.disadvantages,
};

    await plan.save();

    return res.json({
      success: true,
      message: "Week updated using AI",
      week: plan.weeks[weekIndex],
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};



exports.deleteWeek = async (req, res) => {
  try {
    const { courseId, weekNumber } = req.params;

    const weekNum = Number(weekNumber);

    if (!courseId || isNaN(weekNum)) {
      return res.status(400).json({
        success: false,
        message: "Invalid input",
      });
    }

    const plan = await WeekPlan.findOne({
      course: courseId,
      teacher: req.user._id,
    });

    if (!plan) {
      return res.status(404).json({
        success: false,
        message: "Plan not found",
      });
    }

    const index = plan.weeks.findIndex(
      (w) => w.weekNumber === weekNum
    );

    if (index === -1) {
      return res.status(404).json({
        success: false,
        message: "Week not found",
      });
    }

    plan.weeks.splice(index, 1);

    await plan.save(); // now safe after schema fix

    return res.status(200).json({
      success: true,
      message: "Week deleted successfully",
      weeks: plan.weeks,
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Server error",
      error: error.message,
    });
  }
};


exports.generateAIPlanFromBook = async (req, res) => {
  try {
    const { courseId } = req.body;

    if (!courseId || !req.file) {
      return res.status(400).json({
        success: false,
        message: "courseId and book file are required",
      });
    }

    // ===============================
    // COURSE VALIDATION
    // ===============================
    const course = await Course.findOne({
      _id: courseId,
      teacher: req.user._id,
    });

    if (!course) {
      return res.status(404).json({
        success: false,
        message: "Course not found or not authorized",
      });
    }

    // ===============================
    // DUPLICATE CHECK
    // ===============================
    const existingPlan = await WeekPlan.findOne({
      course: courseId,
      teacher: req.user._id,
    });

    if (existingPlan) {
      return res.status(400).json({
        success: false,
        message: "Week plan already exists",
      });
    }

    // ===============================
    // FILE DATA
    // ===============================
    const filePath = req.file.path;
    const fileType = req.file.mimetype;

    let extractedText = "";

    // ===============================
    // PDF + IMAGE EXTRACTION
    // ===============================
    try {
      if (fileType.includes("pdf")) {
        const dataBuffer = fs.readFileSync(filePath);
        const pdfData = await pdfParse(dataBuffer);
        extractedText = pdfData.text || "";
      } 
      else if (fileType.includes("image")) {
        const result = await Tesseract.recognize(filePath, "eng", {
          logger: (m) => console.log(m),
        });
        extractedText = result.data.text || "";
      }
    } catch (err) {
      console.log("Extraction error:", err);
      extractedText = "";
    }

    // fallback
    if (!extractedText || extractedText.length < 50) {
      extractedText =
        "Analyze academic material and generate a structured university semester plan.";
    }

    extractedText = extractedText.substring(0, 4000);

    // ===============================
    // AI PROMPT (NO USER PROMPT)
    // ===============================
    const finalPrompt = `
You are a STRICT UNIVERSITY CURRICULUM DESIGN AI.

COURSE:
- Title: ${course.title}
- Code: ${course.courseCode || "N/A"}

MATERIAL:
${extractedText}

TASK:
Generate EXACTLY 18 WEEK UNIVERSITY PLAN.

RULES:
- Must be strictly 18 weeks
- Follow academic progression
- Week 1-3 Fundamentals
- Week 4-7 Core
- Week 8-12 Intermediate
- Week 13-16 Advanced
- Week 17 Revision
- Week 18 Final Assessment

RETURN ONLY VALID JSON:

{
  "title": "string",
  "description": "string",
  "weeks": [
    {
      "title": "string",
      "topic": "string",
      "clo": "string",
      "objectives": ["string"],
      "tasks": ["string"],
      "advantages": "string",
      "disadvantages": "string"
    }
  ]
}
`;

    // ===============================
    // AI CALL
    // ===============================
    const aiResponse = await callAI({
      prompt: finalPrompt,
    });

    let aiData = aiResponse;

    // ===============================
    // VALIDATION
    // ===============================
    if (!aiData?.weeks || !Array.isArray(aiData.weeks)) {
      return res.status(500).json({
        success: false,
        message: "AI did not return valid weeks",
      });
    }

    // FORCE EXACT 18 WEEKS
    if (aiData.weeks.length !== 18) {
      aiData.weeks = aiData.weeks.slice(0, 18);

      while (aiData.weeks.length < 18) {
        aiData.weeks.push({
          title: `Week ${aiData.weeks.length + 1}`,
          topic: "To be completed",
          objectives: [],
          tasks: [],
          advantages: "",
          disadvantages: "",
        });
      }
    }

    // ===============================
    // FORMAT WEEKS
    // ===============================
    const formattedWeeks = aiData.weeks.map((w, i) => ({
      weekNumber: i + 1,
      title: w.title || `Week ${i + 1}`,
      topics: Array.isArray(w.topics)
      ? w.topics
      : w.topic
      ? [w.topic]
      : [],

     clo: Array.isArray(w.clo)
  ? w.clo
  : w.clo
    ? [w.clo]
    : [],
      objectives: w.objectives || [],
      tasks: w.tasks || [],
      advantages: w.advantages || "",
      disadvantages: w.disadvantages || "",
    }));

    // ===============================
    // SAVE PLAN
    // ===============================
    const plan = await WeekPlan.create({
      course: courseId,
      teacher: req.user._id,

      title: aiData.title || "AI Book-Based Plan",
      description: aiData.description || "Generated from uploaded book",

      weeks: formattedWeeks,
      semesterDuration: 18,

      bookFileUrl: filePath,
      bookFileType: fileType.includes("image") ? "image" : "pdf",
      bookExtractedText: extractedText,

      generationSource: "book",
      prompt: "", // NO PROMPT USED
    });

    return res.status(201).json({
      success: true,
      message: "AI plan generated successfully from PDF/Image",
      plan,
    });

  } catch (error) {
    console.error("generateAIPlanFromBook ERROR:", error);
    return res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};



// ===============================
// GENERATE AI 18 WEEK PLAN (FIXED + CUSTOM PROMPT)
// ===============================
exports.generateAIPlan = async (req, res) => {
  try {
    const { courseId, prompt: userPrompt } = req.body;

    if (!courseId) {
      return res.status(400).json({
        success: false,
        message: "courseId is required",
      });
    }

    const course = await Course.findOne({
      _id: courseId,
      teacher: req.user._id,
    });

    if (!course) {
      return res.status(404).json({
        success: false,
        message: "Course not found or not authorized",
      });
    }

    const existingPlan = await WeekPlan.findOne({
      course: courseId,
      teacher: req.user._id,
    });

    if (existingPlan) {
      return res.status(400).json({
        success: false,
        message: "Week plan already exists for this course",
      });
    }

    // ===============================
    // PRO AI PROMPT (UNIVERSITY LEVEL)
    // ===============================
    const finalPrompt = `
You are a PROFESSIONAL UNIVERSITY CURRICULUM DESIGN AI.

COURSE:
- Title: ${course.title}
- Code: ${course.courseCode || "N/A"}

TEACHER REQUEST:
${userPrompt || "Standard academic progression"}

TASK:
Generate a STRICT 18-WEEK UNIVERSITY SEMESTER PLAN.

RULES:
- EXACTLY 18 WEEKS
- Must follow academic progression:
  Week 1-3: Fundamentals
  Week 4-7: Core Concepts
  Week 8-12: Intermediate
  Week 13-16: Advanced Topics
  Week 17: Revision
  Week 18: Final Project / Assessment

Each week MUST include:
- topic
- CLO (measurable outcome)
- objectives (array)
- tasks (array)
- advantages (learning benefit)
- disadvantages (limitations or challenges)

RETURN ONLY VALID JSON:

{
  "title": "string",
  "description": "string",
  "weeks": [
    {
      "weekNumber": 1,
      "title": "string",
      "topic": "string",
      "clo": "string",
      "objectives": ["string"],
      "tasks": ["string"],
      "advantages": "string",
      "disadvantages": "string"
    }
  ]
}
`;

    let aiResponse = await callAI({
  prompt: finalPrompt,
});

    let aiData;

    try {
      if (typeof aiResponse === "string") {
        aiResponse = aiResponse.replace(/```json/g, "").replace(/```/g, "").trim();
        aiData = JSON.parse(aiResponse);
      } else {
        aiData = aiResponse;
      }
    } catch (err) {
      return res.status(500).json({
        success: false,
        message: "AI returned invalid JSON",
      });
    }

    if (!aiData?.weeks || aiData.weeks.length !== 18) {
      return res.status(500).json({
        success: false,
        message: "AI must generate exactly 18 weeks",
      });
    }

    const formattedWeeks = aiData.weeks.map((w, i) => ({
      weekNumber: i + 1,
      title: w.title || `Week ${i + 1}`,
     topics: Array.isArray(w.topics)
  ? w.topics
  : w.topic
  ? [w.topic]
  : [],
     clo: Array.isArray(w.clo)
  ? w.clo
  : w.clo
    ? [w.clo]
    : [],
      objectives: w.objectives || [],
      tasks: w.tasks || [],
      advantages: w.advantages || "",
      disadvantages: w.disadvantages || "",
    }));

    const plan = await WeekPlan.create({
  course: courseId,
  teacher: req.user._id,

  title: aiData.title,
  description: aiData.description,

  weeks: formattedWeeks,
  semesterDuration: 18,

  // ✅ NEW
  prompt: userPrompt || "",
  generationSource: "prompt",
});

    return res.status(201).json({
      success: true,
      message: "AI 18-week plan generated successfully",
      plan,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      error: error.message,
    });
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

    if (!plan) {
      return res.status(404).json({ message: "AI Plan not found" });
    }

    const doc = new PDFDocument({ margin: 50 });

    res.setHeader("Content-Type", "application/pdf");
    res.setHeader(
      "Content-Disposition",
      `attachment; filename=AI_18Week_Plan_${courseId}.pdf`
    );

    doc.pipe(res);

    // ================= HEADER =================
    doc.fontSize(22).text(plan.title || "AI 18 Week Plan", { align: "center" });

    doc.moveDown();
    doc.fontSize(12).text(plan.description || "", { align: "center" });

    doc.moveDown();

    doc.text(`Course: ${plan.course?.title || "N/A"}`);
    doc.text(`Instructor: ${plan.course?.teacher?.name || "N/A"}`);
    doc.text(`Code: ${plan.course?.courseCode || "N/A"}`);
    doc.text(`Duration: ${plan.semesterDuration || 18} Weeks`);

    doc.moveDown(2);

    // ================= SAFE 18 WEEK GUARANTEE =================
    const safeWeeks = Array.from({ length: 18 }, (_, i) => {
      const week = plan.weeks?.find(w => w.weekNumber === i + 1);

      // FORCE DEFAULT STRUCTURE
      return {
        weekNumber: i + 1,
        title:
          week?.title ||
          (i === 16
            ? "Revision Week"
            : i === 17
            ? "Final Assessment"
            : `Week ${i + 1}`),

        topics: week?.topics?.length
          ? week.topics
          : week?.topic
          ? [week.topic]
          : ["Core Concept Development", "Practical Understanding", "Application Focus"],

        objectives:
          week?.objectives?.length > 0
            ? week.objectives
            : [
                "Understand key concepts",
                "Apply theoretical knowledge",
                "Develop analytical skills",
              ],

        tasks:
          week?.tasks?.length > 0
            ? week.tasks
            : [
                "Class lecture participation",
                "Assignment completion",
                "Practice exercises",
              ],

             clo: Array.isArray(week?.clo) && week.clo.length
  ? week.clo
  : week?.clo
    ? [week.clo]
    : ["Understand and apply course concepts effectively"],

        advantages:
          week?.advantages ||
          "Enhances conceptual clarity, improves problem-solving, strengthens academic foundation",

        disadvantages:
          week?.disadvantages ||
          "Requires consistent effort, may be challenging for beginners, needs practice"
      };
    });

    // ================= PRINT WEEKS =================
    safeWeeks.forEach((week) => {
      if (doc.y > 700) doc.addPage();

      doc
        .fontSize(14)
        .text(`Week ${week.weekNumber}: ${week.topics}`, {
          underline: true,
        });

      doc.moveDown(0.5);
      doc.fontSize(12);

      // TOPICS (always 3)
      doc.text("Topics:");
      week.topics.slice(0, 3).forEach((t) => {
        doc.text(`• ${t}`, { indent: 20 });
      });

     // ================= CLO (ALWAYS DISPLAY) =================
const cloList = Array.isArray(week.clo)
  ? week.clo
  : week.clo
  ? [week.clo]
  : [];

doc.moveDown(0.5);
doc.text("CLO:");

if (cloList.length > 0) {
  cloList.forEach((c) => {
    doc.text(`• ${c}`, { indent: 20 });
  });
} else {
  doc.text("• Not defined", { indent: 20 });
}

      doc.moveDown(0.3);

      // OBJECTIVES (always 3)
      doc.text("Objectives:");
      week.objectives.slice(0, 3).forEach((o) => {
        doc.text(`• ${o}`, { indent: 20 });
      });

      doc.moveDown(0.3);

      // TASKS (always 3)
      doc.text("Tasks:");
      week.tasks.slice(0, 3).forEach((t) => {
        doc.text(`• ${t}`, { indent: 20 });
      });

      doc.moveDown(0.3);

      // ADVANTAGES
      doc.text("Advantages:");
      doc.text(`• ${week.advantages}`, { indent: 20 });

      doc.moveDown(0.3);

      // DISADVANTAGES
      doc.text("Disadvantages:");
      doc.text(`• ${week.disadvantages}`, { indent: 20 });

      doc.moveDown(1);
      doc.text("---------------------------------------------");
      doc.moveDown(1);
    });

    // ================= FOOTER =================
    doc
      .fontSize(10)
      .fillColor("gray")
      .text("Generated by AI Academic Curriculum System", {
        align: "center",
      });

    doc.end();
  } catch (error) {
    console.error(error);
    return res.status(500).json({ error: error.message });
  }
};


