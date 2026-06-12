// ================================
// attempt_model.dart
// ================================

import 'package:frontened/models/Quiz/Attempt_Review.dart';

import 'Attempt_Review.dart';

class Attempt {

  final String id;

  final String quiz;

  final String student;

  // =========================
  // SCORE
  // =========================
  final int score;

  // =========================
  // TOTAL MARKS
  // =========================
  final int total;

  // =========================
  // AI EVALUATION
  // =========================
  final bool evaluatedByAI;

  // scanned paper image/pdf
  final String scannedPaper;

  // =========================
  // REVIEW
  // =========================
  final List<AttemptReview> review;

  final DateTime? createdAt;

  final DateTime? updatedAt;

  Attempt({
    required this.id,
    required this.quiz,
    required this.student,
    required this.score,
    required this.total,
    required this.evaluatedByAI,
    required this.scannedPaper,
    required this.review,
    this.createdAt,
    this.updatedAt,
  });

  factory Attempt.fromJson(
      Map<String, dynamic> json,
      ) {

    return Attempt(

      id: json['_id'] ?? '',

      quiz: json['quiz']?.toString() ?? '',

      student: json['student']?.toString() ?? '',

      score: json['score'] ?? 0,

      total: json['total'] ?? 0,

      evaluatedByAI:
      json['evaluatedByAI'] ?? false,

      scannedPaper:
      json['scannedPaper'] ?? '',

      review: json['review'] != null
          ? List<AttemptReview>.from(
        (json['review'] as List).map(
              (x) =>
              AttemptReview.fromJson(x),
        ),
      )
          : [],

      createdAt:
      json['createdAt'] != null
          ? DateTime.tryParse(
        json['createdAt'],
      )
          : null,

      updatedAt:
      json['updatedAt'] != null
          ? DateTime.tryParse(
        json['updatedAt'],
      )
          : null,
    );
  }

// // =========================
// // TO JSON
// // =========================
// Map<String, dynamic> toJson() {

//   return {

//     "_id": id,

//     "quiz": quiz,

//     "student": student,

//     "score": score,

//     "total": total,

//     "evaluatedByAI":
//         evaluatedByAI,

//     "scannedPaper":
//         scannedPaper,

//     "review":
//         review.map((e) {
//           return e.toJson();
//         }).toList(),

//     "createdAt":
//         createdAt?.toIso8601String(),

//     "updatedAt":
//         updatedAt?.toIso8601String(),
//   };
// }
}