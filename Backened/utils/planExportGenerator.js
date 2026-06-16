const PDFDocument = require("pdfkit");
const docx = require("docx");
const PptxGenJS = require("pptxgenjs");
const fs = require("fs");

exports.generatePlanDocument = async (data, format, filePath) => {
  if (format === "PDF") {
    return new Promise((resolve, reject) => {
      try {
        const doc = new PDFDocument({ margin: 50, size: "A4" });
        const stream = fs.createWriteStream(filePath);
        doc.pipe(stream);

        doc.fontSize(22).font("Helvetica-Bold").text(data.title || "18-Week Lecture Plan", { align: "center" });
        doc.moveDown(0.5);
        doc.fontSize(12).font("Helvetica").fillColor("#555").text(data.description || "", { align: "center" });
        doc.moveDown(2);

        (data.weeks || []).forEach((week) => {
          if (doc.y > 650) doc.addPage();
          doc.fontSize(16).font("Helvetica-Bold").fillColor("#000").text(`Week ${week.weekNumber}: ${week.title}`);
          doc.moveDown(0.5);

          doc.fontSize(12).font("Helvetica-Bold").text("Definition:");
          doc.font("Helvetica").text(week.definition || "N/A", { indent: 10, align: "justify" });
          doc.moveDown(0.5);

          doc.font("Helvetica-Bold").text("Deep Explanation:");
          doc.font("Helvetica").text(week.detailedExplanation || "N/A", { indent: 10, align: "justify" });
          doc.moveDown(0.5);

          if (week.codeOrQuerySnippet) {
            doc.font("Courier").fillColor("blue").text(week.codeOrQuerySnippet, { indent: 15 });
            doc.fillColor("#000").moveDown(0.5);
          }

          doc.font("Helvetica-Bold").text("Real-World Analogy:");
          doc.font("Helvetica").text(week.realWorldAnalogy || "N/A", { indent: 10, italic: true });
          doc.moveDown(1);
          doc.moveTo(50, doc.y).lineTo(550, doc.y).strokeColor("#eeeeee").stroke();
          doc.moveDown(1);
        });

        doc.end();
        stream.on("finish", () => resolve(filePath));
        stream.on("error", reject);
      } catch (e) { reject(e); }
    });
  }

  else if (format === "DOCX") {
    const { Document, Packer, Paragraph, TextRun, HeadingLevel } = docx;
    const children = [
      new Paragraph({ text: data.title || "18-Week Lecture Plan", heading: HeadingLevel.TITLE, alignment: docx.AlignmentType.CENTER }),
      new Paragraph({ text: data.description || "", alignment: docx.AlignmentType.CENTER }),
    ];

    (data.weeks || []).forEach((week) => {
      children.push(new Paragraph({ text: `Week ${week.weekNumber}: ${week.title}`, heading: HeadingLevel.HEADING_1, spacing: { before: 400, after: 200 } }));
      children.push(new Paragraph({ children: [new TextRun({ text: "Definition: ", bold: true }), new TextRun(week.definition || "")] }));
      children.push(new Paragraph({ children: [new TextRun({ text: "Explanation: ", bold: true })] }));
      children.push(new Paragraph({ text: week.detailedExplanation || "", alignment: docx.AlignmentType.JUSTIFIED }));

      if (week.codeOrQuerySnippet) {
        children.push(new Paragraph({ text: "Code Snippet:", spacing: { before: 200 } }));
        children.push(new Paragraph({ text: week.codeOrQuerySnippet, font: "Courier New", color: "0000FF" }));
      }

      children.push(new Paragraph({ children: [new TextRun({ text: "Analogy: ", bold: true, italics: true }), new TextRun({ text: week.realWorldAnalogy || "", italics: true })], spacing: { before: 200 } }));
    });

    const doc = new Document({ sections: [{ children }] });
    const buffer = await Packer.toBuffer(doc);
    fs.writeFileSync(filePath, buffer);
    return filePath;
  }

  else if (format === "PPT") {
    let pptx = new PptxGenJS();
    let titleSlide = pptx.addSlide();
    titleSlide.addText(data.title || "18-Week Lecture Plan", { x: 1, y: 2, fontSize: 32, bold: true, align: "center" });

    (data.weeks || []).forEach((week) => {
      let slide = pptx.addSlide();
      slide.addText(`Week ${week.weekNumber}: ${week.title}`, { x: 0.5, y: 0.5, fontSize: 24, bold: true, color: "003366" });
      slide.addText(`Definition:\n${week.definition || ""}`, { x: 0.5, y: 1.5, fontSize: 14, w: "90%" });
      if (week.codeOrQuerySnippet) {
        slide.addText(`Code/Query:\n${week.codeOrQuerySnippet}`, { x: 0.5, y: 3.0, fontSize: 12, fontFace: "Courier New", color: "0000FF", w: "90%", fill: { color: "E8E8E8" } });
      }
      slide.addText(`Analogy: ${week.realWorldAnalogy || ""}`, { x: 0.5, y: 4.5, fontSize: 12, italic: true, w: "90%" });
    });

    await pptx.writeFile({ fileName: filePath });
    return filePath;
  }
};