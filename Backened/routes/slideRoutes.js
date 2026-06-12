const express = require("express");
const router = express.Router();

const {
  generateSlides,
  getSlidesByCourse,
  updateSlides,
  deleteSlides,
  exportSlidesToPPT,
} = require("../controllers/slideController");

const { protect } = require("../middleware/authMiddleware");
const { authorizeRoles } = require("../middleware/roleMiddleware");

// 👨‍🏫 Teacher only
router.post("/", protect, authorizeRoles("teacher"), generateSlides);
router.post("/export/:id", protect, authorizeRoles("teacher"), exportSlidesToPPT);
router.put("/:id", protect, authorizeRoles("teacher"), updateSlides);
router.delete("/:id", protect, authorizeRoles("teacher"), deleteSlides);

// 👨‍🏫 + 👨‍🎓 BOTH (MUST BE LAST)
router.get("/:courseId", protect, authorizeRoles("teacher", "student"), getSlidesByCourse);

module.exports = router;