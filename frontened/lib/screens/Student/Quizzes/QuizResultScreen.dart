import 'package:flutter/material.dart';
import 'package:frontened/models/Quiz/quiz_model.dart';
import 'package:frontened/screens/Student/Main_Screen.dart';

class QuizResultScreen extends StatefulWidget {
  const QuizResultScreen({super.key});

  static const String routeName = '/quiz-result';

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;

    int score = 0;
    int total = 0;
    List review = [];

    if (args is Map) {
      score = args['score'] ?? 0;
      total = args['total'] ?? 0;
      review = args['review'] ?? [];
    } else if (args is Quiz) {
      score = args.score ?? 0;
      total = args.total ?? args.questions.length;

      review = args.selectedAnswers.asMap().entries.map((e) {
            return {
              "question": args.questions[e.key].question,
              "selectedAnswer": e.value ?? "",
              "correctAnswer": args.questions[e.key].correctAnswer,
              "isCorrect": e.value == args.questions[e.key].correctAnswer,
            };
          }).toList() ??
          [];
    }

    final correct = review.where((e) => e['isCorrect'] == true).length;

    final wrong = review.where((e) =>
        e['isCorrect'] == false && (e['selectedAnswer'] ?? '') != "").length;

    final skipped = review
        .where((e) => (e['selectedAnswer'] ?? '') == "" || e['selectedAnswer'] == null)
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
          context,
          MainScreen.routeName,
         (route) => false,
         ),
        ),
        title: const Text(
          "Quiz Result",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            /// SCORE CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  const Text(
                    "Your Score",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$score / $total",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// SUMMARY
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ResultBox(
                  title: "Correct",
                  value: "$correct",
                  color: AppColors.success,
                ),
                ResultBox(
                  title: "Wrong",
                  value: "$wrong",
                  color: AppColors.error,
                ),
                ResultBox(
                  title: "Skipped",
                  value: "$skipped",
                  color: AppColors.warning,
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Review Answers",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: review.isEmpty
                  ? const Center(child: Text("No review available"))
                  : ListView.builder(
                      itemCount: review.length,
                      itemBuilder: (context, index) {
                        final item = review[index];

                        final isSkipped =
                            (item['selectedAnswer'] ?? '') == "";

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AnswerReviewCard(
                            question: item['question'] ?? '',
                            userAnswer: item['selectedAnswer'] ?? '',
                            correctAnswer: item['correctAnswer'] ?? '',
                            isCorrect: item['isCorrect'] ?? false,
                            isSkipped: isSkipped,
                          ),
                        );
                      },
                    ),
            ),

            /// BUTTON
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/quiz-tips');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    "View AI Feedback",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ================= RESULT BOX =================
class ResultBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const ResultBox({
    super.key,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// ================= ANSWER CARD (UPGRADED) =================
class AnswerReviewCard extends StatelessWidget {
  final String question;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final bool isSkipped;

  const AnswerReviewCard({
    super.key,
    required this.question,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    this.isSkipped = false,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color textColor;

    if (isSkipped) {
      borderColor = AppColors.warning;
      textColor = AppColors.warning;
    } else if (isCorrect) {
      borderColor = AppColors.success;
      textColor = AppColors.success;
    } else {
      borderColor = AppColors.error;
      textColor = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSkipped
                ? "Skipped"
                : "Your Answer: $userAnswer",
            style: TextStyle(color: textColor),
          ),
          const SizedBox(height: 4),
          Text(
            "Correct Answer: $correctAnswer",
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// ================= COLORS =================
class AppColors {
  static const Color primary = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF7C3AED);
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1E1B4B);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
}