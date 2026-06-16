import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:frontened/core/api.dart';
import 'package:frontened/services/storage_service.dart';
import 'package:frontened/models/Quiz/quiz_model.dart';

class QuizService {
  Future<Map<String, String>> _headers() async {
    final token = await StorageService.getToken();
    return {"Content-Type": "application/json", "Authorization": "Bearer $token", "Accept": "application/json"};
  }

  Future<Map<String, String>> _multipartHeaders() async {
    final token = await StorageService.getToken();
    return {"Authorization": "Bearer $token", "Accept": "application/json"};
  }

  Future<List<Quiz>> getAllQuizzes() async {
    final response = await http.get(Uri.parse("${Api.baseUrl}/quizzes"), headers: await _headers());
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return (data['quizzes'] as List).map((q) => Quiz.fromJson(q)).toList();
    throw Exception(data['message'] ?? "Failed to fetch quizzes");
  }

  Future<List<Quiz>> getQuizzesByCourse(String courseId) async {
    final response = await http.get(Uri.parse("${Api.baseUrl}/quizzes/course/$courseId"), headers: await _headers());
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return (data['quizzes'] as List).map((q) => Quiz.fromJson(q)).toList();
    throw Exception(data['message'] ?? "Failed to fetch course quizzes");
  }

  Future<Map<String, dynamic>> getTeacherQuizResults({required String quizId}) async {
    final response = await http.get(Uri.parse("${Api.baseUrl}/quizzes/results/$quizId"), headers: await _headers());
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? "Failed to fetch results");
  }

  Future<bool> createQuiz({
    required String courseId, required String title, required String type,
    List? questions, List? shortQuestions, List? longQuestions
  }) async {
    int total = 0;
    if (questions != null) for(var q in questions) total += (int.tryParse(q['marks'].toString()) ?? 1);
    if (shortQuestions != null) for(var q in shortQuestions) total += (int.tryParse(q['marks'].toString()) ?? 5);
    if (longQuestions != null) for(var q in longQuestions) total += (int.tryParse(q['marks'].toString()) ?? 5);

    final response = await http.post(
        Uri.parse("${Api.baseUrl}/quizzes"),
        headers: await _headers(),
        body: jsonEncode({
          "course": courseId, "title": title, "type": type,
          "questions": questions ?? [], "shortQuestions": shortQuestions ?? [], "longQuestions": longQuestions ?? [],
          "totalMarks": total
        })
    );
    return response.statusCode == 201 || response.statusCode == 200;
  }

  Future<Map<String, dynamic>> attemptQuiz({required String quizId, required List answers}) async {
    final response = await http.post(Uri.parse("${Api.baseUrl}/quizzes/attempt/$quizId"), headers: await _headers(), body: jsonEncode({"answers": answers}));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? "Failed to submit attempt");
  }

  Future<Map<String, dynamic>> scanAIQuizMarks({required String courseId, required String studentId, required String title, required List<File> files}) async {
    final request = http.MultipartRequest("POST", Uri.parse("${Api.baseUrl}/ai/scan"));
    request.headers.addAll(await _multipartHeaders());
    request.fields['courseId'] = courseId;
    request.fields['studentId'] = studentId;
    request.fields['title'] = title;
    for (var file in files) { request.files.add(await http.MultipartFile.fromPath('files', file.path)); }
    final response = await http.Response.fromStream(await request.send());
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['message'] ?? "Scan failed");
  }

  Future<bool> updateQuiz({required String quizId, String? title, List? questions}) async {
    final response = await http.put(Uri.parse("${Api.baseUrl}/quizzes/$quizId"), headers: await _headers(), body: jsonEncode({"title": title ?? "Updated Quiz", "questions": questions ?? []}));
    return response.statusCode == 200;
  }

  Future<bool> deleteQuiz(String quizId) async {
    final response = await http.delete(Uri.parse("${Api.baseUrl}/quizzes/$quizId"), headers: await _headers());
    return response.statusCode == 200;
  }

  Future<String?> generateAIQuestionQuizPdf({required String quizId}) async {
    final response = await http.get(Uri.parse("${Api.baseUrl}/quizzes/pdf/$quizId"), headers: await _headers());
    if (response.statusCode == 200) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/ai_exam_$quizId.pdf');
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    }
    return null;
  }

  Future<String?> generateQuestionQuizPDF({required String quizId, required String courseId, String? title}) async {
    final response = await http.get(Uri.parse("${Api.baseUrl}/quizzes/pdf/$quizId"), headers: await _headers());
    if (response.statusCode == 200) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/exam_$quizId.pdf');
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    }
    return null;
  }

  // ==========================================
  // AI EXAM ENGINE (FIXED FOR OPTIONAL FILE)
  // ==========================================

  // 🔥 FIX: File? file kar diya gaya hai
  Future<Map<String, dynamic>> createAIMCQQuiz({
    required String courseId, required String prompt, required String difficulty,
    required int questionCount, required int marksPerQuestion, File? file
  }) async {
    final url = Uri.parse("${Api.baseUrl}/ai/quizzes/mcq");
    if (file != null && file.path.isNotEmpty) {
      final req = http.MultipartRequest("POST", url)..headers.addAll(await _multipartHeaders());
      req.fields.addAll({
        "courseId": courseId, "course": courseId,
        "topic": prompt, "prompt": prompt,
        "difficulty": difficulty, "questionCount": questionCount.toString(), "marksPerQuestion": marksPerQuestion.toString()
      });
      req.files.add(await http.MultipartFile.fromPath("book", file.path));
      final res = await http.Response.fromStream(await req.send());
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) return data;
      throw Exception(data['message'] ?? "AI Generation Failed");
    } else {
      final res = await http.post(url, headers: await _headers(), body: jsonEncode({
        "courseId": courseId, "course": courseId,
        "topic": prompt, "prompt": prompt,
        "difficulty": difficulty, "questionCount": questionCount, "marksPerQuestion": marksPerQuestion
      }));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) return data;
      throw Exception(data['message'] ?? "AI Generation Failed");
    }
  }

  // 🔥 FIX: File? file kar diya gaya hai
  Future<Map<String, dynamic>> createAIQuestionQuiz({
    required String courseId, required String prompt, required String difficulty, required String type,
    File? file, int? shortCount, int? shortMarks, int? shortEachMark, int? longCount, int? longMarks, int? longEachMark
  }) async {
    final url = Uri.parse("${Api.baseUrl}/ai/quizzes/descriptive");
    if (file != null && file.path.isNotEmpty) {
      final req = http.MultipartRequest("POST", url)..headers.addAll(await _multipartHeaders());
      req.fields.addAll({
        "courseId": courseId, "course": courseId,
        "topic": prompt, "prompt": prompt,
        "difficulty": difficulty, "type": type,
        "shortCount": (shortCount ?? 0).toString(), "shortEachMark": (shortEachMark ?? 2).toString(),
        "longCount": (longCount ?? 0).toString(), "longEachMark": (longEachMark ?? 5).toString()
      });
      req.files.add(await http.MultipartFile.fromPath("book", file.path));
      final res = await http.Response.fromStream(await req.send());
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) return data;
      throw Exception(data['message'] ?? "AI Written Exam Generation Failed");
    } else {
      final res = await http.post(url, headers: await _headers(), body: jsonEncode({
        "courseId": courseId, "course": courseId,
        "topic": prompt, "prompt": prompt,
        "difficulty": difficulty, "type": type,
        "shortCount": shortCount ?? 0, "shortEachMark": shortEachMark ?? 2,
        "longCount": longCount ?? 0, "longEachMark": longEachMark ?? 5
      }));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) return data;
      throw Exception(data['message'] ?? "AI Written Exam Generation Failed");
    }
  }
}