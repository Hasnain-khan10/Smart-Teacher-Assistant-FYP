const Quiz = require("../models/Quiz");
const Course = require("../models/Course");
const Attempt = require("../models/Attempt");
const path = require("path");
const { callAI } = require("../services/aiService");
const { generateQuizPDF } = require("../utils/quizPdfGenerator");
const fs = require("fs");
const sharp = require("sharp");

// ================================
// CREATE QUIZ (MANUAL)
// ================================
exports.createQuiz = async (req, res) => {
  try {
    const { title, type, questions, shortQuestions, longQuestions } = req.body;
    const courseId = req.body.courseId || req.body.course;

    if (!courseId || !title || !type) return res.status(400).json({ message: "Missing required fields" });

    const course = await Course.findOne({ _id: courseId, teacher: req.user._id });
    if (!course) return res.status(404).json({ message: "Course not found" });

    if (type === "mcq") {
      const totalMarks = (questions || []).reduce((sum, q) => sum + (q.marks || 1), 0);
      const quiz = await Quiz.create({ course: courseId, teacher: req.user._id, title, type: "mcq", questions, totalMarks });
      return res.status(201).json({ message: "MCQ Quiz created successfully", quiz });
    }

    if (type === "question") {
      const totalMarks = [...(shortQuestions || []), ...(longQuestions || [])].reduce((sum, q) => sum + (q.marks || 0), 0);
      const quiz = await Quiz.create({ course: courseId, teacher: req.user._id, title, type: "question", shortQuestions: shortQuestions || [], longQuestions: longQuestions || [], totalMarks });
      return res.status(201).json({ message: "Question Quiz created successfully", quiz });
    }

    if (type === "mixed") {
      const totalMarks = [...(questions || []), ...(shortQuestions || []), ...(longQuestions || [])].reduce((sum, q) => sum + (q.marks || 0), 0);
      const quiz = await Quiz.create({ course: courseId, teacher: req.user._id, title, type: "mixed", questions: questions || [], shortQuestions: shortQuestions || [], longQuestions: longQuestions || [], totalMarks });
      return res.status(201).json({ message: "Mixed Quiz created successfully", quiz });
    }

    return res.status(400).json({ message: "Invalid quiz type" });
  } catch (error) {
    return res.status(500).json({ message: "Failed to create quiz", error: error.message });
  }
};

// ================================
// GENERATE QUESTION QUIZ PDF
// ================================
exports.generateQuestionQuizPDF = async (req, res) => {
  try {
    const { courseId, title } = req.query;
    const quiz = await Quiz.findById(req.params.id).populate("course", "title");
    if (!quiz) return res.status(404).json({ message: "Quiz not found" });

    const pdfData = { title: title || quiz.title, shortQuestions: quiz.shortQuestions || [], longQuestions: quiz.longQuestions || [], totalMarks: quiz.totalMarks || 0, grandTotalMarks: quiz.totalMarks || 0 };
    const fileName = `question-quiz-${Date.now()}.pdf`;
    const filePath = path.join(__dirname, `../uploads/${fileName}`);

    await generateQuizPDF(pdfData, filePath);
    const pdfUrl = `${req.protocol}://${req.get("host")}/uploads/${fileName}`;

    return res.status(200).json({ message: "Question quiz PDF generated successfully", pdfUrl });
  } catch (error) {
    return res.status(500).json({ message: "Failed to generate PDF", error: error.message });
  }
};

