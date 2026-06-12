const mongoose = require("mongoose");

// ================= QUESTION SCHEMA =================
const questionSchema = new mongoose.Schema({
  question: {
    type: String,
    required: true,
    trim: true,
  },

  options: {
    A: { type: String },
    B: { type: String },
    C: { type: String },
    D: { type: String },
  },

  correctAnswer: {
    type: String,
  },

  marks: {
    type: Number,
    default: 1,
  },
});

// ================= QUIZ SCHEMA =================
const quizSchema = new mongoose.Schema(
  {
    course: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Course",
      required: true,
      index: true,
    },

    teacher: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },

    title: {
      type: String,
      required: true,
      trim: true,
    },

    description: {
      type: String,
      default: "",
    },

    // ================= QUIZ TYPE SYSTEM =================
    type: {
      type: String,
      enum: ["mcq", "question", "mixed"],
      required: true,
    },

    // ================= QUESTION BANK =================
    questions: [questionSchema],

    // ================= QUESTION QUIZ SUPPORT =================
    shortQuestions: [
      {
        question: String,
        marks: Number,
      },
    ],

    longQuestions: [
      {
        question: String,
        marks: Number,
      },
    ],

    // ================= SCORING SYSTEM =================
    examMeta: {
      type: Object,
      default: {},
    },

    totalMarks: {
    type: Number,
    default: 0,
  },

  marksPerQuestion: {
  type: Number,
  default: 1,
  },

// ================= AI SCANNED QUIZ =================
isAIScanned: {
  type: Boolean,
  default: false,
},

  },
  { timestamps: true }
);

module.exports = mongoose.model("Quiz", quizSchema);