const path = require("path");
const fs = require("fs");
const Quiz = require("../models/Quiz");
const Course = require("../models/Course");
const User = require("../models/User");
const { generateQuizPDF } = require("../utils/quizPdfGenerator");
const { callAI } = require("../services/aiService");
const pdfParse = require("pdf-parse");
const NotificationService = require("../services/notificationService");

exports.createAIQuestionQuiz = async (req, res) => {
  try {
    // 🔒 STRICT GUARD
    if (!req.user || req.user.role !== "teacher") {
      return res.status(403).json({ success: false, message: "Forbidden: Unauthorized access to AI Assessor." });
    }

    let { courseId, topic, prompt, courseTitle, difficulty = "hard", shortCount = 0, longCount = 0, shortEachMark = 2, longEachMark = 5, type = "long", openDateTime, deadlineDateTime } = req.body;

    const finalCourseId = (courseId && courseId !== "UNKNOWN") ? courseId : null;
    let finalTopic = topic || prompt || courseTitle || "General Subjective Assessment";
    const finalTeacherId = req.user._id;

    const sCount = Number(shortCount) || 0;
    const lCount = Number(longCount) || 0;
    const sEach = Number(shortEachMark) || 2;
    const lEach = Number(longEachMark) || 5;

    let parsedOpenDate = openDateTime ? new Date(openDateTime) : new Date();
    let parsedDeadlineDate = deadlineDateTime ? new Date(deadlineDateTime) : new Date(Date.now() + 24 * 60 * 60 * 1000);

    let extractedText = "";
    if (req.file && req.file.mimetype === "application/pdf") {
      try {
          const dataBuffer = fs.readFileSync(req.file.path);
          const pdfData = await pdfParse(dataBuffer);
          extractedText = pdfData.text ? pdfData.text.substring(0, 25000) : "";
      } catch(e) {}
    }

    let formatRequirementText = "";
    if (type === "short") {
      formatRequirementText = `Generate EXACTLY ${sCount} short questions. \nJSON Layout:\n{ "title": "...", "description": "...", "shortQuestions": [{ "question": "...", "marks": ${sEach}, "idealAnswer": "...", "rubric": "..." }] }`;
    } else if (type === "long") {
      formatRequirementText = `Generate EXACTLY ${lCount} long questions. \nJSON Layout:\n{ "title": "...", "description": "...", "longQuestions": [{ "question": "...", "marks": ${lEach}, "idealAnswer": "...", "rubric": "..." }] }`;
    } else {
      formatRequirementText = `Generate ${sCount} short and ${lCount} long questions. \nJSON Layout:\n{ "title": "...", "description": "...", "shortQuestions": [{ "question": "...", "marks": ${sEach}, "idealAnswer": "...", "rubric": "..." }], "longQuestions": [{ "question": "...", "marks": ${lEach}, "idealAnswer": "...", "rubric": "..." }] }`;
    }

    const groqPrompt = `You are a Senior Academic Assessor. Generate descriptive exam questions.
Topic: ${finalTopic}\nDifficulty: ${difficulty}
${extractedText ? `Reference Text Context:\n${extractedText}\n\n` : ''}
STRICT RULE: Respond with clean raw JSON only. Provide deeply detailed 'idealAnswer' and a specific 'rubric' for fair grading.
${formatRequirementText}`;

    const aiData = await callAI({ prompt: groqPrompt, model: "llama-3.1-70b-versatile" });
    if (!aiData || (!aiData.shortQuestions && !aiData.longQuestions)) {
      return res.status(500).json({ success: false, message: "Invalid JSON structure from Groq" });
    }

    const dbShortArray = (aiData.shortQuestions || []).slice(0, sCount).map(q => ({ question: q.question, marks: sEach, idealAnswer: q.idealAnswer || "Brief solution.", rubric: q.rubric || "Standard marks." }));
    const dbLongArray = (aiData.longQuestions || []).slice(0, lCount).map(q => ({ question: q.question, marks: lEach, idealAnswer: q.idealAnswer || "Detailed solution.", rubric: q.rubric || "Full architectural details." }));
    const totalMarks = (dbShortArray.length * sEach) + (dbLongArray.length * lEach);

    const uploadDir = path.join(__dirname, "../uploads");
    if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });
    const fileName = `quiz-${Date.now()}.pdf`;
    const filePath = path.join(uploadDir, fileName);

    aiData.shortQuestions = dbShortArray; aiData.longQuestions = dbLongArray; aiData.grandTotalMarks = totalMarks;
    await generateQuizPDF(aiData, filePath);

    const savedQuizModel = new Quiz({
      course: finalCourseId, teacher: finalTeacherId,
      title: aiData.title || `Written Exam Paper for ${finalTopic}`, description: aiData.description || "In-Depth Descriptive Assessment",
      type: type === "both" ? "mixed" : "question",
      shortQuestions: dbShortArray, longQuestions: dbLongArray,
      totalMarks: totalMarks, isAIScanned: false,
      openDateTime: parsedOpenDate, deadlineDateTime: parsedDeadlineDate
    });

    await savedQuizModel.save();
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
                user.fcmToken, "AI Exam Scheduled! 🤖📝",
                `An AI-generated written exam titled "${savedQuizModel.title}" has been securely scheduled.`,
                { courseId: finalCourseId.toString(), type: "quiz" }
              );
            }
          }
        }
      }
    } catch (notifyErr) { console.log("AI Quiz central notification error:", notifyErr.message); }

    return res.status(200).json({ success: true, message: "Quiz generated perfectly using Groq", pdfUrl: `${req.protocol}://${req.get("host")}/uploads/${fileName}`, quiz: savedQuizModel });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};