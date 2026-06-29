const Course = require("../models/Course");
const User = require("../models/User");

// 🔥 IMPORT GLOBAL CENTRAL NOTIFICATION ENGINE
const NotificationService = require("../services/notificationService");

// ===============================
// CREATE COURSE
// ===============================
exports.createCourse = async (req, res) => {
  try {
    // Strict Guard Code
    if (!req.user || !req.user._id) {
      return res.status(401).json({ success: false, message: "Access Denied: Unauthorized request." });
    }

    if (req.user.role !== "teacher") {
      return res.status(403).json({ success: false, message: "Forbidden: Only instructors can build courses." });
    }

    const { title, courseCode, creditHours, syllabus, books, semester } = req.body;

    if (!title || !courseCode || !creditHours || !semester) {
      return res.status(400).json({
        success: false,
        message: "All fields including semester are required",
      });
    }

    const course = await Course.create({
      title,
      courseCode,
      creditHours,
      syllabus,
      books: books || [],
      semester,
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
      message: "Internal server error occurred",
      error: error.message,
    });
  }
};

// ===============================
// JOIN COURSE
// ===============================
exports.joinCourse = async (req, res) => {
  try {
    if (!req.user || !req.user._id) {
      return res.status(401).json({ success: false, message: "Access Denied: Token validation failed." });
    }

    if (req.user.role !== "student") {
      return res.status(403).json({ success: false, message: "Forbidden: Only students can register." });
    }

    const { code } = req.body;
    if (!code) {
      return res.status(400).json({ success: false, message: "Course token code is required." });
    }

    // Input Sanitization to prevent NoSQL query injections
    const sanitizedCode = String(code).trim();
    const course = await Course.findOne({ joinCode: sanitizedCode });

    if (!course) {
      return res.status(404).json({ success: false, message: "Invalid join code." });
    }

    const alreadyJoined = course.students.some(
      (s) => s.user && s.user.toString() === req.user._id.toString()
    );

    if (alreadyJoined) {
      return res.status(400).json({ success: false, message: "You are already enrolled in this course." });
    }

    course.students.push({
      user: req.user._id,
      progress: 0,
    });

    await course.save();

    try {
      const teacher = await User.findById(course.teacher).lean();
      const student = await User.findById(req.user._id).lean();

      if (teacher && teacher.fcmToken && teacher.fcmToken.trim() !== "") {
        await NotificationService.sendPushNotification(
          teacher.fcmToken,
          "New Student Enrolled 🎓",
          `${student.name || "A student"} has joined your course "${course.title}".`,
          { courseId: course._id.toString(), type: "course" }
        );
      }
    } catch (notifyErr) {
      console.log("Teacher student enrollment notification engine failed:", notifyErr.message);
    }

    return res.status(200).json({
      success: true,
      message: "Joined successfully",
      course: {
        _id: course._id,
        title: course.title,
        progress: 0,
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, error: error.message });
  }
};

// ===============================
// GET COURSE STUDENTS
// ===============================
exports.getCourseStudents = async (req, res) => {
  try {
    if (!req.user || !req.user._id) {
      return res.status(401).json({ success: false, message: "Unauthorized access." });
    }

    if (req.user.role !== "teacher") {
      return res.status(403).json({ success: false, message: "Only teachers can access students logs." });
    }

    const course = await Course.findOne({
      _id: req.params.courseId,
      teacher: req.user._id,
    }).populate("students.user", "name email profileImage");

    if (!course) {
      return res.status(404).json({ success: false, message: "Course scope not found under this account." });
    }

    const students = course.students
      .filter((s) => s.user)
      .map((s) => ({
        _id: s.user._id,
        name: s.user.name,
        email: s.user.email,
        profileImage: s.user.profileImage || "",
        progress: s.progress || 0,
      }));

    return res.status(200).json({
      success: true,
      courseId: course._id,
      totalStudents: students.length,
      students,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: "Server Error", error: error.message });
  }
};

// ===============================
// PREVIEW COURSE
// ===============================
exports.previewCourse = async (req, res) => {
  try {
    const sanitizedCode = String(req.params.code).trim();
    const course = await Course.findOne({ joinCode: sanitizedCode })
      .populate("teacher", "name email")
      .select("-students"); // Security protection: hide student list from link sneak peaks

    if (!course) {
      return res.status(404).json({ success: false, message: "Invalid verification link." });
    }

    return res.json(course);
  } catch (error) {
    return res.status(500).json({ success: false, error: error.message });
  }
};

// ===============================
// GET COURSES
// ===============================
exports.getCourses = async (req, res) => {
  try {
    if (!req.user || !req.user._id) {
      return res.status(401).json({ success: false, message: "Token payload missing." });
    }

    let courses;
    if (req.user.role === "teacher") {
      courses = await Course.find({ teacher: req.user._id })
        .populate("teacher", "name email")
        .lean();
    } else {
      courses = await Course.find({ "students.user": req.user._id })
        .populate("teacher", "name email")
        .lean();
    }

    const formatted = courses.map((course) => {
      const student = course.students?.find(
        (s) => s.user && s.user.toString() === req.user._id.toString()
      );

      return {
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
        progress: student?.progress ?? 0,
      };
    });

    return res.json(formatted);
  } catch (error) {
    return res.status(500).json({ success: false, error: error.message });
  }
};

// ===============================
// GET SINGLE COURSE
// ===============================
exports.getCourseById = async (req, res) => {
  try {
    if (!req.user || !req.user._id) {
      return res.status(401).json({ success: false, message: "Unauthorized." });
    }

    let course;
    if (req.user.role === "teacher") {
      course = await Course.findOne({ _id: req.params.id, teacher: req.user._id });
    } else {
      course = await Course.findById(req.params.id).populate("teacher", "name email");
    }

    if (!course) {
      return res.status(404).json({ success: false, message: "Course records unavailable." });
    }

    const student = course.students?.find(
      (s) => s.user && s.user.toString() === req.user._id.toString()
    );

    return res.json({
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
    return res.status(500).json({ success: false, error: error.message });
  }
};

// ===============================
// UPDATE COURSE
// ===============================
exports.updateCourse = async (req, res) => {
  try {
    if (!req.user || req.user.role !== "teacher") {
      return res.status(403).json({ success: false, message: "Operation forbidden." });
    }

    const course = await Course.findOne({ _id: req.params.id, teacher: req.user._id });
    if (!course) {
      return res.status(404).json({ success: false, message: "Course target not found." });
    }

    const updatedCourse = await Course.findByIdAndUpdate(req.params.id, req.body, { new: true });
    return res.json(updatedCourse);
  } catch (error) {
    return res.status(500).json({ success: false, error: error.message });
  }
};

// ===============================
// DELETE COURSE
// ===============================
exports.deleteCourse = async (req, res) => {
  try {
    if (!req.user || req.user.role !== "teacher") {
      return res.status(403).json({ success: false, message: "Action Unauthorized." });
    }

    const course = await Course.findOne({ _id: req.params.id, teacher: req.user._id });
    if (!course) {
      return res.status(404).json({ success: false, message: "Course scope missing." });
    }

    try {
      const studentIds = course.students.map(s => s.user.toString());
      if (studentIds.length > 0) {
        const users = await User.find({ _id: { $in: studentIds } }).select("fcmToken").lean();
        for (const user of users) {
          if (user.fcmToken && user.fcmToken.trim() !== "") {
            await NotificationService.sendPushNotification(
              user.fcmToken,
              "Course Deleted ⚠️",
              `The instructor has permanently removed/deleted the course "${course.title}".`,
              { courseId: course._id.toString(), type: "course_deleted" }
            );
          }
        }
      }
    } catch (notifyErr) {
      console.log("Delete course notification engine error:", notifyErr.message);
    }

    await course.deleteOne();
    return res.json({ success: true, message: "Deleted successfully" });
  } catch (error) {
    return res.status(500).json({ success: false, error: error.message });
  }
};