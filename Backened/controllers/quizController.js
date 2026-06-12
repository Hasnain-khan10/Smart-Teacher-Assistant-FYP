const Quiz = require("../models/Quiz");
const Course = require("../models/Course");
const Attempt = require("../models/Attempt");
const path = require("path");
const { callAI } = require("../services/aiService");
const { generateQuizPDF } = require("../utils/quizPdfGenerator");
const PDFDocument = require("pdfkit");
const fs = require("fs");
const pdfParse = require("pdf-parse");
const Tesseract = require("tesseract.js");
const sharp = require("sharp");


// ================================
// CREATE QUIZ
// ================================
exports.createQuiz = async (req, res) => {
  try {
    const {
      courseId,
      title,
      type,

      // MCQ
      questions,

      // QUESTION
      shortQuestions,
      longQuestions,
    } = req.body;


    // ================================
    // VALIDATION
    // ================================
    if (!courseId || !title || !type) {
      return res.status(400).json({
        message: "Missing required fields",
      });
    }
    

    const course = await Course.findOne({
      _id: courseId,
      teacher: req.user._id,
    });

    if (!course) {
      return res.status(404).json({
        message: "Course not found",
      });
    }

    // =========================================================
    // MCQ QUIZ
    // =========================================================
    if (type === "mcq") {
      if (!questions || !Array.isArray(questions)) {
        return res.status(400).json({
          message: "MCQ questions are required",
        });
      }

      const totalMarks = questions.reduce(
        (sum, q) => sum + (q.marks || 1),
        0
      );

      const quiz = await Quiz.create({
        course: courseId,
        teacher: req.user._id,
        title,
        type: "mcq",
        questions,
        totalMarks,
      });

      return res.status(201).json({
        message: "MCQ Quiz created successfully",
        quiz,
      });
    }

    // =========================================================
    // QUESTION QUIZ
    // =========================================================
    if (type === "question") {
      const shorts = shortQuestions || [];
      const longs = longQuestions || [];

      const totalMarks = [...shorts, ...longs].reduce(
        (sum, q) => sum + (q.marks || 0),
        0
      );

      const quiz = await Quiz.create({
        course: courseId,
        teacher: req.user._id,
        title,
        type: "question",

        shortQuestions: shorts,
        longQuestions: longs,

        totalMarks,
      });

      return res.status(201).json({
        message: "Question Quiz created successfully",
        quiz,
      });
    }

    // =========================================================
    // MIXED QUIZ
    // =========================================================
    if (type === "mixed") {
      const totalMarks = [
        ...(questions || []),
        ...(shortQuestions || []),
        ...(longQuestions || []),
      ].reduce((sum, q) => sum + (q.marks || 0), 0);

      const quiz = await Quiz.create({
        course: courseId,
        teacher: req.user._id,
        title,
        type: "mixed",

        questions: questions || [],
        shortQuestions: shortQuestions || [],
        longQuestions: longQuestions || [],

        totalMarks,
      });

      return res.status(201).json({
        message: "Mixed Quiz created successfully",
        quiz,
      });
    }

    return res.status(400).json({
      message: "Invalid quiz type",
    });

  } catch (error) {
    console.log("CREATE QUIZ ERROR:", error);

    return res.status(500).json({
      message: "Failed to create quiz",
      error: error.message,
    });
  }
};


