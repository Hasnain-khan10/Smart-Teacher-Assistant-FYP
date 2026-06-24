const mongoose = require("mongoose");

// ================= QUESTION SCHEMA =================
const questionSchema = new mongoose.Schema({
  question: { type: String, required: true, trim: true },
  options: {
    A: { type: String },
    B: { type: String },
    C: { type: String },
    D: { type: String },
  },
  correctAnswer: { type: String },
  explanation: { type: String, default: "" },
  marks: { type: Number, default: 1 },
});

// ================= QUIZ SCHEMA =================
const quizSchema = new mongoose.Schema(
  {
    course: { type: mongoose.Schema.Types.ObjectId, ref: "Course", required: true, index: true },
    teacher: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
    title: { type: String, required: true, trim: true },
    description: { type: String, default: "" },
    type: { type: String, enum: ["mcq", "question", "mixed"], required: true },
    questions: [questionSchema],

    shortQuestions: [
      {
        question: String,
        marks: Number,
        idealAnswer: { type: String, default: "" },
        rubric: { type: String, default: "" }
      },
    ],
    longQuestions: [
      {
        question: String,
        marks: Number,
        idealAnswer: { type: String, default: "" },
        rubric: { type: String, default: "" }
      },
    ],

    examMeta: { type: Object, default: {} },
    totalMarks: { type: Number, default: 0 },
    marksPerQuestion: { type: Number, default: 1 },
    isAIScanned: { type: Boolean, default: false },

    // 🔥 AUTOMATED TIME-BASED LOCK/UNLOCK FIELDS
    // Ye fields auto-handle karengi kab quiz show karna hai aur kab lock karna hai
    openDateTime: {
      type: Date,
    },
    deadlineDateTime: {
      type: Date,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Quiz", quizSchema);