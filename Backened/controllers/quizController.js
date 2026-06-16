const Quiz = require("../models/Quiz");
const Course = require("../models/Course");
const Attempt = require("../models/Attempt");
const path = require("path");
const { callAI } = require("../services/aiService");
const { generateQuizPDF } = require("../utils/quizPdfGenerator");
const fs = require("fs");
const pdfParse = require("pdf-parse");
const sharp = require("sharp");

// ================================
// CREATE QUIZ (MANUAL)
// ================================
exports.createQuiz = async (req, res) => {
  try {
    const { title, type, questions, shortQuestions, longQuestions } = req.body;

    // 🔥 FIX 2: Flutter "course" bhej raha hai aur backend "courseId" maangta hai. Dono handle kar liye!
    const courseId = req.body.courseId || req.body.course;

    if (!courseId || !title || !type) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    const course = await Course.findOne({
      _id: courseId,
      teacher: req.user._id,
    });

    if (!course) {
      return res.status(404).json({ message: "Course not found" });
    }

    if (type === "mcq") {
      const totalMarks = questions.reduce((sum, q) => sum + (q.marks || 1), 0);
      const quiz = await Quiz.create({ course: courseId, teacher: req.user._id, title, type: "mcq", questions, totalMarks });
      return res.status(201).json({ message: "MCQ Quiz created successfully", quiz });
    }

    if (type === "question") {
      const shorts = shortQuestions || [];
      const longs = longQuestions || [];
      const totalMarks = [...shorts, ...longs].reduce((sum, q) => sum + (q.marks || 0), 0);
      const quiz = await Quiz.create({ course: courseId, teacher: req.user._id, title, type: "question", shortQuestions: shorts, longQuestions: longs, totalMarks });
      return res.status(201).json({ message: "Question Quiz created successfully", quiz });
    }

    if (type === "mixed") {
      const totalMarks = [...(questions || []), ...(shortQuestions || []), ...(longQuestions || [])].reduce((sum, q) => sum + (q.marks || 0), 0);
      const quiz = await Quiz.create({ course: courseId, teacher: req.user._id, title, type: "mixed", questions: questions || [], shortQuestions: shortQuestions || [], longQuestions: longQuestions || [], totalMarks });
      return res.status(201).json({ message: "Mixed Quiz created successfully", quiz });
    }

    return res.status(400).json({ message: "Invalid quiz type" });

  } catch (error) {
    console.log("CREATE QUIZ ERROR:", error);
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
    if (!quiz.type || quiz.type.toLowerCase() !== "question") return res.status(400).json({ message: "Only question type quizzes can generate PDF" });

    const pdfData = {
      title: title || quiz.title,
      shortQuestions: quiz.shortQuestions || [],
      longQuestions: quiz.longQuestions || [],
      totalMarks: quiz.totalMarks || 0,
      grandTotalMarks: quiz.totalMarks || 0,
    };

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
      quizzes = data.map(q => ({ ...q.toObject(), isCompleted: false, score: null, total: q.questions.length, answers: [] }));
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
          total: q.type === "mcq" ? q.questions.length : (q.shortQuestions?.length || 0) + (q.longQuestions?.length || 0),
          answers: attempt ? attempt.answers : [],
        };
      });
    }

    // 🔥 FIX 3: Flutter expects { quizzes: [...] }, so we wrap it in an object!
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
    }

    if (req.user.role === "student") {
      quizzes = await Quiz.find({ course: req.params.courseId }).populate("teacher", "name email");
    }

    // 🔥 FIX 3: Flutter expects { quizzes: [...] } here too!
    res.json({ quizzes });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// =======================================
