class Quiz {
  final String id;
  final String title;
  final String description;
  final String type;
  final int totalMarks;
  final List<McqQuestion> questions;
  final List<SubjectiveQuestion> shortQuestions;
  final List<SubjectiveQuestion> longQuestions;
  final bool isAIScanned;

  // 🔥 NEW FIELDS TO FIX YOUR ERRORS
  final String? course;       // Required for course filtering
  final bool isCompleted;     // Required for QuizzesScreen
  final num? score;           // Required for results
  final List<dynamic>? selectedAnswers; // Required for results
  final bool? evaluatedByAI;  // Required for UI logic

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.totalMarks,
    required this.questions,
    required this.shortQuestions,
    required this.longQuestions,
    required this.isAIScanned,
    this.course,
    this.isCompleted = false,
    this.score,
    this.selectedAnswers,
    this.evaluatedByAI,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['_id'] ?? '',
      title: json['title'] ?? 'Untitled Quiz',
      description: json['description'] ?? '',
      type: json['type'] ?? 'mcq',
      totalMarks: json['totalMarks'] ?? 0,
      isAIScanned: json['isAIScanned'] ?? false,

      // Fixed Fields for existing screens
      course: json['course'] is Map ? json['course']['_id'] : json['course'], // Handle populate vs ID
      isCompleted: json['isCompleted'] ?? false,
      score: json['score'],
      selectedAnswers: json['answers'] ?? json['selectedAnswers'],
      evaluatedByAI: json['evaluatedByAI'] ?? false,

      questions: (json['questions'] as List?)?.map((q) => McqQuestion.fromJson(q)).toList() ?? [],
      shortQuestions: (json['shortQuestions'] as List?)?.map((q) => SubjectiveQuestion.fromJson(q)).toList() ?? [],
      longQuestions: (json['longQuestions'] as List?)?.map((q) => SubjectiveQuestion.fromJson(q)).toList() ?? [],
    );
  }
}

class McqQuestion {
  final String question;
  final Map<String, String> options;
  final String correctAnswer;
  final String explanation;
  final int marks;

  McqQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.marks,
  });

  factory McqQuestion.fromJson(Map<String, dynamic> json) {
    return McqQuestion(
      question: json['question'] ?? '',
      options: Map<String, String>.from(json['options'] ?? {}),
      correctAnswer: json['correctAnswer'] ?? '',
      explanation: json['explanation'] ?? '',
      marks: json['marks'] ?? 1,
    );
  }
}

class SubjectiveQuestion {
  final String question;
  final int marks;
  final String idealAnswer;
  final String rubric;

  SubjectiveQuestion({
    required this.question,
    required this.marks,
    required this.idealAnswer,
    required this.rubric,
  });

  factory SubjectiveQuestion.fromJson(Map<String, dynamic> json) {
    return SubjectiveQuestion(
      question: json['question'] ?? '',
      marks: json['marks'] ?? 0,
      idealAnswer: json['idealAnswer'] ?? '',
      rubric: json['rubric'] ?? '',
    );
  }
}