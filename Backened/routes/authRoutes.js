const express = require("express");
const router = express.Router();

const {
  signup,
  login,
  getProfile,
  updateProfile,
  forgotPassword,
  verifyOTP,
  resetPassword,
  googleLogin,
} = require("../controllers/authController");

const { protect } = require("../middleware/authMiddleware");
const upload = require("../middleware/upload");

// Routes
router.post("/signup", signup);
router.post("/login", login);
router.get("/profile", protect, getProfile);
router.put(
  "/profile",
  protect,
  upload.single("profileImage"),
  updateProfile,
);
// =============================================
// 🔐 FORGOT PASSWORD ROUTES
// =============================================

// 1. Send OTP
router.post("/forgot-password", forgotPassword);

// 2. Verify OTP
router.post("/verify-otp", verifyOTP);

// 3. Reset Password
router.post("/reset-password", resetPassword);

router.post("/google-login", googleLogin);

module.exports = router;