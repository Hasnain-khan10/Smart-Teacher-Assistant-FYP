import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:frontened/core/api.dart';
import 'package:frontened/services/storage_service.dart';
import 'package:http/http.dart' as http;

import '../models/week_plan_model.dart';

class WeekPlanService {
  // ==========================
  // HEADERS
  // ==========================
  static Future<Map<String, String>> _headers() async {
    final token = await StorageService.getToken();

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    };
  }

  static Future<Map<String, String>> _authOnlyHeaders() async {
    final token = await StorageService.getToken();

    return {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    };
  }

  // ==========================
  // 1. CREATE MANUAL PLAN
  // ==========================
  static Future<WeekPlanModel> createPlan(
      String courseId,
      List<WeekModel> weeks, {
        int semesterDuration = 18,
      }) async {
    final response = await http.post(
      Uri.parse("${Api.baseUrl}/plans"),
      headers: await _headers(),
      body: jsonEncode({
        "courseId": courseId,
        "semesterDuration": semesterDuration,
        "weeks": weeks.map((e) => e.toJson()).toList(),
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 && data["plan"] != null) {
      return WeekPlanModel.fromJson(data["plan"]);
    }

    throw Exception(data["message"] ?? "Failed to create plan");
  }

  // ==========================
  // 2. GET PLAN BY COURSE
  // ==========================
  static Future<WeekPlanModel> getPlanByCourse(String courseId) async {
    final response = await http.get(
      Uri.parse("${Api.baseUrl}/plans/$courseId"),
      headers: await _headers(),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["plan"] != null) {
      return WeekPlanModel.fromJson(data["plan"]);
    }

    throw Exception(data["message"] ?? "Plan not found");
  }

  // ==========================
  // 3. UPDATE PLAN
  // ==========================
  static Future<WeekPlanModel> updatePlan(
      String planId,
      List<WeekModel> weeks,
      ) async {
    final response = await http.put(
      Uri.parse("${Api.baseUrl}/plans/$planId"),
      headers: await _headers(),
      body: jsonEncode({
        "weeks": weeks.map((e) => e.toJson()).toList(),
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["plan"] != null) {
      return WeekPlanModel.fromJson(data["plan"]);
    }

    throw Exception(data["message"] ?? "Update failed");
  }

  // ==========================
  // 4. DELETE PLAN
  // ==========================
  static Future<void> deletePlan(String planId) async {
    final response = await http.delete(
      Uri.parse("${Api.baseUrl}/plans/$planId"),
      headers: await _headers(),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data["message"] ?? "Delete failed");
    }
  }

  // ==========================
  // 5. WEEK PDF
  // ==========================
  static Future<Uint8List> downloadWeekPDF(
      String courseId,
      int weekNumber,
      ) async {
    final response = await http.get(
      Uri.parse("${Api.baseUrl}/plans/pdf/week/$courseId/$weekNumber"),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    }

    final data = jsonDecode(response.body);
    throw Exception(data["message"] ?? "Week PDF download failed");
  }

  // ==========================
  // 6. GENERATE AI BY PROMPT
  // ==========================
  static Future<WeekPlanModel> generateAIPlan(
      String courseId, {
        String? prompt,
      }) async {
    final response = await http.post(
      Uri.parse("${Api.baseUrl}/plans/ai"),
      headers: await _headers(),
      body: jsonEncode({
        "courseId": courseId,
        "prompt": prompt ?? "",
      }),
    );

    final data = jsonDecode(response.body);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        data["plan"] != null) {
      return WeekPlanModel.fromJson(data["plan"]);
    }

    throw Exception(data["message"] ?? "AI plan generation failed");
  }

  // ==========================
  // 7. GENERATE AI BY BOOK
  // ==========================
  static Future<WeekPlanModel> generateAIPlanFromBook(
      String courseId,
      File bookFile,
      ) async {
    final request = http.MultipartRequest(
      "POST",
      Uri.parse("${Api.baseUrl}/plans/ai/book"),
    );

    request.headers.addAll(await _authOnlyHeaders());

    request.fields["courseId"] = courseId;

    request.files.add(
      await http.MultipartFile.fromPath(
        "book",
        bookFile.path,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final data = jsonDecode(response.body);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        data["plan"] != null) {
      return WeekPlanModel.fromJson(data["plan"]);
    }

    throw Exception(data["message"] ?? "Book AI generation failed");
  }

  // ==========================
  // 8. FULL AI PDF
  // ==========================
  static Future<Uint8List> downloadAIPlanPDF(String courseId) async {
    final response = await http.get(
      Uri.parse("${Api.baseUrl}/plans/ai/pdf/$courseId"),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    }

    final data = jsonDecode(response.body);
    throw Exception(data["message"] ?? "AI full PDF download failed");
  }


  // ==========================
// 9. UPDATE SINGLE WEEK (AI)
// ==========================
  static Future<WeekModel> updateWeekAI(
      String courseId,
      int weekNumber, {
        String? prompt,
      }) async {
    final response = await http.put(
      Uri.parse("${Api.baseUrl}/plans/week/update-ai"),
      headers: await _headers(),
      body: jsonEncode({
        "courseId": courseId,
        "weekNumber": weekNumber,
        "prompt": prompt ?? "",
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["week"] != null) {
      return WeekModel.fromJson(data["week"]);
    }

    throw Exception(data["message"] ?? "Week AI update failed");
  }


// ==========================
// 10. DELETE SINGLE WEEK
// ==========================
  static Future<void> deleteWeek(
      String courseId,
      int weekNumber,
      ) async {
    final response = await http.delete(
      Uri.parse("${Api.baseUrl}/plans/week/delete/$courseId/$weekNumber"),
      headers: await _headers(),
    );

    print("DELETE STATUS: ${response.statusCode}");
    print("DELETE RESPONSE: ${response.body}");

    final data = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : {};

    if (response.statusCode != 200) {
      throw Exception(
        data["message"] ?? data["error"] ?? "Week delete failed",
      );
    }
  }
}