import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontened/Provider/course_provider.dart';
import 'package:frontened/models/Quiz/quiz_model.dart';
import 'package:frontened/models/course_model.dart';
import 'package:frontened/screens/Teacher/Courses/CourseDetailScreen.dart';
import 'package:provider/provider.dart';

class TeacherCreateCourseScreen extends StatefulWidget {
  static const String createCourse = '/create-course';
  final List<Quiz> quiz;

  const TeacherCreateCourseScreen({super.key, required this.quiz});

  @override
  State<TeacherCreateCourseScreen> createState() =>
      _TeacherCreateCourseScreenState();
}

class _TeacherCreateCourseScreenState
    extends State<TeacherCreateCourseScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController creditController = TextEditingController();
  final TextEditingController instructorController = TextEditingController();

  String? selectedSemester;
  String? joinLink;

  final List<String> semesters =
  List.generate(8, (i) => "Semester ${i + 1}");

  Future<void> createCourse() async {
    final provider = Provider.of<CourseProvider>(context, listen: false);

    if (nameController.text.isEmpty ||
        codeController.text.isEmpty ||
        creditController.text.isEmpty ||
        selectedSemester == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    final course = CourseModel(
      id: "",
      title: nameController.text,
      courseCode: codeController.text,
      creditHours: int.parse(creditController.text),
      syllabus: "",
      books: [],
      progress: 0,
      semester: selectedSemester,
    );

    final createdCourse = await provider.createCourse(course);

    if (createdCourse != null) {
      setState(() {
        joinLink = provider.joinLink;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Course Created Successfully"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      nameController.clear();
      codeController.clear();
      creditController.clear();
      instructorController.clear();
      selectedSemester = null;

      Future.delayed(const Duration(milliseconds: 300), () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherCourseDetailScreen(
              courseId: createdCourse.id,
              quiz: widget.quiz,
            ),
          ),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? "Failed")),
      );
    }
  }

  void copyLink() {
    if (joinLink != null) {
      Clipboard.setData(ClipboardData(text: joinLink!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Copied")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CourseProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white, /// 🔥 PURE WHITE ENFORCED
      resizeToAvoidBottomInset: true,
      body: Container(
        color: Colors.white, /// 🔥 PURPLE GRADIENT COMPLETELY REMOVED
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// HEADER
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child:
                        const Icon(Icons.arrow_back_ios, size: 20, color: Colors.black87),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Create New Course",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Text("Enter course details", style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 18),

                  /// FORM WITH CLEAN ACCENTS
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        _inputField("Course Name", nameController),
                        const SizedBox(height: 14),
                        _inputField("Course Code", codeController),
                        const SizedBox(height: 14),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300, width: 1.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedSemester,
                              dropdownColor: Colors.white,
                              style: const TextStyle(color: Colors.black87, fontSize: 16),
                              hint: const Text("Select Semester", style: TextStyle(color: Colors.black45)),
                              isExpanded: true,
                              items: semesters
                                  .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ))
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  selectedSemester = val;
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),
                        _inputField("Credit Hours", creditController),
                        const SizedBox(height: 14),
                        _inputField("Instructor Name", instructorController),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: provider.isCreating ? null : createCourse,
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.deepPurple, Colors.purple],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: provider.isCreating
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : const Text(
                          "Create Course",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// JOIN LINK CONTAINER
                  if (joinLink != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Join Link:",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 8),
                          SelectableText(joinLink!, style: const TextStyle(color: Colors.black87)),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: copyLink,
                            child: const Text("Copy"),
                          )
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  /// COURSE DETAIL BUTTON
                  if (provider.selectedCourse != null)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TeacherCourseDetailScreen(
                                  courseId:
                                  provider.selectedCourse!.id,
                                  quiz: widget.quiz,
                                ),
                          ),
                        );
                      },
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: Colors.deepPurple, width: 1.5),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_stories,
                                  color: Colors.deepPurple),
                              SizedBox(width: 8),
                              Text(
                                "Go to Course Detail (18 Week Plan)",
                                style: TextStyle(
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(String hint, TextEditingController controller) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black45),
          border: InputBorder.none,
        ),
      ),
    );
  }
}