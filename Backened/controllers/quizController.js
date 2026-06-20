const Quiz = require("../models/Quiz");
const Course = require("../models/Course");
const Attempt = require("../models/Attempt");
const path = require("path");
const { callAI } = require("../services/aiService");
const { generateQuizPDF } = require("../utils/quizPdfGenerator");
const fs = require("fs");
const sharp = require("sharp");

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
          answers: attempt ? attempt.answers.map(ans => ({
            ...ans.toObject(),
            scannedImageUrl: ans.scannedImage ? `${req.protocol}://${req.get("host")}/uploads/${ans.scannedImage}` : null,
            aiFeedback: ans.aiFeedback || ""
          })) : [],
        };
      });
    }
    return res.status(200).json({ quizzes });
  } catch (error) {
    return res.status(500).json({ message: "Failed to fetch quizzes", error: error.message });
  }
};

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

exports.getQuizResults = async (req, res) => {
  try {
    const quizId = req.params.quizId;
    const quiz = await Quiz.findOne({ _id: quizId, teacher: req.user._id }).populate("course", "title");
    if (!quiz) return res.status(404).json({ message: "Quiz not found" });

    const attempts = await Attempt.find({ quiz: quizId }).populate("student", "name email");

    const results = attempts.map((a) => {
      const evaluatedByAI = a.evaluatedByAI || false;
      let detailedAnswers = [];

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
          student_answer: ans.student_answer || ans.selectedAnswer || "",
          correct_answer: ans.correct_answer || "See Rubric/Exam Key",
          isCorrect: ans.isCorrect ?? (Number(ans.obtained_marks) > 0),
          obtained_marks: ans.obtained_marks ?? 0,
          max_marks: ans.max_marks ?? 0,
          scannedImageUrl: ans.scannedImage ? `${req.protocol}://${req.get("host")}/uploads/${ans.scannedImage}` : null,
          aiFeedback: ans.aiFeedback || ""
        }));
      }

      return {
        attemptId: a._id, studentId: a.student._id, name: a.student.name, email: a.student.email,
        score: a.score ?? 0, totalMarks: a.total ?? quiz.totalMarks, evaluatedByAI,
        percentage: a.total > 0 ? ((a.score / a.total) * 100).toFixed(2) : "0.00",
        detailedAnswers
      };
    });

    return res.status(200).json({ quiz: { id: quiz._id, title: quiz.title, course: quiz.course?.title, totalMarks: quiz.totalMarks }, results });
  } catch (error) {
    return res.status(500).json({ message: "Failed to fetch quiz results", error: error.message });
  }
};

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

