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
  final DateTime? createdAt;

  final String? course;
  final bool isCompleted;
  final num? score;
  final List<dynamic>? selectedAnswers;
  final bool? evaluatedByAI;
  final List<String>? scannedPaperUrls;

  // 🔥 NEW MIT/CAMBRIDGE STANDARD SECURITIES FIELDS
  final DateTime? openDateTime;
  final DateTime? deadlineDateTime;

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
    this.createdAt,
    this.course,
    this.isCompleted = false,
    this.score,
    this.selectedAnswers,
    this.evaluatedByAI,
    this.scannedPaperUrls,
    this.openDateTime,
    this.deadlineDateTime,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['_id'] ?? '',
      title: json['title'] ?? 'Untitled Quiz',
      description: json['description'] ?? '',
      type: json['type'] ?? 'mcq',
      totalMarks: json['totalMarks'] ?? 0,
      isAIScanned: json['isAIScanned'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      course: json['course'] is Map ? json['course']['_id'] : json['course'],
      isCompleted: json['isCompleted'] ?? false,
      score: json['score'],
      selectedAnswers: json['answers'] ?? json['selectedAnswers'],
      evaluatedByAI: json['evaluatedByAI'] ?? false,

      // 🔥 EXTRACITING TIME CRITERIA FROM BACKEND SECURELY
      openDateTime: json['openDateTime'] != null ? DateTime.tryParse(json['openDateTime']) : null,
      deadlineDateTime: json['deadlineDateTime'] != null ? DateTime.tryParse(json['deadlineDateTime']) : null,

      scannedPaperUrls: json['scannedPaper'] != null
          ? List<String>.from(json['scannedPaper'].map((file) => "https://smart-teacher-assistant-fyp.onrender.com/uploads/$file"))
          : [],

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