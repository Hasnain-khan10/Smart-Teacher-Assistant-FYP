import 'package:flutter/material.dart';

import '../models/course_model.dart';
import '../services/course_service.dart';

class CourseProvider with ChangeNotifier {
  // ===============================
  // STATE
  // ===============================

  List<CourseModel> _courses = [];
  CourseModel? _selectedCourse;

  List<dynamic> _courseStudents = [];
  bool _isStudentsLoading = false;

  bool _isLoading = false;
  bool _isCreating = false;
  bool _isJoining = false;
  bool _isPreviewLoading = false;
  bool _isUpdating = false;
  bool _isDeleting = false;

  String? _error;
  String? _joinLink;

  // ===============================
  // GETTERS
  // ===============================

  List<CourseModel> get courses => _courses;
  CourseModel? get selectedCourse => _selectedCourse;

  List<dynamic> get courseStudents => _courseStudents;
  bool get isStudentsLoading => _isStudentsLoading;

  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isJoining => _isJoining;
  bool get isPreviewLoading => _isPreviewLoading;
  bool get isUpdating => _isUpdating;
  bool get isDeleting => _isDeleting;

  String? get error => _error;
  String? get joinLink => _joinLink;

  // ===============================
  // UTIL
  // ===============================
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ===============================
  // 1. FETCH COURSES
  // ===============================
  Future<void> fetchCourses() async {
    try {
      _setLoading(true);
      _error = null;

      _courses = await CourseService.getCourses();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ===============================
  // 2. FETCH SINGLE COURSE
  // ===============================
  Future<void> fetchCourseById(String id) async {
    try {
      _setLoading(true);
      _error = null;

      _selectedCourse = await CourseService.getCourseById(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ===============================
  // 3. CREATE COURSE
  // ===============================
  Future<CourseModel?> createCourse(CourseModel course) async {
    try {
      _isCreating = true;
      _error = null;
      _joinLink = null;
      notifyListeners();

      final result = await CourseService.createCourse(course);

      final newCourse = result["course"] as CourseModel;
      _joinLink = result["joinLink"];

      _courses.add(newCourse);
      _selectedCourse = newCourse;

      return newCourse;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  // ===============================
  // 4. JOIN COURSE
  // ===============================
  Future<bool> joinCourse(String joinCode) async {
    try {
      _isJoining = true;
      _error = null;
      notifyListeners();

      await CourseService.joinCourse(joinCode);

      await fetchCourses();

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isJoining = false;
      notifyListeners();
    }
  }


// ===============================
// GET COURSE STUDENTS
// ===============================
  Future<void> fetchCourseStudents(String courseId) async {
    try {
      _isStudentsLoading = true;
      notifyListeners();

      final result =
      await CourseService.getCourseStudents(courseId);

      print("STUDENTS API RESULT => $result");

      _courseStudents = result;

    } catch (e) {
      print("ERROR => $e");
      _courseStudents = [];
    } finally {
      _isStudentsLoading = false;
      notifyListeners();
    }
  }


  // ===============================
  // 5. PREVIEW COURSE
  // ===============================
  Future<void> previewCourse(String code) async {
    try {
      _isPreviewLoading = true;
      _error = null;
      notifyListeners();

      _selectedCourse = await CourseService.previewCourse(code);
    } catch (e) {
      _error = e.toString();
      _selectedCourse = null;
    } finally {
      _isPreviewLoading = false;
      notifyListeners();
    }
  }

  // ===============================
  // 7. UPDATE COURSE
  // ===============================
  Future<bool> updateCourse(String id, CourseModel course) async {
    try {
      _isUpdating = true;
      _error = null;
      notifyListeners();

      final updatedCourse =
      await CourseService.updateCourse(id, course);

      final index = _courses.indexWhere((c) => c.id == id);
      if (index != -1) {
        _courses[index] = updatedCourse;
      }

      if (_selectedCourse?.id == id) {
        _selectedCourse = updatedCourse;
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  // ===============================
  // 8. DELETE COURSE
  // ===============================
  Future<bool> deleteCourse(String id) async {
    try {
      _isDeleting = true;
      _error = null;
      notifyListeners();

      await CourseService.deleteCourse(id);

      _courses.removeWhere((c) => c.id == id);

      if (_selectedCourse?.id == id) {
        _selectedCourse = null;
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }
}