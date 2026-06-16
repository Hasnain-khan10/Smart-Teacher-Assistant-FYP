import 'package:flutter/material.dart';
import 'package:frontened/models/Quiz/quiz_model.dart';
import 'package:frontened/screens/Student/Main_Screen.dart';

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({super.key});
  static const String routeName = '/quiz-result';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    int score = 0;
    int total = 0;
    List review = [];

    // Case 1: Agar data Map mein aa raha hai
    if (args is Map) {
      score = (args['score'] ?? 0).toInt();
      total = (args['total'] ?? 0).toInt();
      review = args['review'] ?? [];
    }
    // Case 2: Agar pura Quiz Model object aa raha hai
    else if (args is Quiz) {
      score = (args.score ?? 0).toInt();
      total = (args.totalMarks ?? args.questions.length).toInt();

      // ✅ Yahan hum Questions aur Answers ko combine kar rahe hain
      review = (args.selectedAnswers ?? []).asMap().entries.map((e) {
        int index = e.key;
        var ans = e.value; // Yeh student ka answer hai
        var q = args.questions[index]; // Yeh question object hai

        return {
          "question": q.question,
          "selectedAnswer": ans["selectedAnswer"] ?? "",
          "correctAnswer": q.correctAnswer,
          "isCorrect": ans["selectedAnswer"] == q.correctAnswer,
        };
      }).toList();
    }

    // Logic for Summary Stats
    final correct = review.where((e) => e['isCorrect'] == true).length;
    final wrong = review.where((e) => e['isCorrect'] == false && (e['selectedAnswer'] ?? '') != "").length;
    final skipped = review.where((e) => (e['selectedAnswer'] ?? '') == "" || e['selectedAnswer'] == null).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4F46E5),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, MainScreen.routeName, (route) => false),
        ),
        title: const Text("Evaluation Report", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // HEADER SCORE
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF4F46E5),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Column(
              children: [
                const Text("Total Score Achieved", style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 8),
                Text("$score / $total", style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // SUMMARY CARDS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _statCard("Correct", correct, Colors.green),
                const SizedBox(width: 12),
                _statCard("Wrong", wrong, Colors.red),
                const SizedBox(width: 12),
                _statCard("Skipped", skipped, Colors.orange),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Detailed Breakdown", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
            ),
          ),
          const SizedBox(height: 10),

          // LIST OF Q/A
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: review.length,
              itemBuilder: (context, index) {
                final item = review[index];
                final isSkipped = (item['selectedAnswer'] ?? '') == "";
                final isCorrect = item['isCorrect'] ?? false;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSkipped ? Colors.orange.shade200 : (isCorrect ? Colors.green.shade200 : Colors.red.shade200),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Q${index + 1}. ${item['question']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const Divider(height: 20),
                      Text(
                        isSkipped ? "Skipped" : "Your Answer: ${item['selectedAnswer']}",
                        style: TextStyle(
                          color: isSkipped ? Colors.orange : (isCorrect ? Colors.green : Colors.red),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!isCorrect && !isSkipped)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text("Correct Answer: ${item['correctAnswer']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // AI FEEDBACK BUTTON
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/quiz-tips'),
                icon: const Icon(Icons.auto_awesome, color: Colors.white),
                label: const Text("View AI Feedback", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _statCard(String title, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text("$value", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}