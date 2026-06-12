const axios = require("axios");

// ======================================================
// 🔥 UNIVERSAL AI SERVICE
// Supports:
// ✅ Text AI
// ✅ Vision/Image AI
// ✅ JSON Parsing
// ✅ OpenRouter GPT-4o
// ✅ Handwriting Recognition
// ✅ Quiz Evaluation
// ======================================================

exports.callAI = async ({
  prompt,
  images = [],
  model = "openai/gpt-4o-mini",
  temperature = 0.3,
}) => {

  try {

    // ==================================================
    // BUILD USER CONTENT
    // ==================================================
    let userContent;

    // ============================
    // IMAGE / VISION MODE
    // ============================
    if (images.length > 0) {

      userContent = [];

      // ADD TEXT PROMPT
      userContent.push({
        type: "text",
        text: prompt,
      });

      // ADD IMAGES
      for (const image of images) {

        userContent.push({
          type: "image_url",
          image_url: {
            url: image,
          },
        });
      }
    }

    // ============================
    // TEXT MODE
    // ============================
    else {

      userContent = prompt;
    }

    // ==================================================
    // OPENROUTER API CALL
    // ==================================================
    const response = await axios.post(

      "https://openrouter.ai/api/v1/chat/completions",

      {
        model,

        messages: [

          // ============================================
          // SYSTEM PROMPT
          // ============================================
          {
            role: "system",

            content: `
You are an advanced AI university evaluator.

IMPORTANT RULES:
- Return ONLY valid JSON
- No markdown
- No code block
- No explanations
- No extra text
- No comments
- Always return clean parseable JSON

If images are provided:
- analyze handwriting carefully
- understand messy handwriting
- detect questions and answers
- evaluate like a teacher
- give partial marks fairly
- understand diagrams + text
- do not hallucinate missing answers
            `,
          },

          // ============================================
          // USER CONTENT
          // ============================================
          {
            role: "user",
            content: userContent,
          },
        ],

        temperature,

        max_tokens: 4000,
      },

      {
        headers: {

          Authorization:
            `Bearer ${process.env.OPENROUTER_API_KEY}`,

          "Content-Type": "application/json",

          "HTTP-Referer":
            "http://localhost:5000",

          "X-Title":
            "Smart Teacher Assistance",
        },
      }
    );

    // ==================================================
    // RAW AI RESPONSE
    // ==================================================
    const content =
      response.data.choices[0].message.content;

    console.log(
      "🤖 AI RAW RESPONSE =>",
      content
    );

    // ==================================================
    // CLEAN RESPONSE
    // ==================================================
    let cleaned = content;

    // REMOVE MARKDOWN JSON BLOCKS
    cleaned = cleaned
      .replace(/```json/g, "")
      .replace(/```/g, "")
      .trim();

    // ==================================================
    // SAFE JSON PARSE
    // ==================================================
    try {

      return JSON.parse(cleaned);

    } catch (err) {

      console.log(
        "❌ INVALID JSON FROM AI =>",
        cleaned
      );

      throw new Error(
        "AI returned invalid JSON"
      );
    }

  } catch (error) {

    console.log(
      "❌ AI ERROR =>",
      error.response?.data || error.message
    );

    throw new Error("AI request failed");
  }
};