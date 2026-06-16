const mongoose = require("mongoose");

const weekSchema = new mongoose.Schema({
  weekNumber: { type: Number, required: true },
  title: { type: String, required: true, trim: true }, // Topic Title
  definition: { type: String, default: "" }, // Core concept definition
  detailedExplanation: { type: String, default: "" }, // Deep lecture content
  subTopics: [{ type: String }], // Breakdown
  typesOrClassifications: [{ type: String }], // Types if any
  codeOrQuerySnippet: { type: String, default: "" }, // Programming code / SQL queries
  realWorldAnalogy: { type: String, default: "" }, // Easy understanding example
});

const weekPlanSchema = new mongoose.Schema(
  {
    course: { type: mongoose.Schema.Types.ObjectId, ref: "Course", required: true, index: true },
    teacher: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
    title: { type: String, default: "Premium 18-Week Lecture Series" },
    description: { type: String, default: "" },

    // AI Tracking
    prompt: { type: String, default: "" },
    generationSource: { type: String, enum: ["prompt", "book", "both"], default: "prompt" },
    outputFormat: { type: String, enum: ["PDF", "DOCX", "PPT"], default: "PDF" },

    // File Tracking
    bookFileUrl: { type: String, default: null },
    bookFileType: { type: String, default: null },
    bookExtractedText: { type: String, default: "" },

    weeks: [weekSchema],
    semesterDuration: { type: Number, default: 18 },
    documentUrl: { type: String, default: null }, // Multi-format URL (PDF/DOCX/PPT)
  },
  { timestamps: true }
);

weekPlanSchema.pre("save", function (next) {
  if (this.weeks.length > 18) return next(new Error("Plan cannot exceed 18 weeks"));
  next();
});

module.exports = mongoose.model("WeekPlan", weekPlanSchema);