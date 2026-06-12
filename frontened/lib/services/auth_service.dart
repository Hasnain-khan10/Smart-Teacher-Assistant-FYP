import 'dart:convert';
import 'dart:io';

import 'package:frontened/core/api.dart';
import 'package:frontened/models/auth_models.dart';
import 'package:frontened/services/storage_service.dart';
import 'package:http/http.dart' as http;

import '../models/user_model.dart';

class ApiService {

  // ================= LOGIN =================
  static Future<AuthModel> login(
      String email,
      String password,
      String role,
      ) async {
    final response = await http.post(
      Uri.parse("${Api.baseUrl}/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
        "role": role,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final auth = AuthModel.fromJson(data);

      await StorageService.saveToken(
        auth.token,
        auth.user.role ?? "",
      );

      return auth;
    } else {
      throw Exception(data["message"] ?? "Login failed");
    }
  }


  // ================= SIGNUP =================
  static Future<AuthModel> signup({
    required String name,
    required String email,
    required String password,
    required String role,

    // 🔹 Common
    String? fatherName,
    String? cnic,
    String? department,

    // 👨‍🎓 Student
    String? rollNumber,
    String? semester,
    String? section,

    // 👨‍🏫 Teacher
    String? qualification,
    String? experience,
    String? speciality,
  }) async {
    final Map<String, dynamic> body = {
      "name": name,
      "email": email,
      "password": password,
      "role": role,
      "fatherName": fatherName,
      "cnic": cnic,
      "department": department,
    };

    // ✅ Add Student Fields
    if (role == "student") {
      body["rollNumber"] = rollNumber;
      body["semester"] = semester;
      body["section"] = section;
    }

    // ✅ Add Teacher Fields
    if (role == "teacher") {
      body["qualification"] = qualification;
      body["experience"] = experience;
      body["speciality"] = speciality;
    }

    final response = await http.post(
      Uri.parse("${Api.baseUrl}/auth/signup"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    print("STATUS CODE => ${response.statusCode}");
    print("RESPONSE BODY => ${response.body}");

    if (response.statusCode == 201) {
      final auth = AuthModel.fromJson(data);

      await StorageService.saveToken(
        auth.token,
        auth.user.role ?? "",
      );

      return auth;
    } else {
      throw Exception(data["message"] ?? "Signup failed");
    }
  }


  // ================= PROFILE =================
  static Future<UserModel> getProfile() async {
    final token = await StorageService.getToken();

    final response = await http.get(
      Uri.parse("${Api.baseUrl}/auth/profile"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return UserModel.fromJson(data["user"]);
    } else {
      throw Exception("Failed to load profile");
    }
  }

  // ================= UPDATE PROFILE =================
  static Future<UserModel> updateProfile({
    required String name,

    // Common
    String? fatherName,
    String? cnic,
    String? department,

    // Student
    String? rollNumber,
    String? semester,
    String? section,

    // Teacher
    String? qualification,
    String? experience,
    String? speciality,

    // Profile Image
    File? profileImage,
  }) async {
    final token =
    await StorageService.getToken();

    final request =
    http.MultipartRequest(
      "PUT",
      Uri.parse(
        "${Api.baseUrl}/auth/profile",
      ),
    );

    request.headers["Authorization"] =
    "Bearer $token";

    // =====================================
    // COMMON FIELDS
    // =====================================

    request.fields["name"] = name;

    if (fatherName != null) {
      request.fields["fatherName"] =
          fatherName;
    }

    if (cnic != null) {
      request.fields["cnic"] = cnic;
    }

    if (department != null) {
      request.fields["department"] =
          department;
    }

    // =====================================
    // STUDENT FIELDS
    // =====================================

    if (rollNumber != null) {
      request.fields["rollNumber"] =
          rollNumber;
    }

    if (semester != null) {
      request.fields["semester"] =
          semester;
    }

    if (section != null) {
      request.fields["section"] =
          section;
    }

    // =====================================
    // TEACHER FIELDS
    // =====================================

    if (qualification != null) {
      request.fields["qualification"] =
          qualification;
    }

    if (experience != null) {
      request.fields["experience"] =
          experience;
    }

    if (speciality != null) {
      request.fields["speciality"] =
          speciality;
    }

    // =====================================
    // PROFILE IMAGE
    // =====================================

    if (profileImage != null) {
      request.files.add(
        await http.MultipartFile
            .fromPath(
          "profileImage",
          profileImage.path,
        ),
      );
    }

    final streamedResponse =
    await request.send();

    final response =
    await http.Response.fromStream(
      streamedResponse,
    );

    final data =
    jsonDecode(response.body);

    if (response.statusCode == 200) {
      return UserModel.fromJson(
        data["user"],
      );
    } else {
      throw Exception(
        data["message"] ??
            "Failed to update profile",
      );
    }
  }

  // ================= LOGOUT =================
  static Future<void> logout() async {
    await StorageService.removeToken();
  }

  // ------------------ FORGOT PASSWORD (Send OTP) ------------------
  static Future<String> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse("${Api.baseUrl}/auth/forgot-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data["message"] ?? "OTP sent to your email";
      } else {
        throw Exception(data["message"] ?? "Something went wrong");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

// ------------------ VERIFY OTP ------------------
  static Future<String> verifyOTP(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse("${Api.baseUrl}/auth/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "otp": otp,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data["message"] ?? "OTP verified successfully";
      } else {
        throw Exception(data["message"] ?? "Invalid OTP");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

// ------------------ RESET PASSWORD ------------------
  static Future<String> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("${Api.baseUrl}/auth/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "newPassword": newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data["message"] ?? "Password reset successfully";
      } else {
        throw Exception(data["message"] ?? "Password reset failed");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ================= GOOGLE SIGN-IN =================
  static Future<AuthModel> googleSignIn(
      String idToken,
      String role,
      ) async {
    final response = await http.post(
      Uri.parse("${Api.baseUrl}/auth/google-login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "idToken": idToken,
        "role": role, // ✅ REQUIRED
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final auth = AuthModel.fromJson(data);

      await StorageService.saveToken(
        auth.token,
        auth.user.role ?? "",
      );

      return auth;
    } else {
      throw Exception(data["message"] ?? "Google login failed");
    }
  }
}