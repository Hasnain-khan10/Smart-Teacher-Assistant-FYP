const express = require("express");
const router = express.Router();
const upload = require("../middleware/upload"); // Multer middleware file support ke liye
const { createAIPlan } = require("../controllers/aiPlanController");

// 🚀 Endpoint: POST /api/ai/plans
// 'book' key ke sath multipart form-data receive karega
router.post("/", upload.single("book"), createAIPlan);

module.exports = router;