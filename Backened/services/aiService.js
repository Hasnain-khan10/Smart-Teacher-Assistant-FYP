const axios = require("axios");
require("dotenv").config();

// ======================================================================
// 🏆 HYBRID ENGINE: GROQ (TEXT) & OPENROUTER MULTI-MODEL CHAIN (SCANNING)
// ======================================================================
exports.callAI = async ({
  prompt,
  images = [],
  temperature = 0.3,
}) => {
  try {
    // 🔥 CONDITION 1: VISION (SCANNING) -> AUTOMATIC MULTI-MODEL FALLBACK LOOP
    if (images && images.length > 0) {
      const openRouterKey = process.env.OPENROUTER_API_KEY;
      if (!openRouterKey) throw new Error("OPENROUTER_API_KEY is missing in your .env file!");

      console.log(`🚀 Routing to OpenRouter Multi-Model Fallback Engine for Paper Scan...`);

      const url = "https://openrouter.ai/api/v1/chat/completions";

      let messageContent = [{ type: "text", text: prompt }];
      for (const img of images) {
        let cleanBase64 = img;
        if (!img.startsWith("data:image")) {
          cleanBase64 = `data:image/jpeg;base64,${img}`;
        }
        messageContent.push({
          type: "image_url",
          image_url: { url: cleanBase64 }
        });
      }

      const freeVisionModels = [
        "google/gemini-2.5-flash",
        "meta-llama/llama-3.2-11b-vision-instruct",
        "qwen/qwen-2-vl-7b-instruct",
        "microsoft/phi-3-medium-128k-instruct"
      ];

      let content = null;
      let lastError = null;

      for (const modelId of freeVisionModels) {
        try {
          console.log(`⏳ Trying Vision Model: ${modelId}...`);

          const payload = {
            model: modelId,
            messages: [{ role: "user", content: messageContent }],
            temperature: temperature
          };

          const response = await axios.post(url, payload, {
            headers: {
              "Authorization": `Bearer ${openRouterKey}`,
              "Content-Type": "application/json",
              "HTTP-Referer": "https://smart-assistant.com",
              "X-Title": "Smart Teacher Assistant"
            },
            timeout: 15000
          });

          if (response.data && response.data.choices && response.data.choices[0].message.content) {
            content = response.data.choices[0].message.content;
            console.log(`🎯 SCAN SUCCESSFUL! Handled by Model: ${modelId}`);
            break;
          }

        } catch (err) {
          const errMsg = err.response?.data?.error?.message || err.message;
          console.log(`⚠️ Model [${modelId}] bypassed/failed. Reason: ${errMsg}`);
          lastError = err;
        }
      }

      if (!content) {
        throw new Error(`All free vision endpoints failed or are down. Last error: ${lastError?.message}`);
      }

      // ✅ 100% UNBREAKABLE JSON EXTRACTOR & FAILSAFE
      try {
        const firstCurly = content.indexOf("{");
        const lastCurly = content.lastIndexOf("}");

        if (firstCurly !== -1 && lastCurly !== -1) {
          let extracted = content.substring(firstCurly, lastCurly + 1);
          return JSON.parse(extracted.trim());
        } else {
          throw new Error("No JSON brackets found in AI response");
        }
      } catch (jsonParseErr) {
        console.log("⚠️ Standard JSON Parse failed, trying aggressive regex clean...");
        try {
          let cleaned = content.replace(/```json/gi, "").replace(/```/g, "").trim();
          return JSON.parse(cleaned);
        } catch (finalErr) {
          console.log("🛑 AI IGNORED JSON RULES. RETURNING RAW TEXT AS FEEDBACK (CRASH PREVENTED).");
          // Agar AI sirf baatein kare aur JSON na de, to crash nahi hoga!
          // Woh baatein feedback ban jayengi aur marks 0 lag jayenge, teacher manual update kar dega.
          return {
            "obtained_marks": 0,
            "feedback": content.trim()
          };
        }
      }
    }

    // 🔥 CONDITION 2: PURE TEXT (WEEKLY PLAN / QUIZ GENERATION) -> RUNS ON GROQ UNTOUCHED
    else {
      const groqKey = process.env.GROQ_API_KEY;
      if (!groqKey) throw new Error("GROQ_API_KEY is missing in your .env file!");

      const activeModel = "llama-3.3-70b-versatile";
      let maxTokens = 3500;

      if (prompt.includes("18-Week") || prompt.includes("weeks")) {
        maxTokens = 7500;
      }

      const url = "https://api.groq.com/openai/v1/chat/completions";

      const payload = {
        model: activeModel,
        messages: [{ role: "user", content: String(prompt) }],
        temperature: temperature,
        max_tokens: maxTokens,
        response_format: { type: "json_object" }
      };

      console.log(`🚀 Routing to Groq using Model: ${activeModel}...`);

      const response = await axios.post(url, payload, {
        headers: {
          "Authorization": `Bearer ${groqKey}`,
          "Content-Type": "application/json"
        }
      });

      const content = response.data.choices[0].message.content;
      console.log("🤖 GROQ RAW RESPONSE RECEIVED SUCCESSFULLY");
      return JSON.parse(content);
    }

  } catch (error) {
    console.log("❌ AI HYBRID SERVICE CRITICAL ERROR =>", error.message);
    throw new Error(error.message || "AI request failed. Please try again.");
  }
};