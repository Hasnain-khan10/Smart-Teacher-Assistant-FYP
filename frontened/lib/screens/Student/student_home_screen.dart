import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontened/Provider/auth_provider.dart';
import 'package:frontened/Provider/course_provider.dart';
import 'package:frontened/Provider/quiz_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Courses/JoinCourseScreen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});
  static const String routeName = '/student-home';

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  // 🔥 State to hold deleted courses that need acknowledgement
  List<Map<String, String>> _deletedCourseAlerts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ==============================================================
  // 🔥 ULTRA-SMART DATA LOADER & INLINE CARD DELETION DETECTOR
  // ==============================================================
  Future<void> _loadData() async {
    // 1. Fetch fresh data from backend
    await Future.wait([
      context.read<QuizProvider>().fetchAllQuizzes(),
      context.read<CourseProvider>().fetchCourses(),
      context.read<AuthProvider>().loadProfile(),
    ]);

    if (mounted) {
      final courseProvider = context.read<CourseProvider>();

      // 2. SAFETY CHECK: Only compare if API fetch was successful (not an internet error)
      if (courseProvider.error == null) {
        await _syncCacheAndFindDeleted(courseProvider.courses);
      }
    }
  }

  Future<void> _syncCacheAndFindDeleted(List<dynamic> currentCourses) async {
    final authProvider = context.read<AuthProvider>();
    // Student ki unique ID use kar rahe hain, taake logout/login par bhi yaad rakhe!
    final String studentId = authProvider.user?.id ?? "fallback_id";
    final String cacheKey = 'smart_cache_courses_v3_$studentId';

    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString(cacheKey);

    List<Map<String, dynamic>> previousCourses = [];
    if (cachedData != null) {
      try {
        List<dynamic> decoded = jsonDecode(cachedData);
        previousCourses = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        previousCourses = [];
      }
    }

    // Naye aane wale courses ki list
    List<String> currentCourseIds = currentCourses.map((c) => c.id.toString()).toList();
    List<Map<String, String>> newlyDeleted = [];

    // Compare and find missing courses
    for (var prev in previousCourses) {
      String prevId = prev['id'].toString();
      String prevTitle = prev['title'].toString();
      String isDeleted = prev['isDeleted'].toString();

      if (!currentCourseIds.contains(prevId) && isDeleted != "true") {
        // 🔥 TRIGGER: Yeh course pehle tha, ab API se nahi aaya matlab Teacher ne udha diya!
        newlyDeleted.add({"id": prevId, "title": prevTitle, "isDeleted": "true"});
      } else if (isDeleted == "true") {
        // Pehle se delete ho chuka tha par student ne abhi tak "OK" nahi dabaya
        newlyDeleted.add({"id": prevId, "title": prevTitle, "isDeleted": "true"});
      }
    }

    setState(() {
      _deletedCourseAlerts = newlyDeleted;
    });

    // Save fresh list + unacknowledged deleted courses to cache safely
    List<Map<String, dynamic>> newCache = currentCourses.map((c) => {
      "id": c.id.toString(),
      "title": c.title.toString(),
      "isDeleted": "false"
    }).toList();

    newCache.addAll(newlyDeleted); // Red cards ko memory mein zinda rakho jab tak dismiss na hon
    await prefs.setString(cacheKey, jsonEncode(newCache));
  }

  // 🔥 Dismiss the Red Card when Student clicks OK
  Future<void> _dismissDeletedCard(String courseId) async {
    setState(() {
      _deletedCourseAlerts.removeWhere((c) => c['id'] == courseId);
    });

    final authProvider = context.read<AuthProvider>();
    final String studentId = authProvider.user?.id ?? "fallback_id";
    final String cacheKey = 'smart_cache_courses_v3_$studentId';

    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString(cacheKey);

    if (cachedData != null) {
      List<dynamic> cacheList = jsonDecode(cachedData);
      cacheList.removeWhere((c) => c['id'].toString() == courseId);
      await prefs.setString(cacheKey, jsonEncode(cacheList));
    }
  }

  bool _isCompletedSafe(dynamic quiz) => quiz.isCompleted == true;

  @override
  Widget build(BuildContext context) {
    final quizProvider = context.watch<QuizProvider>();
    final authProvider = context.watch<AuthProvider>();
    final students = authProvider.user;
    final courseProvider = context.watch<CourseProvider>();
    final courses = courseProvider.courses;

    final upcomingQuizzes = quizProvider.quizzes.where((q) => !_isCompletedSafe(q)).toList();

    return Scaffold(
      backgroundColor: Colors.white,

      // 🔥 THE DYNAMIC WAVE FLOATING BUTTON FOR "JOIN COURSE"
      floatingActionButton: _AnimatedWaveButton(
        onTap: () => Navigator.pushNamed(context, JoinCourseScreen.routeName).then((_) => _loadData()),
      ),

      // 🔥 PULL TO REFRESH
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF4F46E5),
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= HEADER =================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Hello, ${students?.name ?? "Student"} 👋", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B))),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.school, size: 14, color: Color(0xFF16A34A)),
                              const SizedBox(width: 4),
                              Text("Role: ${students?.role.toUpperCase() ?? 'STUDENT'}", style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFF4F46E5).withOpacity(0.15),
                      backgroundImage: (students?.profileImage != null && students!.profileImage!.isNotEmpty) ? NetworkImage(students.profileImage!) : null,
                      child: (students?.profileImage == null || students!.profileImage!.isEmpty) ? const Icon(Icons.person, color: Color(0xFF4F46E5)) : null,
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // ================= ENROLLED COURSES =================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Enrolled Courses", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                    Text("${courses.length} Active", style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),

                // 🔥 1. SHOW DELETED COURSE ALERTS (RED CARDS) AT THE TOP
                ..._deletedCourseAlerts.map((delCourse) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade300, width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24),
                          const SizedBox(width: 8),
                          Expanded(child: Text("${delCourse['title']} (Removed)", style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 16))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("The instructor has permanently deleted this subject. All associated quizzes and plans are no longer available.", style: TextStyle(color: Colors.red.shade700, fontSize: 13, height: 1.4)),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => _dismissDeletedCard(delCourse['id']!),
                          child: const Text("OK, Got it", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                )),

                // 2. SHOW NORMAL ACTIVE COURSES
                if (courseProvider.isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                else if (courses.isEmpty && _deletedCourseAlerts.isEmpty)
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                    child: const Column(
                      children: [
                        Icon(Icons.menu_book, size: 40, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("No enrolled courses yet.", style: TextStyle(color: Colors.grey)),
                        Text("Tap the floating button below to join.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  )
                else
                  ...courses.take(15).map((course) => CourseCard(title: course.title, progress: course.progress ?? 0.0)),

                const SizedBox(height: 30),

                // ================= PENDING QUIZZES =================
                const Text("Pending Quizzes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                const SizedBox(height: 12),

                if (quizProvider.isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                else if (upcomingQuizzes.isEmpty)
                  const Text("No pending quizzes. Great job!", style: TextStyle(color: Colors.grey))
                else
                  ...upcomingQuizzes.take(5).map((quiz) => QuizCard(title: quiz.title ?? "Untitled Quiz", date: "Due Soon")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedWaveButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AnimatedWaveButton({required this.onTap});
  @override
  State<_AnimatedWaveButton> createState() => _AnimatedWaveButtonState();
}
class _AnimatedWaveButtonState extends State<_AnimatedWaveButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(scale: 1.0 + (_controller.value * 0.4), child: Opacity(opacity: 1.0 - _controller.value, child: Container(width: 65, height: 65, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF16A34A).withOpacity(0.5))))),
              Container(width: 65, height: 65, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF22C55E)]), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]), child: const Icon(Icons.add, color: Colors.white, size: 30)),
            ],
          );
        },
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  final String title;
  final double progress;
  const CourseCard({super.key, required this.title, required this.progress});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [const Icon(Icons.class_, color: Color(0xFF4F46E5), size: 20), const SizedBox(width: 8), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))]),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: progress, color: const Color(0xFF16A34A), backgroundColor: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
        ],
      ),
    );
  }
}

class QuizCard extends StatelessWidget {
  final String title;
  final String date;
  const QuizCard({super.key, required this.title, required this.date});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.shade100)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 4), Text(date, style: const TextStyle(color: Colors.red, fontSize: 12))])),
          const Icon(Icons.assignment_late_outlined, color: Colors.red),
        ],
      ),
    );
  }
}