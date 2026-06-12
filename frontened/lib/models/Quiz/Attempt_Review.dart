// ================================
// attempt_review_model.dart
// ================================

class AttemptReview {

  final String question;

  final String? selectedAnswer;
  final String? correctAnswer;

  final bool isCorrect;
  final bool skipped;

  AttemptReview({
    required this.question,
    this.selectedAnswer,
    this.correctAnswer,
    required this.isCorrect,
    required this.skipped,
  });

  factory AttemptReview.fromJson(Map<String, dynamic> json) {
    return AttemptReview(
      question: json['question'] ?? '',

      selectedAnswer: json['selectedAnswer'],

      correctAnswer: json['correctAnswer'],

      isCorrect: json['isCorrect'] ?? false,

      skipped: json['skipped'] ?? false,
    );
  }
}