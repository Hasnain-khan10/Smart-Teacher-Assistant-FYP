const User = require("../models/User");
const cloudinary = require("../config/cloudinary");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const nodemailer = require("nodemailer");
const sendEmail = require("../utils/email");
const { OAuth2Client } = require("google-auth-library");

const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

// ============================================
// GENERATE JWT
// ============================================
const generateToken = (user) => {
  return jwt.sign(
    { id: user._id || user.id, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: "7d" }
  );
};

// ============================================
// SIGNUP
// ============================================
exports.signup = async (req, res) => {
  try {
    const {
      name, email, password, role,
      fatherName, cnic, department,
      rollNumber, semester, section,
      qualification, experience, speciality,
    } = req.body;

    if (!role || !["teacher", "student"].includes(role)) {
      return res.status(400).json({ message: "Role is required and must be valid" });
    }

    // 🔥 SPEED OPTIMIZATION: .lean() for faster read operations
    const existingUser = await User.findOne({ email }).lean();
    if (existingUser) {
      return res.status(400).json({ message: "User already exists" });
    }

    if (role === "student") {
      if (!fatherName || !rollNumber || !semester || !department || !cnic || !section) {
        return res.status(400).json({ message: "All student fields are required" });
      }
    }

    if (role === "teacher") {
      if (!fatherName || !cnic || !department || !qualification || !experience || !speciality) {
        return res.status(400).json({ message: "All teacher fields are required" });
      }
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const userData = {
      name, email, password: hashedPassword, role, fatherName, cnic, department,
    };

    if (role === "student") {
      userData.rollNumber = rollNumber;
      userData.semester = semester;
      userData.section = section;
    }

    if (role === "teacher") {
      userData.qualification = qualification;
      userData.experience = experience;
      userData.speciality = speciality;
    }

    const user = await User.create(userData);
    const token = generateToken(user);

    const userResponse = user.toObject();
    delete userResponse.password;

    res.status(201).json({
      message: "User registered successfully",
      token,
      user: userResponse,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================
// LOGIN (SUPER FAST)
// ============================================
exports.login = async (req, res) => {
  try {
    const { email, password, role } = req.body;

    // 🔥 SPEED OPTIMIZATION: .lean() skips Mongoose object hydration, making it lightning fast
    const user = await User.findOne({ email }).lean();

    if (!user) {
      return res.status(400).json({ message: "Invalid credentials" });
    }

    if (role && user.role !== role) {
      return res.status(400).json({ message: "Role mismatch" });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: "Invalid credentials" });
    }

    const token = generateToken(user);
    delete user.password; // Works instantly because user is now a plain JS object

    res.json({
      message: "Login successful",
      token,
      user,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================
// PROFILE (INSTANT LOAD)
// ============================================
exports.getProfile = async (req, res) => {
  try {
    // 🔥 SPEED OPTIMIZATION: Instant read with .lean()
    const user = await User.findById(req.user._id).select("-password").lean();
    res.json({
      message: "Profile fetched successfully",
      user,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================
// UPDATE PROFILE (NO REDUNDANT DB CALLS)
// ============================================
exports.updateProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    const {
      name, fatherName, cnic, department,
      rollNumber, semester, section,
      qualification, experience, speciality,
    } = req.body;

    if (name) user.name = name;
    if (fatherName) user.fatherName = fatherName;
    if (cnic) user.cnic = cnic;
    if (department) user.department = department;

    if (user.role === "student") {
      if (rollNumber) user.rollNumber = rollNumber;
      if (semester) user.semester = semester;
      if (section) user.section = section;
    }

    if (user.role === "teacher") {
      if (qualification) user.qualification = qualification;
      if (experience) user.experience = experience;
      if (speciality) user.speciality = speciality;
    }

    if (req.file) {
      const result = await cloudinary.uploader.upload(req.file.path, {
        folder: "profile_images",
      });
      user.profileImage = result.secure_url;
    }

    await user.save();

    // 🔥 SPEED OPTIMIZATION: Removed the duplicate User.findById call. Converted existing object instantly.
    const updatedUser = user.toObject();
    delete updatedUser.password;

    res.status(200).json({
      message: "Profile updated successfully",
      user: updatedUser,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// =============================================
// FORGOT PASSWORD
// =============================================
exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: "Email is required" });

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: "User not found" });

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    user.resetOTP = otp;
    user.resetOTPExpiry = Date.now() + 10 * 60 * 1000;
    await user.save();

    await sendEmail({
      to: email,
      subject: "Password Reset OTP",
      text: `Your password reset OTP is ${otp}. It is valid for 10 minutes.`,
      html: `<p>Your password reset OTP is <b>${otp}</b>. It is valid for 10 minutes.</p>`
    });

    return res.status(200).json({ message: "OTP sent to your email" });
  } catch (error) {
    return res.status(500).json({ message: "Server error sending OTP" });
  }
};

// =============================================
// VERIFY OTP
// =============================================
exports.verifyOTP = async (req, res) => {
  try {
    const { email, otp } = req.body;
    if (!email || !otp) return res.status(400).json({ message: "Email and OTP are required" });

    // 🔥 SPEED OPTIMIZATION: .lean() applied
    const user = await User.findOne({ email }).lean();
    if (!user) return res.status(404).json({ message: "User not found" });
    if (user.resetOTP !== otp) return res.status(400).json({ message: "Invalid OTP" });
    if (user.resetOTPExpiry < Date.now()) return res.status(400).json({ message: "OTP expired" });

    return res.status(200).json({ message: "OTP verified successfully" });
  } catch (error) {
    return res.status(500).json({ message: "Server error verifying OTP" });
  }
};

// =============================================
// RESET PASSWORD
// =============================================
exports.resetPassword = async (req, res) => {
  try {
    const { email, newPassword } = req.body;
    if (!email || !newPassword) return res.status(400).json({ message: "Email and new password required" });

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: "User not found" });

    const hashedPassword = await bcrypt.hash(newPassword, 12);
    user.password = hashedPassword;
    user.resetOTP = null;
    user.resetOTPExpiry = null;
    await user.save();

    return res.status(200).json({ message: "Password reset successfully" });
  } catch (error) {
    return res.status(500).json({ message: "Server error resetting password" });
  }
};

// ============================================
// GOOGLE LOGIN (ULTRA FAST)
// ============================================
exports.googleLogin = async (req, res) => {
  try {
    const { idToken, role } = req.body;
    if (!idToken) return res.status(400).json({ message: "No ID token provided" });
    if (!role || !["teacher", "student"].includes(role)) return res.status(400).json({ message: "Role is required" });

    const ticket = await client.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });
    const { email, name } = ticket.getPayload();

    // 🔥 SPEED OPTIMIZATION: Instant user lookup
    let user = await User.findOne({ email }).lean();

    if (user) {
      if (user.role !== role) {
        return res.status(400).json({ message: `This email is already registered as ${user.role}` });
      }
    } else {
      const hashedPassword = await bcrypt.hash(crypto.randomBytes(16).toString("hex"), 10);
      const userData = { name, email, password: hashedPassword, role };

      if (role === "student") {
        userData.rollNumber = "N/A"; userData.semester = "N/A"; userData.section = "N/A";
      }
      if (role === "teacher") {
        userData.qualification = "Not Provided"; userData.experience = "Not Provided"; userData.speciality = "Not Provided";
      }
      const newUser = await User.create(userData);
      user = newUser.toObject();
    }

    const token = generateToken(user);
    delete user.password; // Fast deletion from plain object

    res.status(200).json({
      message: "Google login successful",
      token,
      user,
    });
  } catch (error) {
    res.status(401).json({ message: "Google authentication failed", error: error.message });
  }
};