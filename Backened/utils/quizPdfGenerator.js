const PDFDocument = require("pdfkit");
const fs = require("fs");

exports.generateQuizPDF = (data, filePath) => {
  return new Promise((resolve, reject) => {
    try {
      const doc = new PDFDocument({ margin: 50 });
      const stream = fs.createWriteStream(filePath);
      doc.pipe(stream);

      // ============================================
      // PART 1: STUDENT QUESTION PAPER
      // ============================================
      doc.fontSize(22).font("Helvetica-Bold").text(data.title || "Examination Paper", { align: "center" });
      doc.moveDown(0.5);
      doc.fontSize(12).font("Helvetica").text(data.description || "", { align: "center" });
      doc.moveDown(2);

      // 1. MCQ Section
      if (data.questions && data.questions.length > 0) {
        const perMark = data?.examMeta?.marksPerQuestion || 1;
        doc.fontSize(16).font("Helvetica-Bold").text("SECTION A: Multiple Choice Questions");
        doc.moveDown();

        data.questions.forEach((q, index) => {
          doc.fontSize(12).font("Helvetica-Bold").text(`Q${index + 1}. ${q.question} (${q.marks || perMark} Marks)`);
          doc.font("Helvetica").moveDown(0.5);
          doc.text(`A. ${q.options?.A || ""}`);
          doc.text(`B. ${q.options?.B || ""}`);
          doc.text(`C. ${q.options?.C || ""}`);
          doc.text(`D. ${q.options?.D || ""}`);
          doc.moveDown(1);
        });
      }

      // 2. Short Questions Section
      if (data.shortQuestions && data.shortQuestions.length > 0) {
        doc.fontSize(16).font("Helvetica-Bold").text("SECTION B: Short Answer Questions");
        doc.moveDown();
        data.shortQuestions.forEach((q, index) => {
          doc.fontSize(12).font("Helvetica-Bold").text(`Q${index + 1}. ${q.question} (${q.marks} Marks)`);
          doc.moveDown(2); // Leave space for writing
        });
      }

      // 3. Long Questions Section
      if (data.longQuestions && data.longQuestions.length > 0) {
        doc.fontSize(16).font("Helvetica-Bold").text("SECTION C: Long Descriptive Questions");
        doc.moveDown();
        data.longQuestions.forEach((q, index) => {
          doc.fontSize(12).font("Helvetica-Bold").text(`Q${index + 1}. ${q.question} (${q.marks} Marks)`);
          doc.moveDown(4); // Leave more space
        });
      }

      // ============================================
      // PART 2: INSTRUCTOR ANSWER KEY (NEW PAGE)
      // ============================================
      doc.addPage();
      doc.fontSize(20).font("Helvetica-Bold").fillColor("red").text("INSTRUCTOR ONLY - ANSWER KEY & RUBRIC", { align: "center" });
      doc.fillColor("black").moveDown(2);

      // MCQ Key
      if (data.questions && data.questions.length > 0) {
        doc.fontSize(16).font("Helvetica-Bold").text("MCQ Solutions & Rationale");
        doc.moveDown(0.5);
        data.questions.forEach((q, index) => {
          doc.fontSize(12).font("Helvetica-Bold").text(`Q${index + 1}. Correct Answer: ${q.correctAnswer}`);
          doc.font("Helvetica").text(`Rationale: ${q.explanation || "N/A"}`, { indent: 15 });
          doc.moveDown(1);
        });
      }

      // Subjective Key (Short)
      if (data.shortQuestions && data.shortQuestions.length > 0) {
        doc.fontSize(16).font("Helvetica-Bold").text("Short Questions - Grading Guide");
        doc.moveDown(0.5);
        data.shortQuestions.forEach((q, index) => {
          doc.fontSize(12).font("Helvetica-Bold").text(`Q${index + 1}. Ideal Answer:`);
          doc.font("Helvetica").text(q.idealAnswer || "N/A", { indent: 15 });
          doc.font("Helvetica-Bold").text("Rubric: ");
          doc.font("Helvetica").text(q.rubric || "N/A", { indent: 15 });
          doc.moveDown(1);
        });
      }

      // Subjective Key (Long)
      if (data.longQuestions && data.longQuestions.length > 0) {
        doc.fontSize(16).font("Helvetica-Bold").text("Long Questions - Grading Guide");
        doc.moveDown(0.5);
        data.longQuestions.forEach((q, index) => {
          doc.fontSize(12).font("Helvetica-Bold").text(`Q${index + 1}. Ideal Answer:`);
          doc.font("Helvetica").text(q.idealAnswer || "N/A", { indent: 15 });
          doc.font("Helvetica-Bold").text("Rubric: ");
          doc.font("Helvetica").text(q.rubric || "N/A", { indent: 15 });
          doc.moveDown(1);
        });
      }

      doc.end();
      stream.on("finish", () => resolve(filePath));
      stream.on("error", reject);
    } catch (error) {
      reject(error);
    }
  });
};