// ================================
// GENERATE QUESTION QUIZ PDF (COURSE BASED FIX)
// ================================
exports.generateQuestionQuizPDF = async (req, res) => {
  try {
    const { courseId, title } = req.query;

    // ============================
    // FIND QUIZ
    // ============================
    const quiz = await Quiz.findById(req.params.id)
      .populate("course", "title");

    if (!quiz) {
      return res.status(404).json({
        message: "Quiz not found",
      });
    }

    // ============================
    // ONLY QUESTION QUIZ ALLOWED
    // ============================
    if (
      !quiz.type ||
      quiz.type.toLowerCase() !== "question"
    ) {
      return res.status(400).json({
        message:
          "Only question type quizzes can generate PDF",
      });
    }

    // ============================
    // VALIDATE COURSE CONTEXT
    // ============================
    if (
      courseId &&
      quiz.course._id.toString() !== courseId
    ) {
      return res.status(403).json({
        message:
          "Quiz does not belong to this course",
      });
    }

    // ============================
    // TEACHER ACCESS CHECK
    // ============================
    if (req.user.role === "teacher") {
      if (
        quiz.teacher.toString() !==
        req.user._id.toString()
      ) {
        return res.status(403).json({
          message: "Access denied",
        });
      }
    }

    // ============================
    // STUDENT ACCESS CHECK
    // ============================
    if (req.user.role === "student") {
      const enrolled = await Course.findOne({
        _id: quiz.course._id,
        "students.user": req.user._id,
      });

      if (!enrolled) {
        return res.status(403).json({
          message: "Access denied",
        });
      }
    }

    // ============================
    // PDF DATA
    // ============================
    const pdfData = {
      title: title || quiz.title,

      // description: `Course: ${
      //   quiz.course?.title || ""
      // }`,

      shortQuestions:
          quiz.shortQuestions || [],

      longQuestions:
          quiz.longQuestions || [],

      totalMarks:
          quiz.totalMarks || 0,

      grandTotalMarks:
          quiz.totalMarks || 0,
    };

    // ============================
    // GENERATE FILE
    // ============================
    const fileName =
        `question-quiz-${Date.now()}.pdf`;

    const filePath = path.join(
      __dirname,
      `../uploads/${fileName}`
    );

    await generateQuizPDF(
      pdfData,
      filePath
    );

    const pdfUrl =
        `${req.protocol}://${req.get("host")}/uploads/${fileName}`;

    return res.status(200).json({
      message:
          "Question quiz PDF generated successfully",

      pdfUrl,
    });

  } catch (error) {

    console.log(
      "GENERATE QUESTION PDF ERROR:",
      error
    );

    return res.status(500).json({
      message: "Failed to generate PDF",
      error: error.message,
    });
  }
};


// ================================
// GET ALL QUIZZES (FINAL FIX)
// ================================
exports.getAllQuizzes = async (req, res) => {
  try {
    let quizzes = [];

    // ================= TEACHER =================
    if (req.user.role === "teacher") {
      const data = await Quiz.find({
        teacher: req.user._id,
      }).populate("course", "title");

      quizzes = data.map(q => ({
        ...q.toObject(),
        isCompleted: false,
        score: null,
        total: q.questions.length,
        answers: [],
      }));
    }

    // ================= STUDENT =================
    if (req.user.role === "student") {

      // ✅ FIX: correct nested query (students.user)
      const courses = await Course.find({
        "students.user": req.user._id,
      }).select("_id");

      const courseIds = courses.map(c => c._id);

      if (courseIds.length === 0) {
        return res.status(200).json([]);
      }

      const quizzesData = await Quiz.find({
        course: { $in: courseIds },
      })
        .populate("course", "title")
        .populate("teacher", "name");

      const attempts = await Attempt.find({
        student: req.user._id,
        quiz: { $in: quizzesData.map(q => q._id) },
      });

      const attemptMap = {};
      attempts.forEach(a => {
        attemptMap[a.quiz.toString()] = a;
      });

      quizzes = quizzesData.map(q => {
        const attempt = attemptMap[q._id.toString()];

        return {
          ...q.toObject(),
          isCompleted: !!attempt,
        score: attempt ? attempt.score : null,

totalMarks: attempt
  ? attempt.total
  : q.totalMarks,

isAIScanned:
    q.isAIScanned || false,

evaluatedByAI:
    attempt?.evaluatedByAI || false,  

title: q.title,
  
          total:
  q.type === "mcq"
    ? q.questions.length
    : (q.shortQuestions?.length || 0) + (q.longQuestions?.length || 0),
          answers: attempt ? attempt.answers : [],
        };
      });
    }

    return res.status(200).json(quizzes);

  } catch (error) {
    console.error("GET ALL QUIZZES ERROR:", error);
    return res.status(500).json({
      message: "Failed to fetch quizzes",
      error: error.message,
    });
  }
};



