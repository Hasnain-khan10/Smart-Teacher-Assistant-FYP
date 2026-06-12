import 'dart:convert';
import 'dart:io';

import 'package:frontened/core/api.dart';
import 'package:frontened/models/Quiz/quiz_model.dart';
import 'package:frontened/services/storage_service.dart';
import 'package:http/http.dart' as http;

class QuizService {
  // =========================================
  // 🔑 HEADERS
  // =========================================
  static Future<Map<String, String>> _headers() async {
    final token = await StorageService.getToken();

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // =========================================
  // ✅ GET ALL QUIZZES
  // =========================================
  Future<List<Quiz>> getAllQuizzes() async {
    try {
      final response = await http.get(
        Uri.parse("${Api.baseUrl}/quizzes"),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        return data.map((e) => Quiz.fromJson(e)).toList();
      } else {
        throw Exception("Failed to load quizzes");
      }
    } catch (e) {
      throw Exception("Get quizzes error: $e");
    }
  }

  // =========================================
  // 👨‍🏫 TEACHER QUIZ RESULTS (PER QUIZ)
  // =========================================
  Future<Map<String, dynamic>> getTeacherQuizResults({
    required String quizId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse("${Api.baseUrl}/quizzes/results/$quizId"),
        headers: await _headers(),
      );

      print("QUIZ RESULTS STATUS => ${response.statusCode}");
      print("QUIZ RESULTS BODY => ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error["message"] ?? "Failed to load quiz results");
      }
    } catch (e) {
      throw Exception("Quiz results error: $e");
    }
  }

  // =========================================
  // ✅ GET QUIZZES BY COURSE
  // =========================================
  Future<List<Quiz>> getQuizzesByCourse(String courseId) async {
    try {
      final response = await http.get(
        Uri.parse("${Api.baseUrl}/quizzes/course/$courseId"),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        return data.map((e) => Quiz.fromJson(e)).toList();
      } else {
        throw Exception("Failed to load course quizzes");
      }
    } catch (e) {
      throw Exception("Get course quizzes error: $e");
    }
  }

  // =========================================
  // ✅ CREATE NORMAL MCQ QUIZ
  // =========================================
  Future<bool> createQuiz({
    required String courseId,
    required String title,
    required String type,

    // MCQ
    List<Map<String, dynamic>>? questions,

    // QUESTION QUIZ
    List<Map<String, dynamic>>? shortQuestions,
    List<Map<String, dynamic>>? longQuestions,
  }) async {
    try {
      final Map<String, dynamic> body = {
        "courseId": courseId,
        "title": title,
        "type": type,
      };

      // ================================
      // MCQ QUIZ
      // ================================
      if (type == "mcq") {
        body["questions"] = questions ?? [];
      }

      // ================================
      // QUESTION QUIZ
      // ================================
      else if (type == "question") {
        body["shortQuestions"] = shortQuestions ?? [];
        body["longQuestions"] = longQuestions ?? [];
      }

      // ================================
      // MIXED
      // ================================
      else if (type == "mixed") {
        body["questions"] = questions ?? [];
        body["shortQuestions"] = shortQuestions ?? [];
        body["longQuestions"] = longQuestions ?? [];
      }
      print("CREATE QUIZ BODY => ${jsonEncode(body)}");
      final response = await http.post(
        Uri.parse("${Api.baseUrl}/quizzes"),
        headers: await _headers(),
        body: jsonEncode(body),
      );

      // DEBUG
      print("CREATE QUIZ STATUS => ${response.statusCode}");
      print("CREATE QUIZ RESPONSE => ${response.body}");

      if (response.statusCode == 201) {
        return true;
      }

      final data = jsonDecode(response.body);

      throw Exception(
        data["message"] ?? "Failed to create quiz",
      );
    } catch (e) {
      throw Exception("Create quiz failed: $e");
    }
  }

  // =========================================
  // ✅ ATTEMPT QUIZ
  // =========================================
  Future<Map<String, dynamic>> attemptQuiz({
    required String quizId,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${Api.baseUrl}/quizzes/attempt/$quizId"),
        headers: await _headers(),
        body: jsonEncode({
          "answers": answers,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);

        throw Exception(
          error["message"] ?? "Quiz attempt failed",
        );
      }
    } catch (e) {
      throw Exception("Attempt quiz error: $e");
    }
  }

