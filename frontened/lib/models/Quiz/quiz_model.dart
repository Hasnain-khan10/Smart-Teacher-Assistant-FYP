// ================================
// quiz_model.dart
// ================================

import 'package:frontened/models/Quiz/Question.dart';

import 'Question.dart';

class Quiz {
  final String id;

  final String course;
  final String teacher;

  final String title;
  final String description;

  // mcq | question | mixed
  final String type;

  // ================= MCQ =================
  final List<Question> questions;

  // ================= SUBJECTIVE =================
  final List<Question> shortQuestions;
  final List<Question> longQuestions;

  // ================= EXAM META =================
  final Map<String, dynamic>? examMeta;

  final int totalMarks;
  final int marksPerQuestion;

  // ================= AI SCAN =================
  final bool isAIScanned;
  final bool evaluatedByAI;

  // ================= ATTEMPT DATA =================
  final bool isCompleted;

  final int? score;
  final int? total;

  final List<String> selectedAnswers;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  Quiz({
    required this.id,
    required this.course,
    required this.teacher,
    required this.title,
    required this.description,
    required this.type,
    required this.questions,
    required this.shortQuestions,
    required this.longQuestions,
    required this.examMeta,
    required this.totalMarks,
    required this.marksPerQuestion,
    required this.isAIScanned,
    required this.evaluatedByAI,
    required this.isCompleted,
    this.score,
    this.total,
    required this.selectedAnswers,
    this.createdAt,
    this.updatedAt,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['_id'] ?? '',

      // ================= COURSE =================
      course: json['course'] is String
          ? json['course']
          : json['course']?['_id'] ?? '',

      // ================= TEACHER =================
      teacher: json['teacher'] is String
          ? json['teacher']
          : json['teacher']?['_id'] ?? '',

      title: json['title'] ?? '',

      description: json['description'] ?? '',

      type: json['type'] ?? 'mcq',

      // ================= MCQ QUESTIONS =================
      questions: (json['questions'] as List?)
          ?.map((q) => Question.fromJson(q))
          .toList() ??
          [],

      // ================= SHORT QUESTIONS =================
      shortQuestions: (json['shortQuestions'] as List?)
          ?.map((q) => Question.fromJson(q))
          .toList() ??
          [],

      // ================= LONG QUESTIONS =================
      longQuestions: (json['longQuestions'] as List?)
          ?.map((q) => Question.fromJson(q))
          .toList() ??
          [],

      // ================= EXAM META =================
      examMeta: json['examMeta'] != null
          ? Map<String, dynamic>.from(json['examMeta'])
          : null,

      totalMarks: json['totalMarks'] ?? 0,

      marksPerQuestion: json['marksPerQuestion'] ?? 1,

      // ================= AI SCAN =================
      isAIScanned:
      json['isAIScanned'] ?? false,

      evaluatedByAI:
      json['evaluatedByAI'] ?? false,

      // ================= ATTEMPT =================
      isCompleted: json['isCompleted'] ?? false,

      score: json['score'],

      total: json['total'],

      // ================= ANSWERS =================
      selectedAnswers: json['answers'] != null
          ? List<String>.from(
        (json['answers'] as List)
            .map((a) => a['selectedAnswer'] ?? ''),
      )
          : [],

      // ================= DATES =================
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,

      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }
  Quiz copyWith({
    bool? isCompleted,
    int? score,
    int? total,
    List<String>? selectedAnswers,
  }) {
    return Quiz(
      id: id,
      course: course,
      teacher: teacher,
      title: title,
      description: description,
      type: type,
      questions: questions,
      shortQuestions: shortQuestions,
      longQuestions: longQuestions,
      examMeta: examMeta,
      totalMarks: totalMarks,
      marksPerQuestion: marksPerQuestion,
      isAIScanned: isAIScanned,
      evaluatedByAI: evaluatedByAI,
      isCompleted: isCompleted ?? this.isCompleted,
      score: score ?? this.score,
      total: total ?? this.total,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}