// =======================================
// GET QUIZ RESULTS (TEACHER VIEW)
// =======================================
exports.getQuizResults = async (req, res) => {
  try {
    const quizId = req.params.quizId;

    const quiz = await Quiz.findOne({
      _id: quizId,
      teacher: req.user._id,
    }).populate("course", "title");

    if (!quiz) {
      return res.status(404).json({
        message: "Quiz not found",
      });
    }

    // Get all attempts for this quiz
    const attempts = await Attempt.find({
      quiz: quizId,
    }).populate("student", "name email");

    const results = attempts.map((a) => {
      const evaluatedByAI = a.evaluatedByAI || false;

      return {
        studentId: a.student._id,
        name: a.student.name,
        email: a.student.email,

        // IMPORTANT LOGIC (YOUR REQUIREMENT)
        score: a.score ?? 0,

        totalMarks: a.total ?? quiz.totalMarks,

        evaluatedByAI,

        percentage:
          a.total > 0
            ? ((a.score / a.total) * 100).toFixed(2)
            : "0.00",
      };
    });

    return res.status(200).json({
      quiz: {
        id: quiz._id,
        title: quiz.title,
        course: quiz.course?.title,
        totalMarks: quiz.totalMarks,
      },
      results,
    });
  } catch (error) {
    console.log("GET QUIZ RESULTS ERROR:", error);
    return res.status(500).json({
      message: "Failed to fetch quiz results",
      error: error.message,
    });
  }
};



