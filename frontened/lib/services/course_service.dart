import 'dart:convert';

import 'package:frontened/core/api.dart';
import 'package:frontened/services/storage_service.dart';
import 'package:http/http.dart' as http;

import '../models/course_model.dart';

class CourseService {

  // 🔑 Headers
  static Future<Map<String, String>> _headers() async {
    final token = await StorageService.getToken();

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // ===============================
  // CREATE COURSE
  // ===============================
  static Future<Map<String, dynamic>> createCourse(
      CourseModel course) async {

    final response = await http.post(
      Uri.parse("${Api.baseUrl}/courses"),
      headers: await _headers(),
      body: jsonEncode(course.toJson()),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return {
        "course": CourseModel.fromJson(data["course"]),
        "joinLink": data["course"]["joinLink"],
      };
    } else {
      throw Exception(data["message"] ?? "Failed to create course");
    }
  }


  // ===============================
  // GET COURSES
  // ===============================
  static Future<List<CourseModel>> getCourses() async {
    final response = await http.get(
      Uri.parse("${Api.baseUrl}/courses"),
      headers: await _headers(),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<CourseModel>.from(
        (data as List).map((c) => CourseModel.fromJson(c)),
      );
    } else {
      throw Exception("Failed to fetch courses");
    }
  }

  // ===============================
  // GET SINGLE COURSE
  // ===============================
  static Future<CourseModel> getCourseById(String id) async {
    final response = await http.get(
      Uri.parse("${Api.baseUrl}/courses/$id"),
      headers: await _headers(),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return CourseModel.fromJson(data);
    } else {
      throw Exception(data["message"] ?? "Course not found");
    }
  }

  // ===============================
  // JOIN COURSE
  // ===============================
  static Future<CourseModel> joinCourse(String joinCode) async {
    final response = await http.post(
      Uri.parse("${Api.baseUrl}/courses/join"),
      headers: await _headers(),
      body: jsonEncode({"code": joinCode}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return CourseModel.fromJson(data["course"]);
    } else {
      throw Exception(data["message"] ?? "Join failed");
    }
  }

  // ===============================
  // GET COURSE STUDENTS
  // ===============================
  static Future<List<dynamic>> getCourseStudents(String courseId) async {
    final response = await http.get(
      Uri.parse("${Api.baseUrl}/courses/$courseId/students"),
      headers: await _headers(),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data["students"];
    } else {
      throw Exception(
        data["message"] ?? "Failed to fetch students",
      );
    }
  }

  // ===============================
  // PREVIEW COURSE
  // ===============================
  static Future<CourseModel> previewCourse(String code) async {
    final response = await http.get(
      Uri.parse("${Api.baseUrl}/courses/preview/$code"),
      headers: await _headers(),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return CourseModel.fromJson(data);
    } else {
      throw Exception(data["message"] ?? "Invalid link");
    }
  }


  // ===============================
  // UPDATE COURSE
  // ===============================
  static Future<CourseModel> updateCourse(
      String id, CourseModel course) async {

    final response = await http.put(
      Uri.parse("${Api.baseUrl}/courses/$id"),
      headers: await _headers(),
      body: jsonEncode(course.toJson()),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return CourseModel.fromJson(data);
    } else {
      throw Exception(data["message"] ?? "Update failed");
    }
  }

  // ===============================
  // DELETE COURSE
  // ===============================
  static Future<void> deleteCourse(String id) async {
    final response = await http.delete(
      Uri.parse("${Api.baseUrl}/courses/$id"),
      headers: await _headers(),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data["message"] ?? "Delete failed");
    }
  }
}