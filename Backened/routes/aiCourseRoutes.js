const express = require("express");
const router = express.Router();

const { createAICourse } = require("../controllers/aiCourseController");

router.post("/generate-course", createAICourse);

module.exports = router;