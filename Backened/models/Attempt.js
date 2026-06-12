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
        selectedAnswer: {
          type: String,
          default: null,
          required: false,
        },
      },
    ],

    // =========================
    // SCORE
    // =========================
    score: {
      type: Number,
      required: true,
      default: 0,
    },

    // =========================
    // TOTAL MARKS
    // =========================
    total: {
      type: Number,
      default: 0,
    },

    // =========================
    // AI SCAN
    // =========================
    evaluatedByAI: {
      type: Boolean,
      default: false,
    },

    scannedPaper: [
  {
    type: String,
  },
],

  },
  { timestamps: true }
);

// Prevent multiple attempts
attemptSchema.index(
  { student: 1, quiz: 1 },
  { unique: true }
);

module.exports = mongoose.model(
  "Attempt",
  attemptSchema
);