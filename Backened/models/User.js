const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
  {
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
      index: true,
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
    profileImage: {
      type: String,
      default: "",
    },
    // 🔥 FIREBASE PUSH NOTIFICATION TOKEN FIELD (Snapchat/FB Style Background Push)
    fcmToken: {
      type: String,
      default: "",
    },
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
    resetOTP: { type: String },
    resetOTPExpiry: { type: Date },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("User", userSchema);