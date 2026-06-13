import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Import added for Google Sign-In

import '../models/auth_models.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {

  bool _isLoading = false;
  UserModel? _user;
  String? _error;

  // 🔥 GLOBAL SINGLETON INSTANCE: Bina parameters ke initialize karein taake native google-services.json ko use kare
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool get isLoading => _isLoading;
  UserModel? get user => _user;
  String? get error => _error;

  // =========================
  // INTERNAL
  // =========================
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? err) {
    _error = err;
    notifyListeners();
  }

  // =========================
  // AUTO LOGIN
  // =========================
  Future<void> checkAuth() async {
    try {
      _setLoading(true);

      final token = await StorageService.getToken();

      if (token != null) {
        _user = await ApiService.getProfile();
      }

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
    }
  }

  // =========================
  // LOGIN (WITH ROLE 🔥)
  // =========================
  Future<bool> login(
      String email,
      String password,
      String role,
      ) async {
    try {
      _setLoading(true);
      _setError(null);

      AuthModel auth = await ApiService.login(email, password, role);
      _user = auth.user;

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll("Exception: ", ""));
      return false;
    }
  }

  // =========================
  // SIGNUP (NOW RETURNS USER)
  // =========================
  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    required String role,
    String? fatherName,
    String? cnic,
    String? department,
    String? rollNumber,
    String? semester,
    String? section,
    String? qualification,
    String? experience,
    String? speciality,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      print("===== SIGNUP START =====");
      print("NAME: \$name");
      print("EMAIL: \$email");
      print("ROLE: \$role");
      print("DEPARTMENT: \$department");

      AuthModel auth = await ApiService.signup(
        name: name,
        email: email,
        password: password,
        role: role,
        fatherName: fatherName,
        cnic: cnic,
        department: department,
        rollNumber: rollNumber,
        semester: semester,
        section: section,
        qualification: qualification,
        experience: experience,
        speciality: speciality,
      );

      print("===== SIGNUP SUCCESS =====");

      _user = auth.user;

      _setLoading(false);
      return true;
    } catch (e) {
      print("===== SIGNUP ERROR =====");
      print(e);

      _setLoading(false);
      _setError(e.toString().replaceAll("Exception: ", ""));
      return false;
    }
  }

  // =========================
  // LOAD PROFILE
  // =========================
  Future<void> loadProfile() async {
    try {
      _setLoading(true);

      _user = await ApiService.getProfile();

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
    }
  }


  // =========================
  // UPDATE PROFILE
  // =========================
  Future<bool> updateProfile({
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
    try {
      _setLoading(true);
      _setError(null);

      final updatedUser =
      await ApiService.updateProfile(
        name: name,

        fatherName: fatherName,
        cnic: cnic,
        department: department,

        rollNumber: rollNumber,
        semester: semester,
        section: section,

        qualification: qualification,
        experience: experience,
        speciality: speciality,

        profileImage: profileImage,
      );

      _user = updatedUser;

      _setLoading(false);

      notifyListeners();

      return true;
    } catch (e) {
      _setLoading(false);

      _setError(
        e.toString().replaceAll(
          "Exception: ",
          "",
        ),
      );

      return false;
    }
  }

  // =========================
  // GOOGLE LOGIN (WITH ROLE 🔥)
  // =========================
  Future<bool> googleLogin(
      String idToken,
      String role,
      ) async {
    try {
      _setLoading(true);
      _setError(null);

      AuthModel auth = await ApiService.googleSignIn(idToken, role);
      _user = auth.user;

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll("Exception: ", ""));
      return false;
    }
  }

  // =========================
  // FORGOT PASSWORD
  // =========================
  Future<bool> forgotPassword(String email) async {
    try {
      _setLoading(true);
      _setError(null);

      await ApiService.forgotPassword(email);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(
        e.toString().replaceAll(
          "Exception: ",
          "",
        ),
      );
      return false;
    }
  }

  // =========================
  // VERIFY OTP
  // =========================
  Future<bool> verifyOTP({
    required String email,
    required String otp,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      await ApiService.verifyOTP(
        email,
        otp,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(
        e.toString().replaceAll(
          "Exception: ",
          "",
        ),
      );
      return false;
    }
  }

  // =========================
  // RESET PASSWORD
  // =========================
  Future<bool> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      await ApiService.resetPassword(
        email: email,
        newPassword: newPassword,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(
        e.toString().replaceAll(
          "Exception: ",
          "",
        ),
      );
      return false;
    }
  }

  // ==========================================================
  // LOGOUT (PRESERVES ROLE FOR IMMACULATE USER EXPERIENCE) 🔥
  // ==========================================================
  Future<void> logout() async {
    try {
      // 1. Storage se tokens aur session timestamps saaf karein (Role delete nahi hoga)
      await StorageService.removeToken();

      // 2. Global single instance ko check karke safe signout aur disconnect karein
      final bool currentlySigned = await _googleSignIn.isSignedIn();

      if (currentlySigned) {
        await _googleSignIn.signOut();
        try {
          await _googleSignIn.disconnect();
        } catch (platformError) {
          print("Platform Google disconnect skipped safely: \$platformError");
        }
      }

      // 3. API backend instance se token mapping clear karein
      await ApiService.logout();
    } catch (e) {
      print("Global Logout Exception caught: \$e");
    } finally {
      // 4. State updates trigger karke clear exit confirm karein
      _user = null;
      notifyListeners();
    }
  }
}