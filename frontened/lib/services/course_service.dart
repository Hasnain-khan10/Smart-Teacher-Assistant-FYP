import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontened/core/api.dart';
import 'package:frontened/models/course_model.dart';
import 'package:frontened/services/storage_service.dart';

class CourseService {
  static Future<Map<String, String>> _headers() async {
    final token = await StorageService.getToken();
    return {"Content-Type": "application/json", "Authorization": "Bearer $token"};
  }

  static Future<Map<String, dynamic>> createCourse(CourseModel course) async {
    final response = await http.post(
      Uri.parse("${Api.baseUrl}/courses"),
      headers: await _headers(),
      body: jsonEncode(course.toJson()),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return {"course": CourseModel.fromJson(data["course"]), "joinLink": data["course"]["joinLink"]};
    }
    throw Exception(data["message"] ?? "Failed to create course");
  }

  static Future<List<CourseModel>> getCourses() async {
    final response = await http.get(Uri.parse("${Api.baseUrl}/courses"), headers: await _headers());
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return List<CourseModel>.from((data as List).map((c) => CourseModel.fromJson(c)));
    }
    throw Exception("Failed to fetch courses");
  }

  static Future<CourseModel> getCourseById(String id) async {
    final response = await http.get(Uri.parse("${Api.baseUrl}/courses/$id"), headers: await _headers());
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return CourseModel.fromJson(data);
    throw Exception(data["message"] ?? "Course not found");
  }

  static Future<CourseModel> joinCourse(String joinCode) async {
    final response = await http.post(
      Uri.parse("${Api.baseUrl}/courses/join"),
      headers: await _headers(),
      body: jsonEncode({"code": joinCode}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return CourseModel.fromJson(data["course"]);
    throw Exception(data["message"] ?? "Join failed");
  }

  static Future<List<dynamic>> getCourseStudents(String courseId) async {
    final response = await http.get(Uri.parse("${Api.baseUrl}/courses/$courseId/students"), headers: await _headers());
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data["students"];
    throw Exception(data["message"] ?? "Failed to fetch students");
  }

  static Future<CourseModel> previewCourse(String code) async {
    final response = await http.get(Uri.parse("${Api.baseUrl}/courses/preview/$code"), headers: await _headers());
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return CourseModel.fromJson(data);
    throw Exception(data["message"] ?? "Invalid link");
  }

  static Future<CourseModel> updateCourse(String id, CourseModel course) async {
    final response = await http.put(Uri.parse("${Api.baseUrl}/courses/$id"), headers: await _headers(), body: jsonEncode(course.toJson()));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return CourseModel.fromJson(data);
    throw Exception(data["message"] ?? "Update failed");
  }

  static Future<void> deleteCourse(String id) async {
    final response = await http.delete(Uri.parse("${Api.baseUrl}/courses/$id"), headers: await _headers());
    if (response.statusCode != 200) throw Exception(jsonDecode(response.body)["message"] ?? "Delete failed");
  }
}