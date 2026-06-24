import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontened/Provider/auth_provider.dart';
import 'package:frontened/Provider/course_provider.dart';
import 'package:frontened/Provider/quiz_provider.dart';
import 'package:provider/provider.dart';
import 'package:frontened/screens/Student/Courses/JoinCourseScreen.dart';
import 'package:frontened/screens/Student/Profile/ProfileScreen.dart';
import 'package:intl/intl.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});
  static const String routeName = '/student-home';

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  Timer? _homeTimer;

  @override
  void initState() {
    super.initState();
    _loadData();

    _homeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _homeTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      context.read<QuizProvider>().fetchAllQuizzes(),
      context.read<CourseProvider>().fetchCourses(),
      context.read<AuthProvider>().loadProfile(),
    ]);
  }

  DateTime? _getSafeDate(dynamic quiz, String field) {
    try {
      dynamic raw = (quiz as dynamic).toJson()[field];
      if (raw == null) return null;
      if (raw is DateTime) return raw;
      return DateTime.tryParse(raw.toString());
    } catch (e) {
      return null;
    }
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return "00:00:00";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String days = d.inDays > 0 ? "${d.inDays}d " : "";
    String hours = twoDigits(d.inHours.remainder(24));
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$days$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = context.watch<QuizProvider>();
    final authProvider = context.watch<AuthProvider>();
    final student = authProvider.user;
    final courseProvider = context.watch<CourseProvider>();
    final courses = courseProvider.courses;
    final now = DateTime.now();

    final pendingQuizzes = quizProvider.quizzes.where((q) {
      if (q.isCompleted == true) return false;
      final deadline = _getSafeDate(q, 'deadlineDateTime');
      if (deadline != null && now.isAfter(deadline)) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const Text("Pending Quizzes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                const SizedBox(height: 12),
                if (quizProvider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (pendingQuizzes.isEmpty)
                  const Text("No pending quizzes.", style: TextStyle(color: Colors.grey))
                else
                  ...pendingQuizzes.map((quiz) {
                    final openDate = _getSafeDate(quiz, 'openDateTime');
                    final deadline = _getSafeDate(quiz, 'deadlineDateTime');
                    final isLocked = openDate != null && now.isBefore(openDate);

                    return GestureDetector(
                      onTap: () {
                        if (isLocked) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Exam Locked! This exam unlocks at ${DateFormat('hh:mm a, dd MMM').format(openDate)}"),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                              )
                          );
                        } else {
                          Navigator.pushNamed(context, '/quiz-attempt', arguments: quiz);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isLocked ? Colors.grey.withOpacity(0.08) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isLocked ? Colors.grey.shade300 : Colors.red.shade100, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Icon(isLocked ? Icons.lock : Icons.assignment_late_outlined, color: isLocked ? Colors.grey : Colors.red, size: 24),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      quiz.title ?? "Quiz",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontWeight: FontWeight.bold, color: isLocked ? Colors.grey : const Color(0xFF1E1B4B))
                                  ),
                                  const SizedBox(height: 4),
                                  if (isLocked)
                                    Text("Unlocks: ${DateFormat('dd MMM, hh:mm a').format(openDate!)}", style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold))
                                  else if (deadline != null)
                                    Text("Ends in: ${_formatDuration(deadline.difference(now))}", style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold))
                                  else
                                    const Text("Active Now", style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Icon(isLocked ? Icons.lock_outline : Icons.chevron_right, color: isLocked ? Colors.grey : Colors.red, size: 20),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}