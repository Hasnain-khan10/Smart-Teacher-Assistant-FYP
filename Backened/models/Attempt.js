const mongoose = require("mongoose");

const attemptSchema = new mongoose.Schema(
  {
    student: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    quiz: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Quiz",
      required: true,
      index: true,
    },
    answers: [
      {
        selectedAnswer: { type: String, default: null },
        question_text: { type: String, default: "" },
        correct_answer: { type: String, default: "" },
        obtained_marks: { type: Number, default: 0 },
        max_marks: { type: Number, default: 0 },
        isCorrect: { type: Boolean, default: false },
        scannedImage: { type: String, default: null },
        aiFeedback: { type: String, default: "" }, // 🔥 NEW: AI Reason for Marks
      },
    ],
    score: {
      type: Number,
      required: true,
      default: 0,
    },
    total: {
      type: Number,
      default: 0,
    },
    evaluatedByAI: {
      type: Boolean,
      default: false,
    },
    scannedPaper: [
      { type: String },
    ],
  },
  { timestamps: true }
);

attemptSchema.index({ student: 1, quiz: 1 }, { unique: true });

module.exports = mongoose.model("Attempt", attemptSchema);