// ================================
// GET QUIZZES BY COURSE
// ================================
exports.getQuizzesByCourse = async (req, res) => {
  try {
    let quizzes;

    if (req.user.role === "teacher") {
      quizzes = await Quiz.find({
        course: req.params.courseId,
        teacher: req.user._id,
      });
    }

    if (req.user.role === "student") {
      quizzes = await Quiz.find({
        course: req.params.courseId,
      }).populate("teacher", "name email");
    }

    res.json(quizzes);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};


// ================================
// ATTEMPT QUIZ (🔥 FULL FIX)
// ================================
exports.attemptQuiz = async (req, res) => {
  try {
    const quiz = await Quiz.findById(req.params.id);

    if (!quiz) {
      return res.status(404).json({ message: "Quiz not found" });
    }

    const existingAttempt = await Attempt.findOne({
      student: req.user._id,
      quiz: quiz._id,
    });

    if (existingAttempt) {
      return res.status(400).json({
        message: "You already attempted this quiz",
      });
    }

    const answers = req.body.answers || [];

    let score = 0;

    const review = quiz.questions.map((q, index) => {
      const raw = answers[index];

      const selected =
        raw && raw.selectedAnswer && raw.selectedAnswer.trim() !== ""
          ? raw.selectedAnswer
          : null;

      const isSkipped = !selected;
      const isCorrect = selected === q.correctAnswer;

      if (isCorrect) score++;

      return {
        question: q.question,
        selectedAnswer: selected,
        correctAnswer: q.correctAnswer,
        isCorrect: isSkipped ? false : isCorrect,
        skipped: isSkipped, 
      };
    });

    const attempt = await Attempt.create({
      student: req.user._id,
      quiz: quiz._id,
      answers: review.map(r => ({
        selectedAnswer: r.selectedAnswer || "",
      })),
      score,
    });

    return res.status(200).json({
      message: "Quiz attempted successfully",
      score,
      total: quiz.questions.length,
      review,
    });
  } catch (error) {
    console.error("ATTEMPT QUIZ ERROR:", error);
    return res.status(500).json({ error: error.message });
  }
};



// =========================================
// 🔥 VISION-BASED AI QUIZ SCANNING (FINAL)
// =========================================

exports.scanAIQuizMarks = async (req, res) => {
  try {
    const { courseId, studentId, title } = req.body;

    // =====================================
    // VALIDATION
    // =====================================
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

    // =====================================
    // VERIFY COURSE
    // =====================================
    const course = await Course.findById(courseId);

    if (!course) {
      return res.status(404).json({
        message: "Course not found",
      });
    }

    // =====================================
    // PROCESS IMAGES
    // =====================================
    const images = [];

    for (const file of req.files) {
      console.log("📄 PROCESSING PAGE =>", file.filename);

      const optimizedPath = path.join(
        __dirname,
        `../uploads/optimized-${file.filename}.jpg`
      );

      // =====================================
      // IMAGE OPTIMIZATION
      // =====================================
      await sharp(file.path)
        .rotate()
        .resize({
          width: 1800,
          withoutEnlargement: true,
        })
        .jpeg({
          quality: 80,
        })
        .toFile(optimizedPath);

      const imageBuffer = fs.readFileSync(optimizedPath);

      const base64Image =
        imageBuffer.toString("base64");

      images.push(base64Image);
    }

    // =====================================
    // AI PROMPT
    // =====================================
    const visionPrompt = `
You are an expert university paper checker.

You are analyzing handwritten student answer sheets.

TASK:
- Read handwriting carefully
- Detect questions and answers
- Evaluate answers fairly
- Give marks question-wise
- Be strict but reasonable
- Ignore cuttings and noise
- Understand diagrams if present

IMPORTANT:
- Return ONLY valid JSON
- No markdown
- No explanation text
- No extra words

JSON FORMAT:

{
  "questions": [
    {
      "question": "",
      "studentAnswer": "",
      "obtainedMarks": 0,
      "totalMarks": 0,
      "feedback": ""
    }
  ],
  "evaluation": {
    "score": 0,
    "totalMarks": 0,
    "percentage": 0
  }
}

SCORING RULES:
- Correct answer = full marks
- Partial answer = partial marks
- Weak answer = low marks
- Wrong answer = 0

Use ONLY visible content from answer sheets.
`;

    // =====================================
    // AI CALL (VISION)
    // =====================================
    const aiData = await callAI({
      prompt: visionPrompt,
      images,
    });

    // =====================================
    // VALIDATE AI RESPONSE
    // =====================================
    if (
      !aiData ||
      !aiData.evaluation
    ) {
      return res.status(500).json({
        message: "Invalid AI response",
      });
    }

    // =====================================
    // SAFE SCORE EXTRACTION
    // =====================================
    let score =
      Number(aiData.evaluation.score) || 0;

    let totalMarks =
      Number(aiData.evaluation.totalMarks) || 0;

    score = Math.max(
      0,
      Math.min(score, totalMarks)
    );

    const percentage =
      totalMarks > 0
        ? ((score / totalMarks) * 100).toFixed(2)
        : 0;

    // =====================================
    // CREATE QUIZ
    // =====================================
    const quiz = await Quiz.create({
      course: courseId,

      teacher: req.user._id,

      title,

      type: "question",

      shortQuestions: [],

      longQuestions: [],

      totalMarks,

      isAIScanned: true,

      examMeta: {
        generatedBy: "AI_VISION",

        scanType: "HANDWRITING_ANALYSIS",

        pages: req.files.length,

        scannedAt: new Date(),
      },
    });

    // =====================================
    // CREATE ATTEMPT
    // =====================================
    const attempt = await Attempt.create({
      student: studentId,

      quiz: quiz._id,

      answers: aiData.questions || [],

      score,

      total: totalMarks,

      evaluatedByAI: true,

      scannedPaper: req.files
        .map((f) => f.filename)
        .join(","),
    });

    // =====================================
    // CLEANUP TEMP FILES
    // =====================================
    for (const file of req.files) {

      const optimizedPath = path.join(
        __dirname,
        `../uploads/optimized-${file.filename}.jpg`
      );

      if (fs.existsSync(optimizedPath)) {
        fs.unlinkSync(optimizedPath);
      }
    }

    // =====================================
    // SUCCESS RESPONSE
    // =====================================
    return res.status(200).json({
      message:
        "AI answer sheet scanning completed successfully",

      quiz,

      attempt,

      evaluation: {
        score,
        totalMarks,
        percentage,
      },
    });

  } catch (error) {

    console.log(
      "❌ VISION SCAN ERROR:",
      error
    );

    return res.status(500).json({
      message: "Vision scan failed",
      error: error.message,
    });
  }
};


// ================================
// UPDATE QUIZ
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


// ================================
// DELETE QUIZ
// ================================
exports.deleteQuiz = async (req, res) => {
  try {
    const quiz = await Quiz.findOne({
      _id: req.params.id,
      teacher: req.user._id,
    });

    if (!quiz) {
      return res.status(404).json({ message: "Quiz not found" });
    }

    await quiz.deleteOne();

    res.json({ message: "Quiz deleted successfully" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};



// =======================================
// CREATE AI MCQ QUIZ FROM PDF / IMAGE (FIXED + FULL SUPPORT)
// =======================================
exports.createAIMCQQuiz = async (req, res) => {
  try {

    const {
      courseId,
      prompt,
      difficulty,
      questionCount,
      marksPerQuestion,
    } = req.body;

    // =========================
    // VALIDATION
    // =========================
    if (!courseId || !prompt) {
      return res.status(400).json({
        message: "courseId and prompt are required",
      });
    }

    // =========================
    // VERIFY COURSE
    // =========================
    const course = await Course.findOne({
      _id: courseId,
      teacher: req.user._id,
    });

    if (!course) {
      return res.status(404).json({
        message: "Course not found",
      });
    }

    // =========================
    // FILE REQUIRED
    // =========================
    if (!req.file) {
      return res.status(400).json({
        message: "PDF or image is required",
      });
    }

    const count = Number(questionCount) || 10;
    const perMark = Number(marksPerQuestion) || 1;
    const totalMarks = count * perMark;

    // =========================
    // EXTRACT CONTENT
    // =========================
    let extractedText = "";
    let images = [];

    // =========================
    // PDF HANDLING
    // =========================
    if (req.file.mimetype === "application/pdf") {

      const dataBuffer = fs.readFileSync(req.file.path);

      const pdfData = await pdfParse(dataBuffer);

      extractedText = pdfData.text || "";
    }

    // =========================
    // IMAGE HANDLING (FIXED)
    // =========================
    else if (req.file.mimetype.startsWith("image/")) {

      extractedText = "Image uploaded by teacher.";

      // IMPORTANT FIX: must send real file path to AI
      images.push(req.file.path);
    }

    // =========================
    // LIMIT TEXT SIZE
    // =========================
    extractedText = extractedText.substring(0, 12000);

    // =========================
    // AI PROMPT
    // =========================
    const finalPrompt = `
You are an expert university MCQ generator.

Teacher Instruction:
${prompt}

Material Content:
${extractedText}

DIFFICULTY:
${difficulty || "medium"}

IMPORTANT RULES:
- Generate EXACTLY ${count} MCQs
- Each MCQ must contain:
  - question
  - options A/B/C/D
  - correctAnswer
- Questions MUST come from uploaded material
- NO explanations
- Return ONLY valid JSON

JSON FORMAT:

{
  "title": "",
  "description": "",
  "questions": [
    {
      "question": "",
      "options": {
        "A": "",
        "B": "",
        "C": "",
        "D": ""
      },
      "correctAnswer": "A"
    }
  ]
}
`;

    // =========================
    // AI CALL (FIXED: ALWAYS SEND IMAGES ARRAY)
    // =========================
    const aiResponse = await callAI({
      prompt: finalPrompt,
      images: images || [],   // 🔥 FIX: prevents "No images provided"
    });

    let aiData;

    try {
      aiData =
        typeof aiResponse === "string"
          ? JSON.parse(aiResponse)
          : aiResponse;

    } catch (err) {
      return res.status(500).json({
        message: "AI returned invalid JSON",
      });
    }

    // =========================
    // VALIDATION
    // =========================
    if (!aiData.questions || !Array.isArray(aiData.questions)) {
      return res.status(500).json({
        message: "Invalid AI quiz format",
      });
    }

    // =========================
    // FORMAT QUESTIONS
    // =========================
    const formattedQuestions = aiData.questions.map((q) => ({
      question: q.question,
      options: {
        A: q.options?.A || "",
        B: q.options?.B || "",
        C: q.options?.C || "",
        D: q.options?.D || "",
      },
      correctAnswer: q.correctAnswer,
      marks: perMark,
    }));

    // =========================
    // SAVE QUIZ
    // =========================
    const quiz = await Quiz.create({
      course: courseId,
      teacher: req.user._id,
      title: aiData.title || "AI Generated MCQ Quiz",
      description: aiData.description || "",
      type: "mcq",
      questions: formattedQuestions,
      totalMarks,
      marksPerQuestion: perMark,
      examMeta: {
        generatedBy: "AI",
        source: "PDF_OR_IMAGE",
        difficulty: difficulty || "medium",
        totalQuestions: count,
        uploadedFile: req.file.filename,
      },
    });

    // =========================
    // SUCCESS
    // =========================
    return res.status(201).json({
      message: "AI MCQ Quiz created successfully",
      quiz,
    });

  } catch (error) {
    console.log("CREATE AI MCQ QUIZ ERROR:", error);

    return res.status(500).json({
      message: "Failed to create AI MCQ Quiz",
      error: error.message,
    });
  }
};



// Generate AI Question Quiz 
// =======================================
// CREATE AI QUESTION QUIZ FROM PDF / IMAGE
// =======================================
exports.createAIQuestionQuiz = async (req, res) => {
  try {

    const {
      courseId,
      prompt,
      difficulty,

      shortCount,
      longCount,

      shortEachMark,
      longEachMark,

      type,
    } = req.body;

    // =========================
    // VALIDATION
    // =========================
    if (!courseId || !prompt) {
      return res.status(400).json({
        message:
          "courseId and prompt are required",
      });
    }

    // =========================
    // VERIFY COURSE
    // =========================
    const course = await Course.findOne({
      _id: courseId,
      teacher: req.user._id,
    });

    if (!course) {
      return res.status(404).json({
        message: "Course not found",
      });
    }

    // =========================
    // FILE REQUIRED
    // =========================
    if (!req.file) {
      return res.status(400).json({
        message: "PDF or image is required",
      });
    }

    const mode = type || "long";

    const sCount = Number(shortCount) || 0;
    const lCount = Number(longCount) || 10;

    const sEach = Number(shortEachMark) || 1;
    const lEach = Number(longEachMark) || 5;

    const sTotal = sCount * sEach;
    const lTotal = lCount * lEach;

    const grandTotal = sTotal + lTotal;

    // =====================================================
    // 🔥 ENHANCEMENT: SUPPORT PDF + IMAGE + PROMPT TOGETHER
    // =====================================================
    let extractedText = "";
    let images = [];

    // =========================
    // PDF HANDLING
    // =========================
    if (req.file.mimetype === "application/pdf") {

      const dataBuffer = fs.readFileSync(req.file.path);

      const pdfData = await pdfParse(dataBuffer);

      extractedText = pdfData.text || "";
    }

    // =========================
    // IMAGE HANDLING
    // =========================
    else if (req.file.mimetype.startsWith("image/")) {

      images.push(
        `${process.env.BASE_URL}/${req.file.path}`
      );

      extractedText = "Image uploaded by teacher.";
    }

    // =========================
    // LIMIT TEXT
    // =========================
    extractedText = extractedText.substring(0, 12000);

    // =========================
    // BUILD AI PROMPT (UNCHANGED)
    // =========================
    let finalPrompt = `
You are a strict university exam paper generator.

Teacher Instruction:
${prompt}

Study Material:
${extractedText}

DIFFICULTY:
${difficulty || "medium"}

IMPORTANT:
- Questions MUST come from uploaded material
- NO answers
- NO explanations
- Return ONLY valid JSON
`;

    // =========================
    // LONG QUESTIONS
    // =========================
    if (mode === "long") {

      finalPrompt += `

Generate EXACTLY ${lCount}
LONG questions.

Each question carries
${lEach} marks.

JSON FORMAT:

{
  "title": "",
  "description": "",
  "longQuestions": [
    {
      "question": "",
      "marks": ${lEach}
    }
  ]
}
`;
    }

    // =========================
    // SHORT QUESTIONS
    // =========================
    if (mode === "short") {

      finalPrompt += `

Generate EXACTLY ${sCount}
SHORT questions.

Each question carries
${sEach} marks.

JSON FORMAT:

{
  "title": "",
  "description": "",
  "shortQuestions": [
    {
      "question": "",
      "marks": ${sEach}
    }
  ]
}
`;
    }

    // =========================
    // BOTH
    // =========================
    if (mode === "both") {

      finalPrompt += `

Generate:
- EXACTLY ${sCount} SHORT questions
- EXACTLY ${lCount} LONG questions

SHORT QUESTION MARKS:
${sEach}

LONG QUESTION MARKS:
${lEach}

JSON FORMAT:

{
  "title": "",
  "description": "",

  "shortQuestions": [
    {
      "question": "",
      "marks": ${sEach}
    }
  ],

  "longQuestions": [
    {
      "question": "",
      "marks": ${lEach}
    }
  ]
}
`;
    }

    // =========================
    // AI CALL (🔥 NOW SUPPORTS IMAGE + TEXT)
    // =========================
    const aiResponse = await callAI({
      prompt: finalPrompt,
      images,   // 🔥 ADDED WITHOUT CHANGING YOUR LOGIC
    });

    let aiData;

    try {

      aiData =
        typeof aiResponse === "string"
          ? JSON.parse(aiResponse)
          : aiResponse;

    } catch (err) {

      return res.status(500).json({
        message:
          "AI returned invalid JSON",
      });
    }

    // =========================
    // SAVE QUIZ (UNCHANGED)
    // =========================
    const quiz = await Quiz.create({

      course: courseId,
      teacher: req.user._id,

      title:
        aiData.title ||
        "AI Generated Question Quiz",

      description:
        aiData.description || "",

      type: "question",

      shortQuestions:
        aiData.shortQuestions || [],

      longQuestions:
        aiData.longQuestions || [],

      totalMarks: grandTotal,

      examMeta: {

        generatedBy: "AI",

        source: "PDF_OR_IMAGE",

        difficulty:
          difficulty || "medium",

        uploadedFile:
          req.file.filename,
      },
    });

    // =========================
    // PDF DATA (UNCHANGED)
    // =========================
    const pdfData = {

      title: quiz.title,

      description:
        `Course: ${course.title}`,

      shortQuestions:
        quiz.shortQuestions,

      longQuestions:
        quiz.longQuestions,

      totalMarks:
        quiz.totalMarks,

      grandTotalMarks:
        quiz.totalMarks,
    };

    // =========================
    // GENERATE PDF (UNCHANGED)
    // =========================
    const fileName =
      `ai-question-${Date.now()}.pdf`;

    const filePath = path.join(
      __dirname,
      `../uploads/${fileName}`
    );

    await generateQuizPDF(
      pdfData,
      filePath
    );

    const pdfUrl =
      `${req.protocol}://${req.get("host")}/uploads/${fileName}`;

    // =========================
    // SUCCESS
    // =========================
    return res.status(201).json({

      message:
        "AI Question Quiz created successfully",

      quiz,

      pdfUrl,
    });

  } catch (error) {

    console.log(
      "AI QUESTION QUIZ ERROR:",
      error
    );

    return res.status(500).json({
      message:
        "Failed to create AI Question Quiz",

      error: error.message,
    });
  }
};



exports.generateAIQuestionQuizPDF = async (req, res) => {
  try {
    const { quizId } = req.params;

    if (!quizId) {
      return res.status(400).json({
        message: "quizId is required",
      });
    }

    const quiz = await Quiz.findById(quizId).populate("course", "title");

    if (!quiz) {
      return res.status(404).json({
        message: "Quiz not found",
      });
    }

    // =========================
    // ACCESS CHECK
    // =========================
    if (req.user.role === "teacher") {
      if (quiz.teacher.toString() !== req.user._id.toString()) {
        return res.status(403).json({
          message: "Access denied",
        });
      }
    }

    if (req.user.role === "student") {
      const enrolled = await Course.findOne({
        _id: quiz.course._id,
        "students.user": req.user._id,
      });

      if (!enrolled) {
        return res.status(403).json({
          message: "Access denied",
        });
      }
    }

    // =========================================
    // 🔥 MUST HAVE CONDITIONS (IMPORTANT FIX)
    // =========================================

    const hasShort = quiz.shortQuestions && quiz.shortQuestions.length > 0;
    const hasLong = quiz.longQuestions && quiz.longQuestions.length > 0;

    if (!hasShort && !hasLong) {
      return res.status(400).json({
        message: "No questions available in quiz",
      });
    }

    // =========================================
    // 📄 BUILD PDF DATA (FIXED LOGIC)
    // =========================================
    const pdfData = {
      title: quiz.title,
      description: `Course: ${quiz.course?.title}`,

      shortQuestions: hasShort ? quiz.shortQuestions : [],
      longQuestions: hasLong ? quiz.longQuestions : [],

      // optional metadata
      hasShort,
      hasLong,

      totalMarks: quiz.totalMarks,
      grandTotalMarks: quiz.totalMarks,
    };

    // =========================================
    // GENERATE PDF
    // =========================================
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
        mode: hasShort && hasLong
          ? "BOTH"
          : hasShort
          ? "SHORT_ONLY"
          : "LONG_ONLY",
      },
    });

  } catch (error) {
    console.log("AI PDF ERROR:", error);
    return res.status(500).json({
      message: error.message,
    });
  }
};