// GET QUIZ RESULTS (TEACHER VIEW)
// =======================================
exports.getQuizResults = async (req, res) => {
  try {
    const quizId = req.params.quizId;
    const quiz = await Quiz.findOne({ _id: quizId, teacher: req.user._id }).populate("course", "title");

    if (!quiz) return res.status(404).json({ message: "Quiz not found" });

    const attempts = await Attempt.find({ quiz: quizId }).populate("student", "name email");
    const results = attempts.map((a) => {
      const evaluatedByAI = a.evaluatedByAI || false;
      return {
        studentId: a.student._id, name: a.student.name, email: a.student.email,
        score: a.score ?? 0, totalMarks: a.total ?? quiz.totalMarks, evaluatedByAI,
        percentage: a.total > 0 ? ((a.score / a.total) * 100).toFixed(2) : "0.00",
      };
    });

    return res.status(200).json({ quiz: { id: quiz._id, title: quiz.title, course: quiz.course?.title, totalMarks: quiz.totalMarks }, results });
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

    const review = quiz.questions.map((q, index) => {
      const raw = answers[index];
      const selected = raw && raw.selectedAnswer && raw.selectedAnswer.trim() !== "" ? raw.selectedAnswer : null;
      const isSkipped = !selected;
      const isCorrect = selected === q.correctAnswer;
      if (isCorrect) score++;
      return { question: q.question, selectedAnswer: selected, correctAnswer: q.correctAnswer, isCorrect: isSkipped ? false : isCorrect, skipped: isSkipped };
    });

    const attempt = await Attempt.create({ student: req.user._id, quiz: quiz._id, answers: review.map(r => ({ selectedAnswer: r.selectedAnswer || "" })), score });
    return res.status(200).json({ message: "Quiz attempted successfully", score, total: quiz.questions.length, review });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

// ================================
// DELETE QUIZ
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
// ================================
// UPDATE QUIZ (Yeh miss ho gaya tha)
// ================================
exports.updateQuiz = async (req, res) => {
  try {
    const quiz = await Quiz.findOne({
      _id: req.params.id,
      teacher: req.user._id,
    });

    if (!quiz) {
      return res.status(404).json({ message: "Quiz not found" });
    }

    quiz.title = req.body.title || quiz.title;
    quiz.questions = req.body.questions || quiz.questions;

    await quiz.save();

    res.json({
      message: "Quiz updated successfully",
      quiz,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
// =========================================
// 🔥 VISION-BASED AI QUIZ SCANNING (MISSING FUNCTION RESTORED)
// =========================================
exports.scanAIQuizMarks = async (req, res) => {
  try {
    const { courseId, studentId, title } = req.body;

    if (!courseId || !studentId || !title) {
      return res.status(400).json({
        message: "courseId, studentId and title required",
      });
    }

    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        message: "Answer sheet images required",
      });
    }

    const course = await Course.findById(courseId);
    if (!course) {
      return res.status(404).json({ message: "Course not found" });
    }

    const images = [];
    for (const file of req.files) {
      const optimizedPath = path.join(__dirname, `../uploads/optimized-${file.filename}.jpg`);
      await sharp(file.path)
        .rotate()
        .resize({ width: 1800, withoutEnlargement: true })
        .jpeg({ quality: 80 })
        .toFile(optimizedPath);

      const imageBuffer = fs.readFileSync(optimizedPath);
      images.push(imageBuffer.toString("base64"));
    }

    const visionPrompt = `You are an expert university paper checker. Return ONLY valid JSON format with "questions" array and "evaluation" object. Evaluate marks fairly.`;

    const aiData = await callAI({ prompt: visionPrompt, images });

    if (!aiData || !aiData.evaluation) {
      return res.status(500).json({ message: "Invalid AI response" });
    }

    let score = Number(aiData.evaluation.score) || 0;
    let totalMarks = Number(aiData.evaluation.totalMarks) || 0;
    score = Math.max(0, Math.min(score, totalMarks));
    const percentage = totalMarks > 0 ? ((score / totalMarks) * 100).toFixed(2) : 0;

    const quiz = await Quiz.create({
      course: courseId, teacher: req.user._id, title, type: "question", shortQuestions: [], longQuestions: [], totalMarks, isAIScanned: true,
      examMeta: { generatedBy: "AI_VISION", scanType: "HANDWRITING_ANALYSIS", pages: req.files.length, scannedAt: new Date() },
    });

    const attempt = await Attempt.create({
      student: studentId, quiz: quiz._id, answers: aiData.questions || [], score, total: totalMarks, evaluatedByAI: true, scannedPaper: req.files.map((f) => f.filename).join(","),
    });

    for (const file of req.files) {
      const optimizedPath = path.join(__dirname, `../uploads/optimized-${file.filename}.jpg`);
      if (fs.existsSync(optimizedPath)) fs.unlinkSync(optimizedPath);
    }

    return res.status(200).json({ message: "AI answer sheet scanning completed successfully", quiz, attempt, evaluation: { score, totalMarks, percentage } });

  } catch (error) {
    console.log("❌ VISION SCAN ERROR:", error);
    return res.status(500).json({ message: "Vision scan failed", error: error.message });
  }
};
// =======================================
// RESTORED MISSING FUNCTIONS (TO PREVENT ROUTE CRASH)
// =======================================

exports.createAIMCQQuiz = async (req, res) => {
  try {
    return res.status(200).json({ message: "Use the new AI MCQ route" });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

exports.createAIQuestionQuiz = async (req, res) => {
  try {
    return res.status(200).json({ message: "Use the new AI Question route" });
  } catch (error) {
    return res.status(500).json({ error: error.message });
  }
};

// =========================================
// GENERATE AI QUESTION QUIZ PDF (ORIGINAL)
// =========================================
exports.generateAIQuestionQuizPDF = async (req, res) => {
  try {
    const { quizId } = req.params;

    if (!quizId) {
      return res.status(400).json({ message: "quizId is required" });
    }

    const quiz = await Quiz.findById(quizId).populate("course", "title");

    if (!quiz) {
      return res.status(404).json({ message: "Quiz not found" });
    }

    if (req.user.role === "teacher") {
      if (quiz.teacher.toString() !== req.user._id.toString()) {
        return res.status(403).json({ message: "Access denied" });
      }
    }

    if (req.user.role === "student") {
      const enrolled = await Course.findOne({
        _id: quiz.course._id,
        "students.user": req.user._id,
      });

      if (!enrolled) {
        return res.status(403).json({ message: "Access denied" });
      }
    }

    const hasShort = quiz.shortQuestions && quiz.shortQuestions.length > 0;
    const hasLong = quiz.longQuestions && quiz.longQuestions.length > 0;

    if (!hasShort && !hasLong) {
      return res.status(400).json({ message: "No questions available in quiz" });
    }

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

    return res.status(200).json({
      message: "PDF generated successfully",
      pdfUrl,
      type: {
        short: hasShort,
        long: hasLong,
        mode: hasShort && hasLong ? "BOTH" : hasShort ? "SHORT_ONLY" : "LONG_ONLY",
      },
    });

  } catch (error) {
    console.log("AI PDF ERROR:", error);
    return res.status(500).json({ message: error.message });
  }
};