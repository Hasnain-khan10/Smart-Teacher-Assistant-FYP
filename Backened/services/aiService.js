const axios = require("axios");
require("dotenv").config();

// ======================================================
// 🔥 UNIVERSAL AI SERVICE (Strict JSON Format Enforced)
// ======================================================

exports.callAI = async ({
  prompt,
  images = [],
  model = "gemini-3.5-flash", // Aapka set kiya hua model
  temperature = 0.3,
}) => {
  try {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) throw new Error("GEMINI_API_KEY is missing in your .env file!");

    const parts = [];

    // 1. SYSTEM + USER PROMPT (🔥 STRICT JSON FORMAT ADDED HERE 🔥)
    const fullPrompt = `
You are an advanced AI university evaluator.

IMPORTANT RULES:
- Return ONLY valid JSON
- No markdown, No code block, No explanations
- You MUST return the JSON EXACTLY in this format, do not change the variable names:
{
  "evaluation": {
    "total_max_marks": 5,
    "total_obtained_marks": 4,
    "overall_feedback": "Overall summary here"
  },
  "detailedAnswers": [
    {
      "question_text": "Question text here",
      "student_answer": "Student's exact answer",
      "correct_answer": "The ideal correct answer",
      "obtained_marks": 4,
      "isCorrect": true,
      "feedback": "Specific feedback here"
    }
  ]
}

If images are provided:
- analyze handwriting carefully
- understand messy handwriting
- detect questions and answers
- evaluate like a teacher
- give partial marks fairly
- do not hallucinate missing answers

Here is the task:
${prompt}
    `;
    parts.push({ text: fullPrompt });

    // 2. ADD IMAGES
    if (images.length > 0) {
      for (const image of images) {
        let base64Data = image;
        let mimeType = "image/jpeg";

        if (image.startsWith("data:image")) {
          const split = image.split(";base64,");
          mimeType = split[0].replace("data:", "");
          base64Data = split[1];
        }

        parts.push({ inline_data: { mime_type: mimeType, data: base64Data } });
      }
    }

    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
    const payload = { contents: [{ parts }], generationConfig: { temperature: temperature } };

    // ==================================================
    // 🔥 AUTO-RETRY LOGIC
    // ==================================================
    let response;
    let maxRetries = 3;

    for (let i = 0; i < maxRetries; i++) {
      try {
        response = await axios.post(url, payload, { headers: { "Content-Type": "application/json" } });
        break;
      } catch (err) {
        const status = err.response?.status;
        if ((status === 503 || status === 429) && i < maxRetries - 1) {
          console.log(`⚠️ Google API busy (Status ${status}). Retrying in 2.5 seconds...`);
          await new Promise(resolve => setTimeout(resolve, 2500));
        } else {
          throw err;
        }
      }
    }

    // ==================================================
    // RAW AI RESPONSE & CLEANUP
    // ==================================================
    const content = response.data.candidates[0].content.parts[0].text;
    console.log("🤖 AI RAW RESPONSE =>", content);

    let cleaned = content.replace(/```json/g, "").replace(/```/g, "").trim();

    try {
      return JSON.parse(cleaned);
    } catch (err) {
      console.log("❌ INVALID JSON FROM AI =>", cleaned);
      throw new Error("AI returned invalid JSON");
    }

  } catch (error) {
    console.log("❌ AI ERROR =>", JSON.stringify(error.response?.data, null, 2) || error.message);
    throw new Error("AI request failed. Google servers might be completely overloaded right now.");
  }
};