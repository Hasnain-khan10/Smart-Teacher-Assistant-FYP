import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontened/Provider/course_provider.dart';
import 'package:frontened/Provider/quiz_provider.dart';

import 'package:frontened/screens/Teacher/Quiz/TeacherQuizPreviewScreen.dart';
import 'package:frontened/screens/Teacher/Quiz/TeacherQuizEvaluationScreen.dart';
import 'package:frontened/screens/Teacher/Quiz/TeacherScannerOverlay.dart';

class TeacherQuizManagementCenter extends StatefulWidget {
  final String quizId;
  final String courseId;
  final String quizTitle;
  final String quizType;
  final int totalMarks;

  const TeacherQuizManagementCenter({
    super.key,
    required this.quizId,
    required this.courseId,
    required this.quizTitle,
    required this.quizType,
    required this.totalMarks,
  });

  @override
  State<TeacherQuizManagementCenter> createState() => _TeacherQuizManagementCenterState();
}

class _TeacherQuizManagementCenterState extends State<TeacherQuizManagementCenter> {
  String _activeView = "results";

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<QuizProvider>().fetchQuizResults(widget.quizId, quizId: widget.quizId);
      context.read<CourseProvider>().fetchCourseStudents(widget.courseId);
    });
  }

  // 🔥 AI AUTO-GRADING FUNCTION (Ab False Success nahi dikhayega!)
  Future<void> _startScanningProcess(BuildContext context, String studentId, String studentName) async {
    final List<File>? scannedPages = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherScannerOverlay(
          studentName: studentName,
          quizTitle: widget.quizTitle,
        ),
      ),
    );

    if (scannedPages != null && scannedPages.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Row(
            children: [
              CircularProgressIndicator(color: Color(0xFF4F46E5)),
              SizedBox(width: 20),
              Expanded(
                child: Text("🤖 AI is evaluating...\nPlease wait, this may take a minute.", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
              ),
            ],
          ),
        ),
      );

      // 1. Send files to AI Backend
      final result = await context.read<QuizProvider>().scanAIQuizMarks(
        courseId: widget.courseId,
        studentId: studentId,
        title: widget.quizTitle,
        files: scannedPages,
      );

      if (mounted) Navigator.pop(context); // Loading dialog band karein

      // 2. CHECK IF ACTUAL RESULT CAME BACK
      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ AI Auto-Grading Completed!"), backgroundColor: Colors.green),
          );

          await context.read<QuizProvider>().fetchQuizResults(widget.quizId, quizId: widget.quizId);
          setState(() => _activeView = "results");
        }
      } else {
        // 🔥 AGAR ERROR AAYA HAI TO YAHAN SHOW HOGA
        final errorMessage = context.read<QuizProvider>().error ?? "Backend failed to process image. Check Node.js console.";
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Scan Failed: $errorMessage"), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = context.watch<QuizProvider>();
    final courseProvider = context.watch<CourseProvider>();

    final results = (quizProvider.quizResults?["results"] as List?) ?? [];
    final enrolledStudents = courseProvider.courseStudents;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4F46E5),
        title: Text(widget.quizTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: () {
                try {
                  final fullQuiz = quizProvider.quizzes.firstWhere((q) => q.id == widget.quizId);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherQuizPreviewScreen(quiz: fullQuiz)));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quiz data is loading..."), backgroundColor: Colors.orange));
                }
              },
              icon: const Icon(Icons.vpn_key, color: Colors.yellowAccent, size: 18),
              label: const Text("View Key", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(backgroundColor: Colors.white12, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Container(
              height: 50,
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  _toggleButton("Results View", "results", Icons.analytics_outlined),
                  _toggleButton("AI Scanning", "scanning", Icons.document_scanner_outlined),
                ],
              ),
            ),
          ),
          Expanded(
            child: _activeView == "results"
                ? _buildResultsList(results)
                : _buildScanningList(enrolledStudents),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, String value, IconData icon) {
    final bool isSelected = _activeView == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeView = value),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? const [BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // RESULTS TAB (🔥 ListTile Removed, Used Safe Custom Row)
  // ==========================================
  Widget _buildResultsList(List results) {
    if (results.isEmpty) return const Center(child: Text("No student attempts recorded yet."));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final r = results[index] ?? {};
        final name = r["name"] ?? "Unknown Student";
        final marks = (r["score"] ?? 0).toInt();
        final evaluatedByAI = r["evaluatedByAI"] ?? false;

        final List detailedAnswers = r["detailedAnswers"] ?? [];
        final String aiFeedback = r["aiFeedback"] ?? "AI has evaluated this paper successfully. Further insights will be available soon.";

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TeacherQuizEvaluationScreen(
                  studentName: name, quizType: widget.quizType, score: marks, totalMarks: widget.totalMarks,
                  detailedAnswers: detailedAnswers, aiFeedback: aiFeedback,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: Color(0xFF4F46E5), child: Icon(Icons.person, color: Colors.white, size: 20)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (evaluatedByAI)
                        const Text("AI Scanned/Evaluated", style: TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text("$marks / ${widget.totalMarks}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // SCANNING TAB (🔥 ListTile Removed, Used Safe Custom Row)
  // ==========================================
  Widget _buildScanningList(List students) {
    if (students.isEmpty) return const Center(child: Text("No students enrolled in this course."));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final s = students[index];
        final studentName = s["name"] ?? "Enrolled Student";
        final studentId = s["_id"] ?? s["id"] ?? "";

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              const CircleAvatar(backgroundColor: Color(0xFF7C3AED), child: Icon(Icons.person_search, color: Colors.white, size: 20)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    const Text("Ready for AI Paper Scanning", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _startScanningProcess(context, studentId, studentName),
                icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                label: const Text("Scan", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}