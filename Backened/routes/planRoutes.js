const express = require("express");
const router = express.Router();
const multer = require("multer");
const upload = multer({ dest: "uploads/" });

const {
  generatePlan,
  getPlanByCourse,
  generateWeekPDF,
  updateWeekAI,
  deleteWeek,
  updatePlan,
  deletePlan,
  generateAIPlan,
  generateAIPlanFromBook,
  downloadAIPlanPDF,
} = require("../controllers/planController");

const { protect } = require("../middleware/authMiddleware");
const { authorizeRoles } = require("../middleware/roleMiddleware");

// ================= TEACHER ONLY =================
router.post("/", protect, authorizeRoles("teacher"), generatePlan);

router.put("/:id", protect, authorizeRoles("teacher"), updatePlan);
router.delete("/:id", protect, authorizeRoles("teacher"), deletePlan);

// ================= AI =================
router.post(
  "/ai",
  protect,
  authorizeRoles("teacher", "student"),
  generateAIPlan
);

router.post(
  "/ai/book",
  protect,
  authorizeRoles("teacher", "student"),
  upload.single("book"),
  generateAIPlanFromBook,
);

// 👇 NEW AI PDF ROUTE
router.get(
  "/ai/pdf/:courseId",
  protect,
  authorizeRoles("teacher", "student"),
  downloadAIPlanPDF
);

// ================= PDF WEEK =================
router.get(
  "/pdf/week/:courseId/:weekNumber",
  protect,
  authorizeRoles("teacher", "student"),
  generateWeekPDF
);

// AI update single week
router.put("/week/update-ai",protect,
  authorizeRoles("teacher"), updateWeekAI);

// delete single week
router.delete(
  "/week/delete/:courseId/:weekNumber",
  protect,
  authorizeRoles("teacher"),
  deleteWeek
);

// ================= GET PLAN =================
router.get(
  "/:courseId",
  protect,
  authorizeRoles("teacher", "student"),
  getPlanByCourse
);

module.exports = router;