const mongoose = require("mongoose");
const crypto = require("crypto");

const courseSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true },
    courseCode: { type: String, required: true, trim: true },
    creditHours: { type: Number, required: true, min: 0 },
    syllabus: { type: String, trim: true },
    semester: { type: String, required: true, trim: true },
    books: [{ type: String, trim: true }],
    teacher: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, index: true },
    joinCode: { type: String, unique: true, index: true },
    students: [
      {
        user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
        progress: { type: Number, default: 0, min: 0, max: 100 },
      },
    ],
  },
  { timestamps: true }
);

// ===============================
// AUTO-GENERATE JOIN CODE
// ===============================
courseSchema.pre("save", async function (next) {
  try {
    if (!this.joinCode) {
      let code;
      let exists = true;
      while (exists) {
        code = crypto.randomBytes(4).toString("hex");
        const existing = await mongoose.models.Course.findOne({ joinCode: code });
        if (!existing) exists = false;
      }
      this.joinCode = code;
    }
    next();
  } catch (error) {
    next(error);
  }
});

// ==============================================================
// 🔥 MIT LEVEL CASCADE DELETE: CLEANUP ORPHANED DATA AUTOMATICALLY
// ==============================================================
courseSchema.pre("deleteOne", { document: true, query: false }, async function (next) {
  try {
    const courseId = this._id;
    console.log(`🗑️ Initiating Cascade Delete for Course: ${courseId}`);

    // 1. Delete all Weekly Plans associated with this course
    await mongoose.model("WeekPlan").deleteMany({ course: courseId });

    // 2. Find all Quizzes for this course
    const quizzes = await mongoose.model("Quiz").find({ course: courseId });
    const quizIds = quizzes.map(q => q._id);

    // 3. Delete all Quizzes
    await mongoose.model("Quiz").deleteMany({ course: courseId });

    // 4. Delete all Student Attempts associated with those Quizzes
    if (quizIds.length > 0) {
      await mongoose.model("Attempt").deleteMany({ quiz: { $in: quizIds } });
    }

    console.log(`✅ Cascade Delete Complete! All Plans, Quizzes, and Attempts removed.`);
    next();
  } catch (error) {
    console.log(`❌ Cascade Delete Error:`, error.message);
    next(error);
  }
});

module.exports = mongoose.model("Course", courseSchema);