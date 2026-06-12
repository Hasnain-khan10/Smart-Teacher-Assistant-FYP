import 'package:flutter/material.dart';

class AiFeedbackScreen extends StatelessWidget {
final int score;
final int total;

const AiFeedbackScreen({
super.key,
this.score = 22,
this.total = 30,
});

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: Colors.white,

  appBar: AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1B4B)),
      onPressed: () => Navigator.pop(context),
    ),
    title: const Text(
      "Quiz Results",
      style: TextStyle(
        color: Color(0xFF1E1B4B),
        fontWeight: FontWeight.bold,
      ),
    ),
    centerTitle: true,
  ),

  body: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [

        /// 🔹 Title
        const Text(
          "Midterm Quiz",
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Introduction to AI",
          style: TextStyle(
            color: Color(0xFF6B7280),
          ),
        ),

        const SizedBox(height: 16),

        /// 🔹 Score
        Text(
          "$score / $total",
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1B4B),
          ),
        ),

        const SizedBox(height: 20),

        /// 🔹 Tips Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// Heading
              const Text(
                "Tips to Improve",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1B4B),
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 12),

              /// Tip 1
              _tipItem("Review the concepts of supervised learning."),

              const SizedBox(height: 10),

              /// Tip 2
              _tipItem("Practice sample questions on neural networks."),

              const SizedBox(height: 10),

              /// Tip 3
              _tipItem("Revisit the basics of regression algorithms."),
            ],
          ),
        ),
      ],
    ),
  ),
);

}

/// 🔹 Tip Item Widget
Widget _tipItem(String text) {
return Row(
children: [
const Icon(
Icons.lightbulb,
color: Color(0xFFF59E0B),
),
const SizedBox(width: 10),
Expanded(
child: Text(
text,
style: const TextStyle(
color: Color(0xFF1E1B4B),
),
),
),
],
);
}
}