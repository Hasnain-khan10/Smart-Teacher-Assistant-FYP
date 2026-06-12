const express = require("express");
const router = express.Router();

const { createAIPlan } = require("../controllers/aiPlanController");

router.post("/generate", createAIPlan);

module.exports = router;