import 'dart:convert';

import 'package:frontened/core/api.dart';
import 'package:frontened/services/storage_service.dart';
import 'package:http/http.dart' as http;

import '../models/slide_model.dart';

class SlideService {


  // 🔑 headers
  static Future<Map<String, String>> _headers() async {
    final token = await StorageService.getToken();

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // ==================================
  // 1. GENERATE SLIDES (Teacher)
  // ==================================
  static Future<SlideModel> generateSlides(
      String courseId, String topic) async {
    final response = await http.post(
      Uri.parse("${Api.baseUrl}/slides"),
      headers: await _headers(),
      body: jsonEncode({
        "courseId": courseId,
        "topic": topic,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return SlideModel.fromJson(data["slideDoc"]);
    } else {
      throw Exception(data["message"] ?? "Failed to generate slides");
    }
  }

  // ==================================
  // 2. GET SLIDES BY COURSE (Both)
  // ==================================
  static Future<List<SlideModel>> getSlidesByCourse(
      String courseId) async {
    final response = await http.get(
      Uri.parse("${Api.baseUrl}/slides/$courseId"),
      headers: await _headers(),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<SlideModel>.from(
        data.map((s) => SlideModel.fromJson(s)),
      );
    } else {
      throw Exception("Failed to fetch slides");
    }
  }

  // ==================================
  // 3. EXPORT PPT (Teacher)
  // ==================================
  static Future<String> exportSlidesToPPT(String slideId) async {
    final response = await http.post(
      Uri.parse("${Api.baseUrl}/slides/export/$slideId"),
      headers: await _headers(),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data["pptUrl"]; // 🔥 return URL
    } else {
      throw Exception(data["message"] ?? "PPT export failed");
    }
  }

  // ==================================
  // 4. UPDATE SLIDES (Teacher)
  // ==================================
  static Future<SlideModel> updateSlides(
      String id, List<SlideItem> slides) async {
    final response = await http.put(
      Uri.parse("${Api.baseUrl}/slides/$id"),
      headers: await _headers(),
      body: jsonEncode({
        "slides": slides.map((s) => s.toJson()).toList(),
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return SlideModel.fromJson(data["slide"]);
    } else {
      throw Exception(data["message"] ?? "Update failed");
    }
  }

  // ==================================
  // 5. DELETE SLIDES (Teacher)
  // ==================================
  static Future<void> deleteSlides(String id) async {
    final response = await http.delete(
      Uri.parse("${Api.baseUrl}/slides/$id"),
      headers: await _headers(),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data["message"] ?? "Delete failed");
    }
  }
}