// ================================
// GET ALL QUIZZES
// ================================
exports.getAllQuizzes = async (req, res) => {
  try {
    let quizzes = [];
    if (req.user.role === "teacher") {
      const data = await Quiz.find({ teacher: req.user._id }).populate("course", "title");
      quizzes = data.map(q => ({ ...q.toObject(), isCompleted: false, score: null, total: (q.questions || []).length, answers: [] }));
    }
    if (req.user.role === "student") {
      const courses = await Course.find({ "students.user": req.user._id }).select("_id");
      const courseIds = courses.map(c => c._id);
      if (courseIds.length === 0) return res.status(200).json({ quizzes: [] });

      const quizzesData = await Quiz.find({ course: { $in: courseIds } }).populate("course", "title").populate("teacher", "name");
      const attempts = await Attempt.find({ student: req.user._id, quiz: { $in: quizzesData.map(q => q._id) } });

      const attemptMap = {};
      attempts.forEach(a => { attemptMap[a.quiz.toString()] = a; });

      quizzes = quizzesData.map(q => {
        const attempt = attemptMap[q._id.toString()];
        return {
          ...q.toObject(),
          isCompleted: !!attempt,
          score: attempt ? attempt.score : null,
          totalMarks: attempt ? attempt.total : q.totalMarks,
          isAIScanned: q.isAIScanned || false,
          evaluatedByAI: attempt?.evaluatedByAI || false,
          title: q.title,
          total: q.type === "mcq" ? (q.questions || []).length : ((q.shortQuestions?.length || 0) + (q.longQuestions?.length || 0)),
          answers: attempt ? attempt.answers : [],
        };
      });
    }
    return res.status(200).json({ quizzes });
  } catch (error) {
    return res.status(500).json({ message: "Failed to fetch quizzes", error: error.message });
  }
};