  // =========================================
  // 🤖 REAL AI ANSWER SHEET SCAN
  // MULTI PAGE SUPPORT
  // =========================================
  Future<Map<String, dynamic>> scanAIQuizMarks({
    required String courseId,
    required String studentId,
    required String title,
    required List<File> files,
  }) async {
    try {
      print("====================================");
      print("🤖 REAL AI SCAN API STARTED");

      print("COURSE ID => $courseId");
      print("STUDENT ID => $studentId");
      print("TITLE => $title");

      print("TOTAL FILES => ${files.length}");

      for (var file in files) {
        print("FILE => ${file.path}");
      }

      print("====================================");

      final headers = await _headers();
      final uri = Uri.parse("${Api.baseUrl}/quizzes/scan-ai-marks");
      final request = http.MultipartRequest("POST", uri);

      request.headers.addAll(headers);

      request.fields["courseId"] = courseId;
      request.fields["studentId"] = studentId;
      request.fields["title"] = title;

      for (File file in files) {
        request.files.add(
          await http.MultipartFile.fromPath(
            "files",
            file.path,
          ),
        );
      }

      print("📡 SENDING TO AI SERVER...");

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("SCAN STATUS => ${response.statusCode}");
      print("SCAN RESPONSE => ${response.body}");

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        print("❌ JSON PARSE ERROR => $e");
        throw Exception("Invalid server response");
      }

      if (response.statusCode == 200) {
        print("====================================");
        print("✅ AI SCAN SUCCESS");
        print("====================================");

        return {
          "success": true,
          "message": data["message"],
          "quiz": data["quiz"],
          "questions": data["questions"],
          "evaluation": data["evaluation"],
          "attempt": data["attempt"],
          "extractedText": data["extractedText"],
        };
      }

      throw Exception(data["message"] ?? "AI scan failed");
    } catch (e) {
      print("❌ SCAN AI SERVICE ERROR => $e");
      throw Exception("Scan AI error: $e");
    }
  }

  // =========================================
  // ✅ UPDATE QUIZ
  // =========================================
  Future<bool> updateQuiz({
    required String quizId,
    String? title,
    List<Map<String, dynamic>>? questions,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("${Api.baseUrl}/quizzes/$quizId"),
        headers: await _headers(),
        body: jsonEncode({
          "title": title,
          "questions": questions,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Update quiz failed: $e");
    }
  }

  // =========================================
  // ✅ DELETE QUIZ
  // =========================================
  Future<bool> deleteQuiz(String quizId) async {
    try {
      final response = await http.delete(
        Uri.parse("${Api.baseUrl}/quizzes/$quizId"),
        headers: await _headers(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception("Delete quiz failed: $e");
    }
  }

  // =========================================
  // 🤖 CREATE AI MCQ QUIZ
  // POST /quizzes/ai/mcq
  // =========================================
  Future<Map<String, dynamic>> createAIMCQQuiz({
    required String courseId,
    required String prompt,
    required String difficulty,
    required int questionCount,
    required int marksPerQuestion,
    required File file,
  }) async {
    try {
      final headers = await _headers();
      headers.remove("Content-Type");

      final request = http.MultipartRequest(
        "POST",
        Uri.parse("${Api.baseUrl}/quizzes/ai/mcq"),
      );

      request.headers.addAll(headers);

      request.fields["courseId"] = courseId;
      request.fields["prompt"] = prompt;
      request.fields["difficulty"] = difficulty;
      request.fields["questionCount"] = questionCount.toString();
      request.fields["marksPerQuestion"] = marksPerQuestion.toString();

      request.files.add(
        await http.MultipartFile.fromPath(
          "file",
          file.path,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data["message"] ?? "AI MCQ generation failed");
      }
    } catch (e) {
      throw Exception("AI MCQ quiz error: $e");
    }
  }

  // =========================================
  // 🤖 CREATE AI QUESTION QUIZ
  // POST /quizzes/ai/question
  // =========================================
  Future<Map<String, dynamic>> createAIQuestionQuiz({
    required String courseId,
    required String prompt,
    required String difficulty,
    required String type,
    required File file,
    int? shortCount,
    int? shortMarks,
    int? shortEachMark,
    int? longCount,
    int? longMarks,
    int? longEachMark,
  }) async {
    try {
      final uri = Uri.parse("${Api.baseUrl}/quizzes/ai/question");
      final request = http.MultipartRequest("POST", uri);

      final headers = await _headers();
      request.headers.addAll(headers);

      request.fields["courseId"] = courseId;
      request.fields["prompt"] = prompt;
      request.fields["difficulty"] = difficulty;
      request.fields["type"] = type;

      if (shortCount != null) request.fields["shortCount"] = shortCount.toString();
      if (shortMarks != null) request.fields["shortMarks"] = shortMarks.toString();
      if (shortEachMark != null) request.fields["shortEachMark"] = shortEachMark.toString();
      if (longCount != null) request.fields["longCount"] = longCount.toString();
      if (longMarks != null) request.fields["longMarks"] = longMarks.toString();
      if (longEachMark != null) request.fields["longEachMark"] = longEachMark.toString();

      request.files.add(
        await http.MultipartFile.fromPath(
          "file",
          file.path,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data["message"] ?? "AI Question quiz failed");
      }
    } catch (e) {
      throw Exception("AI question quiz error: $e");
    }
  }

  // =========================================
  // 📄 GENERATE AI QUESTION QUIZ PDF
  // =========================================
  Future<String> generateAIQuestionQuizPdf({
    required String quizId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse("${Api.baseUrl}/quizzes/ai/question/pdf/$quizId"),
        headers: await _headers(),
      );

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return decoded["pdfUrl"];
      } else {
        throw Exception(decoded["message"] ?? "PDF generation failed");
      }
    } catch (e) {
      throw Exception("Generate AI Question PDF error: $e");
    }
  }

  // =========================================
  // 📄 GENERATE QUESTION/MIXED QUIZ PDF
  // =========================================
  Future<String> generateQuestionQuizPDF({
    required String quizId,
    required String courseId,
    String? title,
  }) async {
    try {
      final Map<String, String> queryParams = {
        "courseId": courseId,
      };

      if (title != null) {
        queryParams["title"] = title;
      }

      final uri = Uri.parse("${Api.baseUrl}/quizzes/pdf/$quizId")
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: await _headers(),
      );

      print("PDF STATUS => ${response.statusCode}");
      print("PDF RESPONSE => ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["pdfUrl"] ?? "";
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error["message"] ?? "Failed to generate quiz PDF");
      }
    } catch (e) {
      throw Exception("Generate question quiz PDF error: $e");
    }
  }
}