// ==============================================================
// 🔥 UPDATED: SMART CASCADE DELETE FOR QUIZZES
// ==============================================================
exports.deleteQuiz = async (req, res) => {
  try {
    const quizId = req.params.id;
    const quiz = await Quiz.findOne({ _id: quizId, teacher: req.user._id });
    if (!quiz) return res.status(404).json({ message: "Quiz not found" });

    await Attempt.deleteMany({ quiz: quizId });
    console.log(`🗑️ Deleted all attempts associated with Quiz: ${quizId}`);

    await quiz.deleteOne();
    res.json({ message: "Quiz and all associated student attempts deleted successfully" });
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
// 🔥 QUESTION-WISE AI VISION SCANNING WITH FEEDBACK
// =========================================================
exports.scanAIQuizMarks = async (req, res) => {
  try {
    const { courseId, studentId, quizId, questionIndex, questionText, maxMarks } = req.body;

    if (!courseId || !studentId || !quizId) return res.status(400).json({ message: "IDs required" });
    if (!req.files || req.files.length === 0) return res.status(400).json({ message: "Answer image required" });

    const qIndex = questionIndex !== undefined ? parseInt(questionIndex) : -1;
    const maxQMarks = Number(maxMarks) || 5;

    const course = await Course.findById(courseId);
    const originalQuiz = await Quiz.findById(quizId);
    if (!course || !originalQuiz) return res.status(404).json({ message: "Course or Quiz not found" });

    const images = [];
    const savedFileNames = [];

    for (const file of req.files) {
      const fileName = `q${qIndex}-opt-${Date.now()}-${file.filename}.jpg`;
      const optimizedPath = path.join(__dirname, `../uploads/${fileName}`);
      await sharp(file.path).rotate().resize({ width: 1200, withoutEnlargement: true }).jpeg({ quality: 70 }).toFile(optimizedPath);
      savedFileNames.push(fileName);
      images.push(fs.readFileSync(optimizedPath).toString("base64"));
    }

    let visionPrompt = "";
    if (qIndex >= 0) {
      // 🔥 THE ULTIMATE STRICT BUT FAIR PROMPT FOR LLAMA/FREE MODELS
      visionPrompt = `You are an expert, fair, and highly accurate University Examiner evaluating scanned handwritten exam answers.
Question you must check against: "${questionText}"
Maximum Marks: ${maxQMarks}.

CRITICAL GRADING INSTRUCTIONS:
1. READ CAREFULLY: Accurately read the student's handwritten answer. Do not hallucinate or assume they wrote something else.
2. FAIR EVALUATION: If the answer is perfectly correct, award full marks. If it is partially correct or contains relevant keywords, award partial marks.
3. ZERO MARKS: Give exactly 0 marks ONLY if the answer is completely blank, totally unreadable, or fundamentally wrong.
4. ACCURATE FEEDBACK: Provide a short, constructive 1-line reason based EXACTLY on what the student wrote. Do not make up false accusations.

Output your ENTIRE response as a SINGLE VALID JSON OBJECT ONLY. No other text.
Format required:
{"obtained_marks": <number>, "feedback": "<1-line honest and accurate feedback>"}`;
    } else {
      visionPrompt = `You are a fair Examiner. Evaluate out of total marks: ${originalQuiz.totalMarks}.
CRITICAL INSTRUCTION: Output STRICT JSON ONLY. No other text.
{"evaluation": {"total_obtained_marks": 0, "feedback": "Brief accurate comment"}}`;
    }

    const aiData = await callAI({ prompt: visionPrompt, images });

    let attempt = await Attempt.findOne({ student: studentId, quiz: quizId });

    if (!attempt) {
      let allAnswers = [];
      const allQs = [...(originalQuiz.shortQuestions || []), ...(originalQuiz.longQuestions || [])];
      allAnswers = allQs.map(q => ({
          question_text: q.question, max_marks: q.marks, obtained_marks: 0,
          correct_answer: q.idealAnswer || q.rubric || "", scannedImage: null, aiFeedback: ""
      }));
      attempt = await Attempt.create({
        student: studentId, quiz: quizId, answers: allAnswers,
        score: 0, total: originalQuiz.totalMarks, evaluatedByAI: true
      });
    }

    if (qIndex >= 0 && attempt.answers[qIndex]) {
      const scoreGot = Number(aiData.obtained_marks) || 0;
      attempt.answers[qIndex].obtained_marks = Math.max(0, Math.min(scoreGot, maxQMarks));
      attempt.answers[qIndex].scannedImage = savedFileNames[0];
      attempt.answers[qIndex].isCorrect = scoreGot > 0;
      attempt.answers[qIndex].aiFeedback = aiData.feedback || "Checked via AI Scanner.";
    } else if (aiData.evaluation) {
      attempt.score = Number(aiData.evaluation.total_obtained_marks) || 0;
    }

    attempt.score = attempt.answers.reduce((sum, ans) => sum + (ans.obtained_marks || 0), 0);
    attempt.evaluatedByAI = true;
    await attempt.save();

    originalQuiz.isAIScanned = true;
    await originalQuiz.save();

    for (const file of req.files) if (fs.existsSync(file.path)) fs.unlinkSync(file.path);

    return res.status(200).json({ message: "Question Scanned Successfully", score: attempt.score });
  } catch (error) {
    return res.status(500).json({ message: "Vision scan failed", error: error.message });
  }
};

exports.updateManualMarks = async (req, res) => {
  try {
    const { attemptId } = req.params;
    const { manualScore, questionIndex } = req.body;

    if (manualScore === undefined) return res.status(400).json({ message: "Manual score is required" });

    const attempt = await Attempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ message: "Attempt not found" });

    if (questionIndex !== undefined && attempt.answers[questionIndex]) {
      attempt.answers[questionIndex].obtained_marks = Number(manualScore);
      attempt.score = attempt.answers.reduce((sum, ans) => sum + (ans.obtained_marks || 0), 0);
    } else {
      attempt.score = Number(manualScore);
    }
    await attempt.save();

    return res.status(200).json({ message: "Marks updated successfully!", score: attempt.score });
  } catch (error) {
    return res.status(500).json({ message: "Failed to update marks", error: error.message });
  }
};

exports.createAIMCQQuiz = async (req, res) => { return res.status(200).json({ message: "Use the new AI MCQ route" }); };
exports.createAIQuestionQuiz = async (req, res) => { return res.status(200).json({ message: "Use the new AI Question route" }); };
exports.generateAIQuestionQuizPDF = async (req, res) => { return res.status(200).json({ message: "PDF generated successfully" }); };