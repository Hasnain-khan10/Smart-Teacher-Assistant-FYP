import 'package:flutter/material.dart';

class TeacherQuizEvaluationScreen extends StatelessWidget {
  final String studentName;
  final String quizType;
  final int score;
  final int totalMarks;
  final List<dynamic> detailedAnswers;
  final String aiFeedback;

  const TeacherQuizEvaluationScreen({
    super.key,
    required this.studentName,
    required this.quizType,
    required this.score,
    required this.totalMarks,
    this.detailedAnswers = const [],
    this.aiFeedback = "No AI feedback available for this attempt.",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Bilkul clear white background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4F46E5), // Blue app bar for theme consistency
        title: const Text("Student Result", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 1),

              // ================= STUDENT PROFILE & NAME =================
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF4F46E5), width: 3),
                ),
                child: const CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.person, size: 60, color: Color(0xFF4F46E5)),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                studentName.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1B4B),
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                    const SizedBox(width: 6),
                    Text(
                      "AI Evaluated Successfully",
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // ================= OBTAINED MARKS (BLUE) =================
              const Text(
                "OBTAINED MARKS",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5),
              ),
              const SizedBox(height: 5),
              Text(
                "$score",
                style: const TextStyle(
                  fontSize: 90,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F46E5), // Bold Blue Color
                  height: 1.0,
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 80, vertical: 20),
                child: Divider(thickness: 2, color: Colors.grey),
              ),

              // ================= TOTAL MARKS (GREEN) =================
              const Text(
                "TOTAL MARKS",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5),
              ),
              const SizedBox(height: 5),
              Text(
                "$totalMarks",
                style: const TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: Colors.green, // Bold Green Color
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}