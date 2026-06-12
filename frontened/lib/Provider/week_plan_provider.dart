import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import '../models/week_plan_model.dart';
import '../services/week_plan_service.dart';

class WeekPlanProvider with ChangeNotifier {
  // ===============================
  // STATE
  // ===============================

  WeekPlanModel? _plan;

  bool _isLoading = false;
  bool _isCreating = false;
  bool _isUpdating = false;
  bool _isDeleting = false;

  bool _isGeneratingAI = false;
  bool _isGeneratingFromBook = false;
  bool _isDownloadingAI = false;

  final Map<int, bool> _downloadingWeeks = {};

  final bool _isWeekUpdating = false;
  final bool _isWeekDeleting = false;

  final Map<int, bool> _weekActionLoading = {};

  String? _error;

  // ===============================
  // GETTERS
  // ===============================

  WeekPlanModel? get plan => _plan;

  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isUpdating => _isUpdating;
  bool get isDeleting => _isDeleting;

  bool get isGeneratingAI => _isGeneratingAI;
  bool get isGeneratingFromBook => _isGeneratingFromBook;
  bool get isDownloadingAI => _isDownloadingAI;

  bool get isWeekUpdating => _isWeekUpdating;
  bool get isWeekDeleting => _isWeekDeleting;

  bool isWeekActionLoading(int weekNumber) {
    return _weekActionLoading[weekNumber] ?? false;
  }

  String? get error => _error;

  bool isWeekLoading(int weekNumber) {
    return _downloadingWeeks[weekNumber] ?? false;
  }

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

  void clearPlan() {
    _plan = null;
    notifyListeners();
  }


  // ===============================
  // 1. CREATE MANUAL PLAN
  // ===============================
  Future<bool> createPlan(
      String courseId,
      List<WeekModel> weeks, {
        int semesterDuration = 18,
      }) async {
    try {
      _isCreating = true;
      _error = null;
      notifyListeners();

      _plan = await WeekPlanService.createPlan(
        courseId,
        weeks,
        semesterDuration: semesterDuration,
      );

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }


  // ===============================
  // 2. FETCH PLAN
  // ===============================
  Future<void> fetchPlan(String courseId) async {
    try {
      _setLoading(true);
      _error = null;

      _plan = await WeekPlanService.getPlanByCourse(courseId);
    } catch (e) {
      _error = e.toString();
      _plan = null;
    } finally {
      _setLoading(false);
    }
  }


  // ===============================
  // 3. UPDATE PLAN
  // ===============================
  Future<bool> updatePlan(
      String planId,
      List<WeekModel> weeks,
      ) async {
    try {
      _isUpdating = true;
      _error = null;
      notifyListeners();

      _plan = await WeekPlanService.updatePlan(planId, weeks);

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
  // 4. DELETE PLAN
  // ===============================
  Future<bool> deletePlan(String planId) async {
    try {
      _isDeleting = true;
      _error = null;
      notifyListeners();

      await WeekPlanService.deletePlan(planId);

      _plan = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }


  // ===============================
  // 📄 5. WEEK PDF
  // ===============================
  Future<bool> downloadAndOpenWeekPDF(
      String courseId,
      int weekNumber,
      ) async {
    try {
      _downloadingWeeks[weekNumber] = true;
      notifyListeners();

      final bytes = await WeekPlanService.downloadWeekPDF(
        courseId,
        weekNumber,
      );

      final dir = await getTemporaryDirectory();

      final file = File(
        "${dir.path}/week_${weekNumber}_course_$courseId.pdf",
      );

      await file.writeAsBytes(bytes);

      await OpenFile.open(file.path);

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _downloadingWeeks[weekNumber] = false;
      notifyListeners();
    }
  }


  // ===============================
  // 🚀 6. AI GENERATE (PROMPT)
  // ===============================
  Future<bool> generateAIPlan(
      String courseId, {
        String? prompt,
      }) async {
    try {
      _isGeneratingAI = true;
      _error = null;
      notifyListeners();

      _plan = await WeekPlanService.generateAIPlan(
        courseId,
        prompt: prompt,
      );

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isGeneratingAI = false;
      notifyListeners();
    }
  }


  // ===============================
  // 📘 7. AI GENERATE FROM BOOK (NEW)
  // ===============================
  Future<bool> generateAIPlanFromBook(
      String courseId,
      File bookFile,
      ) async {
    try {
      _isGeneratingFromBook = true;
      _error = null;
      notifyListeners();

      _plan = await WeekPlanService.generateAIPlanFromBook(
        courseId,
        bookFile,
      );

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isGeneratingFromBook = false;
      notifyListeners();
    }
  }


  // ===============================
  // 📄 8. FULL AI PDF
  // ===============================
  Future<bool> downloadAndOpenAIPlanPDF(String courseId) async {
    try {
      _isDownloadingAI = true;
      _error = null;
      notifyListeners();

      final bytes =
      await WeekPlanService.downloadAIPlanPDF(courseId);

      final dir = await getTemporaryDirectory();

      final file = File("${dir.path}/ai_plan_$courseId.pdf");

      await file.writeAsBytes(bytes);

      await OpenFile.open(file.path);

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isDownloadingAI = false;
      notifyListeners();
    }
  }

  Future<bool> updateWeekAI(
      String courseId,
      int weekNumber, {
        String? prompt,
      }) async {
    try {
      _weekActionLoading[weekNumber] = true;
      notifyListeners();

      final updatedWeek = await WeekPlanService.updateWeekAI(
        courseId,
        weekNumber,
        prompt: prompt,
      );

      // 🔄 Update local state
      if (_plan != null) {
        final index = _plan!.weeks.indexWhere(
              (w) => w.weekNumber == weekNumber,
        );

        if (index != -1) {
          _plan!.weeks[index] = updatedWeek;
        }
      }

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _weekActionLoading[weekNumber] = false;
      notifyListeners();
    }
  }

  Future<bool> deleteWeek(String courseId, int weekNumber) async {
    try {
      _weekActionLoading[weekNumber] = true;
      notifyListeners();

      await WeekPlanService.deleteWeek(courseId, weekNumber);

      if (_plan != null) {
        _plan!.weeks.removeWhere(
              (w) => w.weekNumber == weekNumber,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();

      debugPrint("❌ Delete Week Error: $e");

      return false;
    } finally {
      _weekActionLoading[weekNumber] = false;
      notifyListeners();
    }
  }
}