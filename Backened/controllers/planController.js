const WeekPlan = require("../models/WeekPlan");
const Course = require("../models/Course");
const User = require("../models/User");
const PDFDocument = require("pdfkit");
const fs = require("fs");
const pdfParse = require("pdf-parse");
const Tesseract = require("tesseract.js");
const { callAI } = require("../services/aiService");

// 🔥 IMPORT GLOBAL CENTRAL NOTIFICATION ENGINE
const NotificationService = require("../services/notificationService");

// ===============================
// CREATE WEEK PLAN (MANUAL)
// ===============================
exports.generatePlan = async (req, res) => {
  try {
    // 🔒 SECURITY GUARD ADDED
    if (!req.user || !req.user._id) {
      return res.status(401).json({ success: false, message: "Unauthorized: Please log in." });
    }

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

    try {
      const studentIds = course.students.map(s => s.user.toString());
      if (studentIds.length > 0) {
        const users = await User.find({ _id: { $in: studentIds } }).select("fcmToken").lean();

        for (const user of users) {
          if (user.fcmToken && user.fcmToken.trim() !== "") {
            await NotificationService.sendPushNotification(
              user.fcmToken,
              "New Week Plan Available 📚",
              `Instructor ${req.user.name || "Teacher"} has published the weekly academic roadmap for ${course.title}.`,
              { courseId: course._id.toString(), type: "plan" }
            );
          }
        }
      }
    } catch (notifyErr) {
      console.log("Week Plan manual notification service error:", notifyErr.message);
    }

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
    // 🔒 SECURITY GUARD ADDED
    if (!req.user || !req.user._id) {
      return res.status(401).json({ success: false, message: "Unauthorized: Please log in." });
    }

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
    // 🔒 SECURITY GUARD ADDED
    if (!req.user || !req.user._id) {
      return res.status(401).json({ success: false, message: "Unauthorized: Please log in." });
    }

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

    doc.fontSize(16).text(`Week ${week.weekNumber}: ${week.title || "Topic"}`, { underline: true });
    doc.moveDown();
    doc.fontSize(12);

    if (week.definition && week.definition !== "Pending" && week.definition.trim() !== "") {
      doc.font('Helvetica-Bold').text("Definition: ", { continued: true }).font('Helvetica').text(week.definition);
      doc.moveDown(0.5);
    }

    if (week.detailedExplanation && week.detailedExplanation !== "Pending" && week.detailedExplanation.trim() !== "") {
      doc.font('Helvetica-Bold').text("Explanation: ").font('Helvetica').text(week.detailedExplanation);
      doc.moveDown(0.5);
    }

    if (week.subTopics && week.subTopics.length > 0) {
      doc.font('Helvetica-Bold').text("Sub-Topics:");
      doc.font('Helvetica');
      week.subTopics.forEach((t) => doc.text(`• ${t}`, { indent: 20 }));
      doc.moveDown(0.5);
    }

    if (week.codeOrQuerySnippet && week.codeOrQuerySnippet.trim() !== "") {
      doc.font('Helvetica-Bold').text("Snippet / Code:").font('Courier').text(week.codeOrQuerySnippet, { indent: 20 });
      doc.font('Helvetica').moveDown(0.5);
    }

    if (week.realWorldAnalogy && week.realWorldAnalogy.trim() !== "") {
      doc.font('Helvetica-Bold').text("Analogy: ").font('Helvetica-Oblique').text(week.realWorldAnalogy);
      doc.font('Helvetica').moveDown(0.5);
    }

    if (week.topics && week.topics.length > 0) {
      doc.font('Helvetica-Bold').text("Topics:"); doc.font('Helvetica');
      week.topics.forEach((t) => doc.text(`• ${t}`, { indent: 20 }));
      doc.moveDown(0.5);
    }

    const cloList = Array.isArray(week.clo) ? week.clo : week.clo ? [week.clo] : [];
    if (cloList.length > 0 && cloList[0] !== "Not defined" && cloList[0] !== "") {
       doc.font('Helvetica-Bold').text("CLO:"); doc.font('Helvetica');
       cloList.forEach((c) => doc.text(`• ${c}`, { indent: 20 }));
    }

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
    // 🔒 SECURITY GUARD ADDED
    if (!req.user || !req.user._id) {
      return res.status(401).json({ success: false, message: "Unauthorized: Please log in." });
    }

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
    // 🔒 SECURITY GUARD ADDED
    if (!req.user || !req.user._id) {
      return res.status(401).json({ success: false, message: "Unauthorized: Please log in." });
    }

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
    // 🔒 SECURITY GUARD ADDED
    if (!req.user || !req.user._id) {
      return res.status(401).json({ success: false, message: "Unauthorized: Please log in." });
    }

    const { courseId, weekNumber, prompt } = req.body;
    if (!courseId || !weekNumber) return res.status(400).json({ success: false, message: "courseId and weekNumber required" });

    const course = await Course.findById(courseId).lean();
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

    try {
      if (course && course.students) {
        const studentIds = course.students.map(s => s.user.toString());
        if (studentIds.length > 0) {
          const users = await User.find({ _id: { $in: studentIds } }).select("fcmToken").lean();

          for (const user of users) {
            if (user.fcmToken && user.fcmToken.trim() !== "") {
              await NotificationService.sendPushNotification(
                user.fcmToken,
                "Week Plan Material Evolved! ⚡",
                `Topic configurations for Week ${weekNumber} have been dynamically enhanced by AI engine optimization.`,
                { courseId: courseId.toString(), type: "plan" }
              );
            }
          }
        }
      }
    } catch (notifyErr) {
      console.log("AI update plan layout notification failed:", notifyErr.message);
    }

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
    // 🔒 SECURITY GUARD ADDED
    if (!req.user || !req.user._id) {
      return res.status(401).json({ success: false, message: "Unauthorized: Please log in." });
    }

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

exports.generateAIPlanFromBook = async (req, res) => {
  if (!req.user) return res.status(401).json({ success: false, message: "Unauthorized." });
  res.status(200).json({ success: true, message: "Please use AI endpoints." });
};
exports.generateAIPlan = async (req, res) => {
  if (!req.user) return res.status(401).json({ success: false, message: "Unauthorized." });
  res.status(200).json({ success: true, message: "Please use AI endpoints." });
};

// ===============================
// DOWNLOAD AI FULL PLAN PDF
// ===============================
exports.downloadAIPlanPDF = async (req, res) => {
  try {
    // 🔒 SECURITY GUARD ADDED
    if (!req.user || !req.user._id) {
      return res.status(401).json({ success: false, message: "Unauthorized: Please log in." });
    }

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

      if (week.definition && week.definition !== "Pending" && week.definition.trim() !== "") {
        doc.font('Helvetica-Bold').text("Definition: ", { continued: true }).font('Helvetica').text(week.definition);
        doc.moveDown(0.3);
      }

      if (week.detailedExplanation && week.detailedExplanation !== "Pending" && week.detailedExplanation.trim() !== "") {
        doc.font('Helvetica-Bold').text("Explanation: ").font('Helvetica').text(week.detailedExplanation);
        doc.moveDown(0.3);
      }

      if (week.subTopics && week.subTopics.length > 0) {
        doc.font('Helvetica-Bold').text("Sub-Topics:");
        doc.font('Helvetica');
        week.subTopics.forEach((t) => doc.text(`• ${t}`, { indent: 20 }));
        doc.moveDown(0.3);
      }

      if (week.codeOrQuerySnippet && week.codeOrQuerySnippet.trim() !== "") {
        doc.font('Helvetica-Bold').text("Snippet / Code:").font('Courier').text(week.codeOrQuerySnippet, { indent: 20 });
        doc.font('Helvetica').moveDown(0.3);
      }

      if (week.realWorldAnalogy && week.realWorldAnalogy.trim() !== "") {
        doc.font('Helvetica-Bold').text("Analogy: ").font('Helvetica-Oblique').text(week.realWorldAnalogy);
        doc.font('Helvetica').moveDown(0.3);
      }

      if (week.topics && week.topics.length > 0) {
        doc.font('Helvetica-Bold').text("Topics & Sub-topics:"); doc.font('Helvetica');
        week.topics.forEach((t) => doc.text(`• ${t}`, { indent: 20 }));
        doc.moveDown(0.3);
      }

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