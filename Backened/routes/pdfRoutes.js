const express = require("express");
const router = express.Router();

const { generateCoursePDF } = require("../controllers/pdfController");

const { protect } = require("../middleware/authMiddleware");
const { authorizeRoles } = require("../middleware/roleMiddleware");

// 👨‍🏫 + 👨‍🎓 BOTH
router.get(
  "/course/:courseId",
  protect,
  authorizeRoles("teacher", "student"),
  generateCoursePDF
);

module.exports = router;