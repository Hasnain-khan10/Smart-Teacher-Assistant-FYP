import 'package:flutter/material.dart';
import 'package:frontened/Provider/auth_provider.dart';
import 'package:frontened/Provider/course_provider.dart';
import 'package:frontened/Provider/quiz_provider.dart';
import 'package:provider/provider.dart';
import 'package:frontened/screens/Student/Courses/JoinCourseScreen.dart';
import 'package:frontened/screens/Student/Profile/ProfileScreen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});
  static const String routeName = '/student-home';

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      context.read<QuizProvider>().fetchAllQuizzes(),
      context.read<CourseProvider>().fetchCourses(),
      context.read<AuthProvider>().loadProfile(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = context.watch<QuizProvider>();
    final authProvider = context.watch<AuthProvider>();
    final student = authProvider.user;
    final courseProvider = context.watch<CourseProvider>();
    final courses = courseProvider.courses;
    final pendingQuizzes = quizProvider.quizzes.where((q) => q.isCompleted != true).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // Plus button green wave design remains same
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, JoinCourseScreen.routeName).then((_) => _loadData()),
        backgroundColor: const Color(0xFF16A34A),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF4F46E5),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔥 TOP HEADER: Profile on Top-Left
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentProfileScreen())),
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: const Color(0xFF4F46E5).withAlpha(40),
                        backgroundImage: (student?.profileImage != null && student!.profileImage!.isNotEmpty) ? NetworkImage(student.profileImage!) : null,
                        child: (student?.profileImage == null || student!.profileImage!.isEmpty) ? const Icon(Icons.person, color: Color(0xFF4F46E5)) : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Hello, ${student?.name ?? 'Student'} 👋", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Text("Student Dashboard", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // 🔥 ENROLLED COURSES SECTION
                const Text("Enrolled Courses", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                const SizedBox(height: 15),
                if (courseProvider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (courses.isEmpty)
                  const Center(child: Text("No courses joined yet.", style: TextStyle(color: Colors.grey)))
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.3,
                    ),
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      return GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/course-detail', arguments: course),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white, borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.menu_book_rounded, color: Color(0xFF4F46E5), size: 30),
                              const SizedBox(height: 10),
                              Text(course.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 35),

                // 🔥 PENDING QUIZZES SECTION
                const Text("Pending Quizzes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                const SizedBox(height: 12),
                if (quizProvider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (pendingQuizzes.isEmpty)
                  const Text("No pending quizzes.", style: TextStyle(color: Colors.grey))
                else
                  ...pendingQuizzes.map((quiz) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade100)),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(quiz.title ?? "Quiz", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("Due Soon", style: TextStyle(color: Colors.red, fontSize: 12)),
                      trailing: const Icon(Icons.assignment_late_outlined, color: Colors.red),
                    ),
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}