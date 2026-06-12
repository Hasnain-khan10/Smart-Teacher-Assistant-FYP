const mongoose = require("mongoose");


const userSchema = new mongoose.Schema(
  {
    // =========================
    // BASIC INFO
    // =========================
    
    name: {
      type: String,
      required: true,
      trim: true,
    },

    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },

    password: {
      type: String,
      required: true,
    },

    role: {
      type: String,
      enum: ["teacher", "student"],
      required: true,
    },

    // =========================
// PROFILE IMAGE
// =========================
profileImage: {
  type: String,
  default: "",
},

    // =========================
    // COMMON FIELDS
    // =========================
    fatherName: {
      type: String,
      trim: true,
    },

    cnic: {
      type: String,
      trim: true,
    },

    department: {
      type: String,
      trim: true,
    },

    // =========================
    // 👨‍🎓 STUDENT FIELDS
    // =========================
    rollNumber: {
      type: String,
      trim: true,
      required: function () {
        return this.role === "student";
      },
    },

    semester: {
      type: String,
      trim: true,
      required: function () {
        return this.role === "student";
      },
    },

    section: {
      type: String,
      trim: true,
      required: function () {
        return this.role === "student";
      },
    },

    // =========================
    // 👨‍🏫 TEACHER FIELDS
    // =========================
    qualification: {
      type: String,
      trim: true,
      required: function () {
        return this.role === "teacher";
      },
    },

    experience: {
      type: String,
      trim: true,
      required: function () {
        return this.role === "teacher";
      },
    },

    speciality: {
      type: String,
      trim: true,
      required: function () {
        return this.role === "teacher";
      },
    },

    // =========================
    // RESET PASSWORD
    // =========================
    resetOTP: { type: String },
    resetOTPExpiry: { type: Date },
    
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("User", userSchema);