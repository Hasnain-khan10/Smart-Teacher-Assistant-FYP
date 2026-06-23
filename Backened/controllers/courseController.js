const Course = require("../models/Course");


// ===============================
// CREATE COURSE
// ===============================
exports.createCourse = async (req, res) => {
  try {
    const { title, courseCode, creditHours, syllabus, books, semester } = req.body;

    if (!req.user) {
      return res.status(401).json({ message: "Unauthorized" });
    }

    if (req.user.role !== "teacher") {
      return res.status(403).json({ message: "Only teachers can create courses" });
    }

    if (!title || !courseCode || !creditHours  || !semester) {
      return res.status(400).json({
        message: "All fields including semester are required",
      });
    }

    const course = await Course.create({
      title,
      courseCode,
      creditHours,
      syllabus,
      books: books || [],
      semester, // ✅ FROM TEACHER INPUT
      teacher: req.user._id,
    });

    const joinLink = `${req.protocol}://${req.get("host")}/api/courses/join/${course.joinCode}`;

    return res.status(201).json({
  success: true,
  message: "Course created successfully",

  course: {
    _id: course._id,
    title: course.title,
    courseCode: course.courseCode,
    creditHours: course.creditHours,
    syllabus: course.syllabus,
    books: course.books,
    semester: course.semester,
    teacher: course.teacher,
    joinCode: course.joinCode,
    joinLink,
  },
});

  } catch (error) {
    return res.status(500).json({
      success: false,
      error: error.message,
    });
  }
};



// ===============================
// JOIN COURSE
// ===============================
exports.joinCourse = async (req, res) => {
  try {
    const { code } = req.body;

    if (!req.user) {
      return res.status(401).json({ message: "Unauthorized" });
    }

    if (req.user.role !== "student") {
      return res.status(403).json({ message: "Only students can join" });
    }

    const course = await Course.findOne({ joinCode: code });

    if (!course) {
      return res.status(404).json({ message: "Invalid join code" });
    }

    const alreadyJoined = course.students.some(
      (s) => s.user.toString() === req.user._id.toString()
    );

    if (alreadyJoined) {
      return res.status(400).json({ message: "Already enrolled" });
    }

    course.students.push({
      user: req.user._id,
      progress: 0,
    });

    await course.save();

    console.log("BODY:", req.body);
console.log("JOIN CODE:", req.body.code || req.body.joinCode);

    res.status(200).json({
      success: true,
      message: "Joined successfully",
      course: {
        _id: course._id,
        title: course.title,
        progress: 0,
      },
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};


// ===============================
// GET COURSE STUDENTS (ONLY ENROLLED)
// ===============================
exports.getCourseStudents = async (req, res) => {
  try {
    // =========================
    // AUTH CHECK
    // =========================
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: "Unauthorized",
      });
    }

    // =========================
    // ONLY TEACHER ALLOWED
    // =========================
    if (req.user.role !== "teacher") {
      return res.status(403).json({
        success: false,
        message: "Only teachers can access students",
      });
    }

    // =========================
    // FIND COURSE (OWNER ONLY)
    // =========================
    const course = await Course.findOne({
  _id: req.params.courseId,
  teacher: req.user._id,
}).populate("students.user", "name email profileImage");

    if (!course) {
      return res.status(404).json({
        success: false,
        message: "Course not found",
      });
    }

    // =========================
    // EXTRACT ONLY ENROLLED STUDENTS
    // =========================
    const students = course.students
      .filter((s) => s.user) // safety check
      .map((s) => ({
        _id: s.user._id,
        name: s.user.name,
        email: s.user.email,
        profileImage: s.user.profileImage || "",
        progress: s.progress || 0,
      }));

      console.log(course.students);

      console.log("COURSE FOUND:", course);
console.log("STUDENTS RAW:", course.students);

    // =========================
    // RESPONSE
    // =========================
    return res.status(200).json({
      success: true,
      courseId: course._id,
      totalStudents: students.length,
      students,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Server Error",
      error: error.message,
    });
  }
};



// ===============================
// PREVIEW COURSE
// ===============================
exports.previewCourse = async (req, res) => {
  try {
    const course = await Course.findOne({
      joinCode: req.params.code,
    }).populate("teacher", "name email");

    if (!course) {
      return res.status(404).json({ message: "Invalid link" });
    }

    res.json(course);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};



// ===============================
// GET COURSES
// ===============================
exports.getCourses = async (req, res) => {
  try {
    let courses;

    if (req.user.role === "teacher") {
  courses = await Course.find({ teacher: req.user._id })
    .populate("teacher", "name email")
    .lean();
   }
    else {
      courses = await Course.find({
        "students.user": req.user._id,
      })
      .populate("teacher", "name email")
      .lean(); // ✅ IMPORTANT
    }

    const formatted = courses.map((course) => {
      const student = course.students?.find(
        (s) => s.user.toString() === req.user._id.toString()
      );

      return {
        _id: course._id,
      title: course.title,
      courseCode: course.courseCode,
      creditHours: course.creditHours,
      syllabus: course.syllabus,
      books: course.books,
      joinLink: `${req.protocol}://${req.get("host")}/api/courses/join/${course.joinCode}`,
      semester: course.semester, // ✅ FIXED
      joinCode: course.joinCode,
      teacher: course.teacher,
      progress: student?.progress ?? 0,
      };
    });

    res.json(formatted);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ===============================
// GET SINGLE COURSE
// ===============================
exports.getCourseById = async (req, res) => {
  try {
    let course;

    if (req.user.role === "teacher") {
      course = await Course.findOne({
        _id: req.params.id,
        teacher: req.user._id,
      });
    }
    else {
      course = await Course.findById(req.params.id)
        .populate("teacher", "name email");
    }

    if (!course) {
      return res.status(404).json({ message: "Course not found" });
    }

    const student = course.students?.find(
  (s) => s.user && s.user.toString() === req.user._id.toString()
);

   res.json({
  _id: course._id,
  title: course.title,
  courseCode: course.courseCode,
  creditHours: course.creditHours,
  syllabus: course.syllabus,
  books: course.books,
  joinLink: `${req.protocol}://${req.get("host")}/api/courses/join/${course.joinCode}`,
  semester: course.semester,
  joinCode: course.joinCode,
  teacher: course.teacher,
  progress: student ? student.progress : 0,
});

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};


// ===============================
// UPDATE COURSE
// ===============================
exports.updateCourse = async (req, res) => {
  try {
    const course = await Course.findOne({
      _id: req.params.id,
      teacher: req.user._id,
    });

    if (!course) {
      return res.status(404).json({ message: "Course not found" });
    }

    const updatedCourse = await Course.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );

    res.json(updatedCourse);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};



// ===============================
// DELETE COURSE
// ===============================
exports.deleteCourse = async (req, res) => {
  try {
    const course = await Course.findOne({
      _id: req.params.id,
      teacher: req.user._id,
    });

    if (!course) {
      return res.status(404).json({ message: "Course not found" });
    }

    await course.deleteOne();

    res.json({ message: "Deleted successfully" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};