// ================================
// GET QUIZZES BY COURSE
// ================================
exports.getQuizzesByCourse = async (req, res) => {
  try {
    let quizzes;
    if (req.user.role === "teacher") {
      quizzes = await Quiz.find({ course: req.params.courseId, teacher: req.user._id });
    } else {
      quizzes = await Quiz.find({ course: req.params.courseId }).populate("teacher", "name email");
    }
    res.json({ quizzes });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// =======================================================
// GET QUIZ RESULTS (TEACHER VIEW - WITH PAPER IMAGES)
// =======================================================
exports.getQuizResults = async (req, res) => {
  try {
    const quizId = req.params.quizId;
    const quiz = await Quiz.findOne({ _id: quizId, teacher: req.user._id }).populate("course", "title");

    if (!quiz) return res.status(404).json({ message: "Quiz not found" });

    const attempts = await Attempt.find({ quiz: quizId }).populate("student", "name email");

    const results = attempts.map((a) => {
      const evaluatedByAI = a.evaluatedByAI || false;
      let detailedAnswers = [];

      const scannedPaperUrls = (a.scannedPaper || []).map(fileName => {
        return `${req.protocol}://${req.get("host")}/uploads/${fileName}`;
      });

      if (quiz.type === "mcq") {
        detailedAnswers = (quiz.questions || []).map((q, idx) => {
          const studentAnsObj = a.answers && a.answers[idx] ? a.answers[idx] : {};
          const studentAnswer = studentAnsObj.selectedAnswer || "Not Answered";
          const isCorrect = studentAnswer === q.correctAnswer;
          return { question_text: q.question, student_answer: studentAnswer, correct_answer: q.correctAnswer, isCorrect: isCorrect, obtained_marks: isCorrect ? (q.marks || 1) : 0 };
        });
      } else if (evaluatedByAI) {
        detailedAnswers = (a.answers || []).map((ans) => ({
          question_text: ans.question_text || ans.question || "Question",
          student_answer: ans.student_answer || ans.studentAnswer || ans.selectedAnswer || "",
          correct_answer: ans.correct_answer || ans.correctAnswer || "See Rubric/Exam Key",
          isCorrect: ans.isCorrect ?? (Number(ans.obtained_marks || ans.marksObtained) > 0),
          obtained_marks: ans.obtained_marks ?? ans.marksObtained ?? 0
        }));
      }

      return {
        attemptId: a._id,
        studentId: a.student._id,
        name: a.student.name,
        email: a.student.email,
        score: a.score ?? 0,
        totalMarks: a.total ?? quiz.totalMarks,
        evaluatedByAI,
        scannedPaperUrls,
        percentage: a.total > 0 ? ((a.score / a.total) * 100).toFixed(2) : "0.00",
        detailedAnswers
      };
    });

    return res.status(200).json({
      quiz: { id: quiz._id, title: quiz.title, course: quiz.course?.title, totalMarks: quiz.totalMarks },
      results
    });
  } catch (error) {
    return res.status(500).json({ message: "Failed to fetch quiz results", error: error.message });
  }
};

// ================================
// ATTEMPT QUIZ
// ================================
exports.attemptQuiz = async (req, res) => {
  try {
    const quiz = await Quiz.findById(req.params.id);
    if (!quiz) return res.status(404).json({ message: "Quiz not found" });

    const existingAttempt = await Attempt.findOne({ student: req.user._id, quiz: quiz._id });
    if (existingAttempt) return res.status(400).json({ message: "You already attempted this quiz" });

    const answers = req.body.answers || [];
    let score = 0;

    const review = (quiz.questions || []).map((q, index) => {
      const raw = answers[index];
      const selected = raw && raw.selectedAnswer && raw.selectedAnswer.trim() !== "" ? raw.selectedAnswer : null;
      const isCorrect = selected === q.correctAnswer;
      if (isCorrect) score++;
      return { question: q.question, selectedAnswer: selected, correctAnswer: q.correctAnswer, isCorrect: !selected ? false : isCorrect, skipped: !selected };
    });

    const attempt = await Attempt.create({ student: req.user._id, quiz: quiz._id, answers: review.map(r => ({ selectedAnswer: r.selectedAnswer || "" })), score });
    return res.status(200).json({ message: "Quiz attempted successfully", score, total: (quiz.questions || []).length, review });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

// ================================
// DELETE & UPDATE QUIZ
// ================================
exports.deleteQuiz = async (req, res) => {
  try {
    const quiz = await Quiz.findOne({ _id: req.params.id, teacher: req.user._id });
    if (!quiz) return res.status(404).json({ message: "Quiz not found" });
    await quiz.deleteOne();
    res.json({ message: "Quiz deleted successfully" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updateQuiz = async (req, res) => {
  try {
    const quiz = await Quiz.findOne({ _id: req.params.id, teacher: req.user._id });
    if (!quiz) return res.status(404).json({ message: "Quiz not found" });

    if (req.body.title) quiz.title = req.body.title;
    if (req.body.questions) quiz.questions = req.body.questions;
    if (req.body.shortQuestions) quiz.shortQuestions = req.body.shortQuestions;
    if (req.body.longQuestions) quiz.longQuestions = req.body.longQuestions;

    let total = 0;
    if (quiz.type === "mcq") total = (quiz.questions || []).reduce((sum, q) => sum + (q.marks || 1), 0);
    else total += (quiz.shortQuestions || []).reduce((sum, q) => sum + (q.marks || 0), 0) + (quiz.longQuestions || []).reduce((sum, q) => sum + (q.marks || 0), 0);

    quiz.totalMarks = total;
    await quiz.save();
    res.json({ message: "Quiz updated successfully", quiz });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// =========================================================
// 🔥 VISION-BASED AI QUIZ SCANNING
// =========================================================
exports.scanAIQuizMarks = async (req, res) => {
  try {
    const { courseId, studentId, quizId } = req.body;
    if (!courseId || !studentId || !quizId) return res.status(400).json({ message: "courseId, studentId, and quizId are required" });
    if (!req.files || req.files.length === 0) return res.status(400).json({ message: "Answer sheet images required" });

    const course = await Course.findById(courseId);
    if (!course) return res.status(404).json({ message: "Course not found" });

    const originalQuiz = await Quiz.findById(quizId);
    if (!originalQuiz) return res.status(404).json({ message: "Original Quiz not found" });

    const images = [];
    const savedFileNames = [];

    for (const file of req.files) {
      const fileName = `optimized-${file.filename}.jpg`;
      const optimizedPath = path.join(__dirname, `../uploads/${fileName}`);

      await sharp(file.path).rotate().resize({ width: 1200, withoutEnlargement: true }).jpeg({ quality: 70 }).toFile(optimizedPath);

      savedFileNames.push(fileName);
      const imageBuffer = fs.readFileSync(optimizedPath);
      images.push(imageBuffer.toString("base64"));
    }

    const visionPrompt = `You are a strict University Examiner. Analyze the handwritten text in the image. Evaluate fairly out of total marks: ${originalQuiz.totalMarks}.
Return STRICT JSON ONLY:
{
  "evaluation": { "total_max_marks": ${originalQuiz.totalMarks}, "total_obtained_marks": 5, "overall_feedback": "Short summary" },
  "detailedAnswers": [ { "question_text": "Q1", "student_answer": "Answer from image", "correct_answer": "Expected answer", "obtained_marks": 5, "isCorrect": true } ]
}`;

    const aiData = await callAI({ prompt: visionPrompt, images });

    if (!aiData || (!aiData.evaluation && !aiData.detailedAnswers)) {
      return res.status(500).json({ message: "Invalid AI response from Vision Model" });
    }

    let score = Number(aiData.evaluation?.total_obtained_marks || aiData.evaluation?.score) || 0;
    let totalMarks = Number(aiData.evaluation?.total_max_marks || aiData.evaluation?.totalMarks) || originalQuiz.totalMarks;
    score = Math.max(0, Math.min(score, totalMarks));

    originalQuiz.isAIScanned = true;
    await originalQuiz.save();

    let attempt = await Attempt.findOne({ student: studentId, quiz: quizId });
    if (attempt) {
      attempt.answers = aiData.detailedAnswers || [];
      attempt.score = score;
      attempt.total = totalMarks;
      attempt.evaluatedByAI = true;
      attempt.scannedPaper = savedFileNames;
      await attempt.save();
    } else {
      attempt = await Attempt.create({
        student: studentId, quiz: quizId, answers: aiData.detailedAnswers || [],
        score, total: totalMarks, evaluatedByAI: true, scannedPaper: savedFileNames,
      });
    }

    for (const file of req.files) {
      if (fs.existsSync(file.path)) fs.unlinkSync(file.path);
    }

    return res.status(200).json({ message: "AI Scanning Complete", evaluation: { score, totalMarks } });
  } catch (error) {
    console.log("❌ VISION SCAN ERROR:", error.message);
    return res.status(500).json({ message: "Vision scan failed", error: error.message });
  }
};

// =========================================================
// 🔥 MANUAL MARKS OVERRIDE (TEACHER CONTROL)
// =========================================================
exports.updateManualMarks = async (req, res) => {
  try {
    const { attemptId } = req.params;
    const { manualScore } = req.body;

    if (manualScore === undefined) return res.status(400).json({ message: "Manual score is required" });

    const attempt = await Attempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ message: "Attempt not found" });

    attempt.score = Number(manualScore);
    await attempt.save();

    return res.status(200).json({ message: "Marks updated manually successfully!", score: attempt.score });
  } catch (error) {
    return res.status(500).json({ message: "Failed to update marks", error: error.message });
  }
};

// =========================================
// RESTORED FALLBACKS FOR AI ROUTING
// =========================================
exports.createAIMCQQuiz = async (req, res) => {
  return res.status(200).json({ message: "Use the new AI MCQ route" });
};

exports.createAIQuestionQuiz = async (req, res) => {
  return res.status(200).json({ message: "Use the new AI Question route" });
};

exports.generateAIQuestionQuizPDF = async (req, res) => {
  try {
    const { quizId } = req.params;
    if (!quizId) return res.status(400).json({ message: "quizId is required" });

    const quiz = await Quiz.findById(quizId).populate("course", "title");
    if (!quiz) return res.status(404).json({ message: "Quiz not found" });

    const hasShort = quiz.shortQuestions && quiz.shortQuestions.length > 0;
    const hasLong = quiz.longQuestions && quiz.longQuestions.length > 0;

    const pdfData = {
      title: quiz.title,
      description: `Course: ${quiz.course?.title}`,
      shortQuestions: hasShort ? quiz.shortQuestions : [],
      longQuestions: hasLong ? quiz.longQuestions : [],
      hasShort,
      hasLong,
      totalMarks: quiz.totalMarks,
      grandTotalMarks: quiz.totalMarks,
    };

    const fileName = `ai-question-${Date.now()}.pdf`;
    const filePath = path.join(__dirname, `../uploads/${fileName}`);
    await generateQuizPDF(pdfData, filePath);
    const pdfUrl = `${req.protocol}://${req.get("host")}/uploads/${fileName}`;

    return res.status(200).json({ message: "PDF generated successfully", pdfUrl });
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
};