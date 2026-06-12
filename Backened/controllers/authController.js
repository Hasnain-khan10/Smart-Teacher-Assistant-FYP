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
    { id: user._id, role: user.role },
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
      name,
      email,
      password,
      role,

      // Common
      fatherName,
      cnic,
      department,

      // Student
      rollNumber,
      semester,
      section,

      // Teacher
      qualification,
      experience,
      speciality,
    } = req.body;

    // ✅ Role Validation
    if (!role || !["teacher", "student"].includes(role)) {
      return res.status(400).json({ message: "Role is required and must be valid" });
    }

    // ✅ Check Existing User
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ message: "User already exists" });
    }

    // ============================================
    // 🔥 ROLE-BASED VALIDATION
    // ============================================

    if (role === "student") {
      if (!fatherName || !rollNumber || !semester || !department || !cnic || !section) {
        return res.status(400).json({
          message: "All student fields are required",
        });
      }
    }

    if (role === "teacher") {
      if (!fatherName || !cnic || !department || !qualification || !experience || !speciality) {
        return res.status(400).json({
          message: "All teacher fields are required",
        });
      }
    }

    // ✅ Hash Password
    const hashedPassword = await bcrypt.hash(password, 10);

    // ============================================
    // 🔥 CREATE USER (CLEAN OBJECT)
    // ============================================
    const userData = {
      name,
      email,
      password: hashedPassword,
      role,
      fatherName,
      cnic,
      department,
    };

    // ✅ Add Student Fields
    if (role === "student") {
      userData.rollNumber = rollNumber;
      userData.semester = semester;
      userData.section = section;
    }

    // ✅ Add Teacher Fields
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
// LOGIN
// ============================================
exports.login = async (req, res) => {
  try {
    const { email, password, role } = req.body;

    const user = await User.findOne({ email });

    if (!user) {
      return res.status(400).json({ message: "Invalid credentials" });
    }

    // 🔥 Role mismatch check
    if (role && user.role !== role) {
      return res.status(400).json({ message: "Role mismatch" });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: "Invalid credentials" });
    }

    const token = generateToken(user);

    const userResponse = user.toObject();
    delete userResponse.password;

    res.json({
      message: "Login successful",
      token,
      user: userResponse,
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};



// ============================================
// PROFILE
// ============================================
exports.getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select("-password");

    res.json({
      message: "Profile fetched successfully",
      user,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};


// ============================================
// UPDATE PROFILE
// ============================================
exports.updateProfile = async (req, res) => {
  try {

    const user = await User.findById(req.user._id);

    if (!user) {
      return res.status(404).json({
        message: "User not found",
      });
    }

    const {
      name,
      fatherName,
      cnic,
      department,

      // Student
      rollNumber,
      semester,
      section,

      // Teacher
      qualification,
      experience,
      speciality,
    } = req.body;

    // ============================================
    // COMMON FIELDS
    // ============================================
    if (name !== undefined) {
      user.name = name;
    }

    if (fatherName !== undefined) {
      user.fatherName = fatherName;
    }

    if (cnic !== undefined) {
      user.cnic = cnic;
    }

    if (department !== undefined) {
      user.department = department;
    }

    // ============================================
    // STUDENT FIELDS
    // ============================================
    if (user.role === "student") {

      if (rollNumber !== undefined) {
        user.rollNumber = rollNumber;
      }

      if (semester !== undefined) {
        user.semester = semester;
      }

      if (section !== undefined) {
        user.section = section;
      }
    }

    // ============================================
    // TEACHER FIELDS
    // ============================================
    if (user.role === "teacher") {

      if (qualification !== undefined) {
        user.qualification = qualification;
      }

      if (experience !== undefined) {
        user.experience = experience;
      }

      if (speciality !== undefined) {
        user.speciality = speciality;
      }
    }

    // ============================================
// PROFILE IMAGE
// ============================================
if (req.file) {

  const result = await cloudinary.uploader.upload(
    req.file.path,
    {
      folder: "profile_images",
    }
  );

  user.profileImage = result.secure_url;
}

    await user.save();

    const updatedUser = await User.findById(user._id)
      .select("-password");

    res.status(200).json({
      message: "Profile updated successfully",
      user: updatedUser,
    });

  } catch (error) {

    res.status(500).json({
      error: error.message,
    });
  }
};


// =============================================
// 🔐 FORGOT PASSWORD — Send OTP
exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email)
      return res.status(400).json({ message: "Email is required" });

    const user = await User.findOne({ email });
    if (!user)
      return res.status(404).json({ message: "User not found" });

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    user.resetOTP = otp;
    user.resetOTPExpiry = Date.now() + 10 * 60 * 1000; // 10 minutes
    await user.save();

    // Send OTP email
    await sendEmail({
      to: email,
      subject: "Password Reset OTP",
      text: `Your password reset OTP is ${otp}. It is valid for 10 minutes.`,
      html: `<p>Your password reset OTP is <b>${otp}</b>. It is valid for 10 minutes.</p>`
    });

    return res.status(200).json({
      message: "OTP sent to your email",
    });
  } catch (error) {
    console.error("❌ Forgot Password Error:", error);
    return res.status(500).json({ message: "Server error sending OTP" });
  }
};


