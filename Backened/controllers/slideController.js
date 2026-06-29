const Slide = require("../models/Slide");
const Course = require("../models/Course");
const PptxGenJS = require("pptxgenjs");
const cloudinary = require("../config/cloudinary");
const fs = require("fs");

exports.generateSlides = async (req, res) => {
  try {
    // 🔒 SECURITY GUARD ADDED
    if (!req.user || !req.user._id) {
      return res.status(401).json({ success: false, message: "Unauthorized request block." });
    }

    const { courseId, topic } = req.body;

    const course = await Course.findOne({
      _id: courseId,
      teacher: req.user._id,
    });

    if (!course) {
      return res.status(404).json({ message: "Course not found" });
    }

    // Dummy Slide Generator
    let slides = [];

    for (let i = 1; i <= 5; i++) {
      slides.push({
        title: `${topic} - Slide ${i}`,
        content: [
          `Point 1 about ${topic}`,
          `Point 2 about ${topic}`,
          `Point 3 about ${topic}`,
        ],
      });
    }

    const slideDoc = await Slide.create({
      course: courseId,
      teacher: req.user._id,
      topic,
      slides,
    });

    res.status(201).json({
      message: "Slides generated successfully",
      slideDoc,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getSlidesByCourse = async (req, res) => {
  try {
    // 🔒 SECURITY GUARD ADDED
    if (!req.user || !req.user._id) {
      return res.status(401).json({ success: false, message: "Unauthorized request block." });
    }

    let slides;

    // 👨‍🏫 Teacher → only their slides
    if (req.user.role === "teacher") {
      slides = await Slide.find({
        course: req.params.courseId,
        teacher: req.user._id,
      });
    }

    // 👨‍🎓 Student → all slides of that course
    if (req.user.role === "student") {
      slides = await Slide.find({
        course: req.params.courseId,
      }).populate("teacher", "name email");
    }

    res.json(slides);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.exportSlidesToPPT = async (req, res) => {
  try {
    // 🔒 SECURITY GUARD ADDED
    if (!req.user || !req.user._id) {
      return res.status(401).json({ success: false, message: "Unauthorized request block." });
    }

    const slideDoc = await Slide.findOne({
      _id: req.params.id,
      teacher: req.user._id,
    });

    if (!slideDoc) {
      return res.status(404).json({ message: "Slides not found" });
    }

    let pptx = new PptxGenJS();

    slideDoc.slides.forEach((s) => {
      let slide = pptx.addSlide();

      slide.addText(s.title, {
        x: 1,
        y: 0.5,
        fontSize: 24,
        bold: true,
      });

      slide.addText(s.content.join("\n"), {
        x: 1,
        y: 1.5,
        fontSize: 16,
      });
    });

    const filePath = `./temp_${Date.now()}.pptx`;

    await pptx.writeFile({ fileName: filePath });

    // Upload to Cloudinary
    const result = await cloudinary.uploader.upload(filePath, {
      resource_type: "raw",
    });

    // Save URL
    slideDoc.pptUrl = result.secure_url;
    await slideDoc.save();

    // Delete local file
    fs.unlinkSync(filePath);

    res.json({
      message: "PPT generated and uploaded",
      pptUrl: result.secure_url,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updateSlides = async (req, res) => {
  try {
    // 🔒 SECURITY GUARD ADDED
    if (!req.user || !req.user._id) {
      return res.status(401).json({ success: false, message: "Unauthorized request block." });
    }

    const slide = await Slide.findOne({
      _id: req.params.id,
      teacher: req.user._id,
    });

    if (!slide) {
      return res.status(404).json({ message: "Slides not found" });
    }

    slide.slides = req.body.slides || slide.slides;

    await slide.save();

    res.json({
      message: "Slides updated successfully",
      slide,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.deleteSlides = async (req, res) => {
  try {
    // 🔒 SECURITY GUARD ADDED
    if (!req.user || !req.user._id) {
      return res.status(401).json({ success: false, message: "Unauthorized request block." });
    }

    const slide = await Slide.findOne({
      _id: req.params.id,
      teacher: req.user._id,
    });

    if (!slide) {
      return res.status(404).json({ message: "Slides not found" });
    }

    await slide.deleteOne();

    res.json({ message: "Slides deleted successfully" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};