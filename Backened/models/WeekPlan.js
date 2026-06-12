const mongoose = require("mongoose");

const weekSchema = new mongoose.Schema({
  weekNumber: {
    type: Number,
    required: true,
  },

  title: {
    type: String,
    required: true,
    trim: true,
  },

  topics: [{ type: String }],

clo: {
  type: [String],
  default: [],
},

  objectives: [{ type: String }],
  tasks: [{ type: String }],

  // AI Enhancements
  advantages: {
    type: String,
    default: "",
  },

  disadvantages: {
    type: String,
    default: "",
  },
});

const weekPlanSchema = new mongoose.Schema(
  {
    // =========================
    // RELATIONS
    // =========================
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

    // =========================
    // PLAN INFO
    // =========================
    title: {
      type: String,
      default: "AI Generated 18 Week Plan",
    },

    description: {
      type: String,
      default: "",
    },

    // =========================
    // 🧠 AI INPUT TRACKING (NEW)
    // =========================
    prompt: {
      type: String,
      default: "",
    },

    generationSource: {
      type: String,
      enum: ["prompt", "book", "both"],
      default: "prompt",
    },

    // =========================
    // 📘 BOOK SUPPORT (NEW)
    // =========================
    bookFileUrl: {
      type: String, // stored file path / cloud URL
      default: null,
    },

    bookFileType: {
      type: String, // "image" | "pdf"
      default: null,
    },

    bookExtractedText: {
      type: String, // OCR / parsed text
      default: "",
    },

    // =========================
    // CORE DATA
    // =========================
    weeks: [weekSchema],

    semesterDuration: {
      type: Number,
      default: 18,
    },

    pdfUrl: {
      type: String,
      default: null,
    },
  },
  { timestamps: true }
);

// =========================
// 🔒 VALIDATION
// =========================
weekPlanSchema.pre("save", function (next) {
  if (this.weeks.length > 18) {
    return next(new Error("Week plan cannot exceed 18 weeks"));
  }
  next();
});

module.exports = mongoose.model("WeekPlan", weekPlanSchema);