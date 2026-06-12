const PDFDocument = require("pdfkit");
const fs = require("fs");

exports.generateQuizPDF = (data, filePath) => {
  return new Promise((resolve, reject) => {
    try {
      const doc = new PDFDocument({ margin: 50 });

      const stream = fs.createWriteStream(filePath);
      doc.pipe(stream);

      // 🧠 BASIC INFO
      const title = data?.title || "Exam Paper";
      const description = data?.description || "";

      // 📄 HEADER
      doc.fontSize(20).text(title, { align: "center" });
      doc.moveDown();

      doc.fontSize(12).text(description);
      doc.moveDown(2);

      // =========================
      // 🟢 MCQ SECTION (UPDATED WITH MARKS)
      // =========================
      if (data.questions?.[0]?.options) {

        const perMark = data?.examMeta?.marksPerQuestion || 1;
        const totalMarks = data?.examMeta?.totalMarks || 0;

        doc.fontSize(14).text("MCQ EXAM PAPER:");
        doc.moveDown();

        data.questions.forEach((q, index) => {
          if (!q?.question) return;

          doc.fontSize(12).text(
            `${index + 1}. ${q.question} (${perMark} Marks)`
          );
          doc.moveDown(0.5);

          doc.text(`A. ${q.options?.A || ""}`);
          doc.text(`B. ${q.options?.B || ""}`);
          doc.text(`C. ${q.options?.C || ""}`);
          doc.text(`D. ${q.options?.D || ""}`);

          doc.moveDown(1);
        });

        // ✅ TOTAL MARKS
        doc.moveDown(2);
        doc.fontSize(14).text(`Total Marks: ${totalMarks}`);
      }

      // =========================
      // 🟡 BOTH (SHORT + LONG)
      // =========================
      else if (data.shortQuestions || data.longQuestions) {

        let grandTotal = 0;

        // SHORT SECTION
        if (Array.isArray(data.shortQuestions)) {
          doc.fontSize(14).text("SHORT QUESTIONS:");
          doc.moveDown();

          data.shortQuestions.forEach((q, index) => {
            if (!q?.question) return;

            doc.fontSize(12).text(
              `${index + 1}. ${q.question} (${q.marks || 0} Marks)`
            );

            grandTotal += q.marks || 0;
            doc.moveDown();
          });

          if (data.shortTotalMarks) {
            doc.moveDown();
            doc.text(`Short Section Total: ${data.shortTotalMarks}`);
          }

          doc.moveDown(1);
        }

        // LONG SECTION
        if (Array.isArray(data.longQuestions)) {
          doc.fontSize(14).text("LONG QUESTIONS:");
          doc.moveDown();

          data.longQuestions.forEach((q, index) => {
            if (!q?.question) return;

            doc.fontSize(12).text(
              `${index + 1}. ${q.question} (${q.marks || 0} Marks)`
            );

            grandTotal += q.marks || 0;
            doc.moveDown();
          });

          if (data.longTotalMarks) {
            doc.moveDown();
            doc.text(`Long Section Total: ${data.longTotalMarks}`);
          }
        }

        // GRAND TOTAL
        doc.moveDown(2);
        doc.fontSize(14).text(
          `Grand Total Marks: ${data.grandTotalMarks || grandTotal}`
        );
      }

      // =========================
      // 🟣 SINGLE (SHORT / LONG)
      // =========================
      else if (Array.isArray(data.questions)) {

        let total = 0;

        doc.fontSize(14).text("EXAM QUESTIONS:");
        doc.moveDown();

        data.questions.forEach((q, index) => {
          if (!q?.question) return;

          const marks = q.marks || 0;
          total += marks;

          doc.fontSize(12).text(
            `${index + 1}. ${q.question} (${marks} Marks)`
          );

          doc.moveDown();
        });

        doc.moveDown(1);
        doc.fontSize(12).text(`Total Marks: ${data.totalMarks || total}`);
      }

      // =========================
      // ❌ EMPTY CASE
      // =========================
      else {
        doc.fontSize(12).text("No questions available.");
      }

      doc.end();

      stream.on("finish", () => resolve(filePath));
      stream.on("error", reject);

    } catch (error) {
      reject(error);
    }
  });
};