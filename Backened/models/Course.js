const mongoose = require("mongoose");
const crypto = require("crypto");

const courseSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true,
      trim: true,
    },

    courseCode: {
      type: String,
      required: true,
      trim: true,
    },

    creditHours: {
      type: Number,
      required: true,
      min: 0,
    },

    syllabus: {
      type: String,
      trim: true,
    },

    semester: {
  type: String,
  required: true,
  trim: true,
},

    books: [
      {
        type: String,
        trim: true,
      },
    ],

    teacher: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },

    // 🔑 Join Code (for student enrollment)
    joinCode: {
      type: String,
      unique: true,
      index: true,
    },

    // 👨‍🎓 Students enrolled in course
    students: [
      {
        user: {
          type: mongoose.Schema.Types.ObjectId,
          ref: "User",
          required: true,
        },
        progress: {
          type: Number,
          default: 0,
          min: 0,
          max: 100,
        },
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

        const existing = await mongoose.models.Course.findOne({
          joinCode: code,
        });

        if (!existing) exists = false;
      }

      this.joinCode = code;
    }

    next();
  } catch (error) {
    next(error);
  }
});

module.exports = mongoose.model("Course", courseSchema);