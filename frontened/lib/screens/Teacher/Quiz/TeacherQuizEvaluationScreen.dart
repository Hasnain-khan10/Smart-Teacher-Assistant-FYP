import 'package:flutter/material.dart';

class TeacherQuizEvaluationScreen extends StatelessWidget {
  final String studentName;
  final String quizType; // "mcq" or "theory"
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
      backgroundColor: const Color(0xFFF8FAFC), // Modern Light Gray
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4F46E5),
        title: const Text("Student Evaluation", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // ================= HEADER SCORE CARD =================
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF4F46E5),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
            ),
            child: Row(
              children: [
                const CircleAvatar(radius: 35, backgroundColor: Colors.white24, child: Icon(Icons.person, size: 40, color: Colors.white)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(studentName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                        child: Text("Total Score: $score / $totalMarks", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ================= AI FEEDBACK / TIPS SECTION =================
                  const Row(
                    children: [
                      Icon(Icons.smart_toy, color: Color(0xFF1E1B4B)),
                      SizedBox(width: 8),
                      Text("AI Evaluation & Insights", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade100),
                      boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Text(
                      aiFeedback,
                      style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ================= BREAKDOWN SECTION =================
                  Row(
                    children: [
                      const Icon(Icons.receipt_long, color: Color(0xFF1E1B4B)),
                      const SizedBox(width: 8),
                      Text(quizType.toLowerCase() == "mcq" ? "MCQ Responses Breakdown" : "Question Wise Breakdown", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  detailedAnswers.isEmpty
                      ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                    child: const Column(
                      children: [
                        Icon(Icons.hourglass_empty, size: 40, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("Detailed breakdown will appear after scanning.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: detailedAnswers.length,
                    itemBuilder: (context, index) {
                      final ans = detailedAnswers[index];
                      final isCorrect = ans["isCorrect"] ?? false;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isCorrect ? Colors.green.shade200 : Colors.red.shade200),
                            boxShadow: [BoxShadow(color: isCorrect ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(radius: 12, backgroundColor: isCorrect ? Colors.green : Colors.red, child: Text("${index+1}", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                                const SizedBox(width: 12),
                                Expanded(child: Text(ans["question"] ?? "Unknown Question", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: isCorrect ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                  child: Text("${ans["marksObtained"]} Marks", style: TextStyle(color: isCorrect ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                                )
                              ],
                            ),
                            const Divider(height: 30),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(isCorrect ? Icons.check_circle : Icons.cancel, size: 18, color: isCorrect ? Colors.green : Colors.red),
                                const SizedBox(width: 8),
                                Expanded(child: Text("Student's Answer: ${ans["studentAnswer"] ?? ""}", style: TextStyle(color: isCorrect ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.w500))),
                              ],
                            ),
                            if (!isCorrect) ...[
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text("Correct Answer: ${ans["correctAnswer"] ?? ""}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                                ],
                              ),
                            ]
                          ],
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}