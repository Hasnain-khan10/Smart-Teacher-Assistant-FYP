const express = require("express");
const router = express.Router();

const {
  createCourse,
  joinCourse,
  getCourseStudents,
  previewCourse,
  getCourses,
  getCourseById,
  updateProgress,
  updateCourse,
  deleteCourse,
} = require("../controllers/courseController");

const { protect } = require("../middleware/authMiddleware");
const { authorizeRoles } = require("../middleware/roleMiddleware");

// 👨‍🏫 Teacher
router.post("/", protect, authorizeRoles("teacher"), createCourse);

// 👨‍🎓 Student
router.post(
  "/join",
  protect,
  authorizeRoles("student"),
  joinCourse
);

router.get(
  "/:courseId/students",
  protect,
  authorizeRoles("teacher"),
  getCourseStudents
);

router.get("/preview/:code", protect, authorizeRoles("student"), previewCourse);

// 👨‍🏫 Teacher
router.put("/:id", protect, authorizeRoles("teacher"), updateCourse);
router.delete("/:id", protect, authorizeRoles("teacher"), deleteCourse);

// 👨‍🏫 + 👨‍🎓
router.get("/", protect, authorizeRoles("teacher", "student"), getCourses);
router.get("/:id", protect, authorizeRoles("teacher", "student"), getCourseById);

module.exports = router;