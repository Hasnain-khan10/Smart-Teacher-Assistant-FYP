const axios = require("axios");
require("dotenv").config();

// ======================================================
// 🔥 GROQ CLOUD AI SERVICE (WITH VISION SCANNING SUPPORT)
// ======================================================
exports.callAI = async ({
  prompt,
  images = [],
  temperature = 0.3,
}) => {
  try {
    const apiKey = process.env.GROQ_API_KEY;
    if (!apiKey) throw new Error("GROQ_API_KEY is missing in your .env file!");

    // Default Settings for Text
    let activeModel = "llama-3.3-70b-versatile";
    let maxTokens = 3500;
    if (prompt.includes("18-Week") || prompt.includes("weeks")) {
      maxTokens = 7500;
    }

    let messageContent;

    // 🔥 SMART VISION SWITCH: Agar image aayi to Vision Model trigger hoga
    if (images && images.length > 0) {
      activeModel = "llama-3.2-11b-vision-preview"; // Groq Vision Model
      maxTokens = 2000; // Standard size for evaluations

      messageContent = [{ type: "text", text: prompt }];

      for (const img of images) {
        const base64Data = img.startsWith("data:image") ? img : `data:image/jpeg;base64,${img}`;
        messageContent.push({
          type: "image_url",
          image_url: { url: base64Data }
        });
      }
    } else {
      // Normal Text Prompt
      messageContent = prompt;
    }

    const url = "https://api.groq.com/openai/v1/chat/completions";

    const payload = {
      model: activeModel,
      messages: [{ role: "user", content: messageContent }],
      temperature: temperature,
      max_tokens: maxTokens,
      response_format: { type: "json_object" }
    };

    console.log(`🚀 Sending request to Groq using Model: ${activeModel}...`);

    const response = await axios.post(url, payload, {
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json"
      }
    });

    const content = response.data.choices[0].message.content;
    console.log("🤖 GROQ RAW RESPONSE RECEIVED SUCCESSFULLY");

    return JSON.parse(content);

  } catch (error) {
    console.log("❌ GROQ ERROR =>", JSON.stringify(error.response?.data || error.message, null, 2));
    throw new Error("Groq API request failed. Please try again.");
  }
};