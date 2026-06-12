import 'package:flutter/material.dart';
import 'package:frontened/Provider/course_provider.dart';
import 'package:frontened/main.dart';
import 'package:frontened/models/Quiz/quiz_model.dart';
import 'package:frontened/models/course_model.dart';
import 'package:frontened/screens/Teacher/Courses/CourseMainScreen.dart';
import 'package:frontened/screens/Teacher/Courses/GenerateAIPlanScreen.dart' show TeacherGenerateAIPlanScreen;
import 'package:frontened/screens/Teacher/Courses/Student%20show%20screen.dart';
import 'package:provider/provider.dart';

class TeacherCourseDetailScreen extends StatefulWidget {
  static const String courseDetail = '/course-detail';

  final String courseId;
  final List<Quiz> quiz;

  const TeacherCourseDetailScreen({
    super.key,
    required this.courseId,
    required this.quiz,
  });

  @override
  State<TeacherCourseDetailScreen> createState() =>
      _TeacherCourseDetailScreenState();
}

class _TeacherCourseDetailScreenState extends State<TeacherCourseDetailScreen> {
  bool _loading = true;
  CourseModel? course;

  @override
  void initState() {
    super.initState();
    _loadCourse();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      await context
          .read<CourseProvider>()
          .fetchCourseStudents(widget.courseId);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _loadCourse() async {
    await Future.delayed(Duration.zero);

    final provider = context.read<CourseProvider>();

    await provider.fetchCourseById(widget.courseId);

    setState(() {
      course = provider.selectedCourse;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizCount = widget.quiz.length;
    final studentsCount = context.watch<CourseProvider>().courseStudents.length;
    final weeks = 18;

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          /// ================= HEADER =================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
                top: 50, left: 20, right: 20, bottom: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// BACK + TITLE
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Course Detail",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),

                const SizedBox(height: 18),

                /// COURSE NAME
                Text(
                  course?.title ?? "N/A",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "${course?.teacherName ?? 'Teacher'} • ${course?.semester ?? 'Semester'}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Code: ${course?.courseCode ?? 'N/A'}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          /// ================= BODY =================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  /// STATS
                  Row(
                    children: [
                      Expanded(
                          child: _statCard("$studentsCount", "Students")),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _statCard("$quizCount", "Quizzes")),
                      const SizedBox(width: 10),
                      Expanded(child: _statCard("$weeks", "Weeks")),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// ACTION GRID
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.1,
                      children: [
                        _actionCard(
                          icon: Icons.auto_awesome,
                          title: "AI Plan",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TeacherGenerateAIPlanScreen(
                                      courseId: widget.courseId,
                                    ),
                              ),
                            );
                          },
                        ),
                        _actionCard(
                          icon: Icons.people,
                          title: "Students",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudentsScreen(
                                  courseId: widget.courseId,
                                  quiz: widget.quiz,
                                ),
                              ),
                            );
                          },
                        ),
                        // _actionCard(
                        //   icon: Icons.document_scanner,
                        //   title: "Scan Quiz",
                        //   onTap: () {
                        //     Navigator.push(
                        //       context,
                        //       MaterialPageRoute(
                        //         builder: (_) =>
                        //             TeacherScanQuizScreen(),
                        //       ),
                        //     );
                        //   },
                        // ),
                        _actionCard(
                          icon: Icons.quiz,
                          title: "AI Course PDF",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TeacherCourseMainScreen(
                                  courseId: widget.courseId,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= STAT CARD =================
  Widget _statCard(String number, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            number,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// ================= ACTION CARD =================
  Widget _actionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.secondary.withValues(alpha: 0.2),
              AppColors.primary.withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: AppColors.primary),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            )
          ],
        ),
      ),
    );
  }
}