// =============================================
// 🔎 VERIFY OTP
// =============================================
exports.verifyOTP = async (req, res) => {
  try {
    const { email, otp } = req.body;

    if (!email || !otp)
      return res.status(400).json({ message: "Email and OTP are required" });

    const user = await User.findOne({ email });
    if (!user)
      return res.status(404).json({ message: "User not found" });

    if (user.resetOTP !== otp)
      return res.status(400).json({ message: "Invalid OTP" });

    if (user.resetOTPExpiry < Date.now())
      return res.status(400).json({ message: "OTP expired" });

    return res.status(200).json({
      message: "OTP verified successfully",
    });
  } catch (error) {
    console.error("❌ OTP Verification Error:", error);
    return res.status(500).json({ message: "Server error verifying OTP" });
  }
};
 

// =============================================
// 🔄 RESET PASSWORD
// =============================================
exports.resetPassword = async (req, res) => {
  try {
    const { email, newPassword } = req.body;

    if (!email || !newPassword)
      return res.status(400).json({ message: "Email and new password required" });

    const user = await User.findOne({ email });
    if (!user)
      return res.status(404).json({ message: "User not found" });

    const hashedPassword = await bcrypt.hash(newPassword, 12);

    user.password = hashedPassword;
    user.resetOTP = null;
    user.resetOTPExpiry = null;

    await user.save();

    return res.status(200).json({
      message: "Password reset successfully",
    });
  } catch (error) {
    console.error("❌ Reset Password Error:", error);
    return res.status(500).json({ message: "Server error resetting password" });
  }
};


// ============================================
// GOOGLE LOGIN (FINAL FIXED)
// ============================================
exports.googleLogin = async (req, res) => {
  try {
    const { idToken, role } = req.body;

    // ============================================
    // VALIDATIONS
    // ============================================
    if (!idToken) {
      return res.status(400).json({
        message: "No ID token provided",
      });
    }

    if (!role || !["teacher", "student"].includes(role)) {
      return res.status(400).json({
        message: "Role is required",
      });
    }

    // ============================================
    // VERIFY GOOGLE TOKEN
    // ============================================
    const ticket = await client.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });

    const { email, name } = ticket.getPayload();

    // ============================================
    // CHECK EXISTING USER
    // ============================================
    let user = await User.findOne({ email });

    // ============================================
    // EXISTING USER
    // ============================================
    if (user) {

      // Prevent role mismatch
      if (user.role !== role) {
        return res.status(400).json({
          message: `This email is already registered as ${user.role}`,
        });
      }

    }

    // ============================================
    // NEW USER
    // ============================================
    else {

      // Generate secure random password
      const hashedPassword = await bcrypt.hash(
        crypto.randomBytes(16).toString("hex"),
        10
      );

      // Base user object
      const userData = {
        name,
        email,
        password: hashedPassword,
        role,
      };

      // ============================================
      // DEFAULT STUDENT FIELDS
      // ============================================
      if (role === "student") {
        userData.rollNumber = "N/A";
        userData.semester = "N/A";
        userData.section = "N/A";
      }

      // ============================================
      // DEFAULT TEACHER FIELDS
      // ============================================
      if (role === "teacher") {
        userData.qualification = "Not Provided";
        userData.experience = "Not Provided";
        userData.speciality = "Not Provided";
      }

      // Create user
      user = await User.create(userData);
    }

    // ============================================
    // GENERATE JWT TOKEN
    // ============================================
    const token = generateToken(user);

    // Remove password from response
    const userResponse = user.toObject();
    delete userResponse.password;

    // ============================================
    // SUCCESS RESPONSE
    // ============================================
    res.status(200).json({
      message: "Google login successful",
      token,
      user: userResponse,
    });

  } catch (error) {

    console.error("Google Login Error:", error.message);

    res.status(401).json({
      message: "Google authentication failed",
      error: error.message,
    });
  }
};