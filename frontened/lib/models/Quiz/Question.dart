// ================================
// question_model.dart
// ================================

class Question {
  final String question;

  // MCQ ONLY
  final Map<String, String>? options;

  // nullable for printable AI exams
  final String? correctAnswer;

  final int marks;

  Question({
    required this.question,
    this.options,
    this.correctAnswer,
    required this.marks,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      question: json['question'] ?? '',

      options: json['options'] != null
          ? Map<String, String>.from(json['options'])
          : null,

      correctAnswer: json['correctAnswer'],

      marks: json['marks'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "question": question,
      "options": options,
      "correctAnswer": correctAnswer,
      "marks": marks,
    };
  }
}