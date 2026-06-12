const PDFDocument = require("pdfkit");
const fs = require("fs");

exports.generateCoursePDF = (data, filePath) => {
  return new Promise((resolve) => {
    const doc = new PDFDocument({ margin: 50 });

    doc.pipe(fs.createWriteStream(filePath));

    // Title
    doc.fontSize(20).text(data.title, { align: "center" });
    doc.moveDown();

    // Description
    doc.fontSize(12).text(data.description);
    doc.moveDown();

    // Modules
    data.modules.forEach((module, index) => {
      doc.fontSize(14).text(`Module ${index + 1}: ${module.title}`);
      doc.moveDown(0.5);

      module.topics.forEach((topic) => {
        doc.fontSize(12).text(`• ${topic}`);
      });

      doc.moveDown();
    });

    doc.end();
    resolve(filePath);
  });
};