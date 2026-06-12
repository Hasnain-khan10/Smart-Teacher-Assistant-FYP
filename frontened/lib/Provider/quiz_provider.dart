import 'dart:io';
import 'package:flutter/material.dart';
import '../models/Quiz/quiz_model.dart';
import '../services/quiz_service.dart';

class QuizProvider with ChangeNotifier {
  final QuizService _quizService = QuizService();

  List<Quiz> _quizzes = [];
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isUpdating = false;
  bool _isDeleting = false;
  bool _isAttempting = false;
  bool _isGeneratingAI = false;
  bool _isGeneratingPdf = false;
  bool _isScanningAI = false;
  Map<String, dynamic>? _scanResult;
  bool _isLoadingQuizResults = false;
  Map<String, dynamic>? _quizResults;
  String? _error;

  List<Quiz> get quizzes => _quizzes;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isUpdating => _isUpdating;
  bool get isDeleting => _isDeleting;
  bool get isAttempting => _isAttempting;
  bool get isGeneratingAI => _isGeneratingAI;
  bool get isGeneratingPdf => _isGeneratingPdf;
  bool get isScanningAI => _isScanningAI;
  Map<String, dynamic>? get scanResult => _scanResult;
  bool get isLoadingQuizResults => _isLoadingQuizResults;
  Map<String, dynamic>? get quizResults => _quizResults;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> fetchAllQuizzes() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      _quizzes = await _quizService.getAllQuizzes();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchQuizResults(dynamic positionalId, {String? quizId}) async {
    try {
      _isLoadingQuizResults = true;
      _error = null;
      notifyListeners();
      String finalQuizId = quizId ?? positionalId?.toString() ?? "";
      final result = await _quizService.getTeacherQuizResults(quizId: finalQuizId);
      _quizResults = result;
      return result;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoadingQuizResults = false;
      notifyListeners();
    }
  }

  Future<void> fetchQuizzes(String courseId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      _quizzes = await _quizService.getQuizzesByCourse(courseId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createQuiz({
    required String courseId,
    required String title,
    required String type,
    List<Map<String, dynamic>>? questions,
    List<Map<String, dynamic>>? shortQuestions,
    List<Map<String, dynamic>>? longQuestions,
  }) async {
    try {
      _isCreating = true;
      _error = null;
      notifyListeners();
      final success = await _quizService.createQuiz(
        courseId: courseId,
        title: title,
        type: type,
        questions: questions,
        shortQuestions: shortQuestions,
        longQuestions: longQuestions,
      );
      if (success) {
        await fetchQuizzes(courseId);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  // 🔥 MASTER RESOLUTION FIX: Accepts positional parameters AND named parameters for high compatibility
  Future<Map<String, dynamic>?> attemptQuiz(dynamic arg1, {String? quizId, List<dynamic>? answers}) async {
    try {
      _isAttempting = true;
      _error = null;
      notifyListeners();

      String targetQuizId = quizId ?? (arg1 is String ? arg1 : "");
      List<dynamic> rawAnswers = answers ?? (arg1 is List ? arg1 : []);
      
      List<Map<String, dynamic>> finalAnswers = rawAnswers.map((e) => Map<String, dynamic>.from(e)).toList();

      final result = await _quizService.attemptQuiz(
        quizId: targetQuizId,
        answers: finalAnswers,
      );

      return result;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isAttempting = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> scanAIQuizMarks({
    String? courseId,
    String? studentId,
    String? title,
    List<File>? files,
    dynamic arg1,
  }) async {
    try {
      _isScanningAI = true;
      _error = null;
      notifyListeners();
      
      final result = await _quizService.scanAIQuizMarks(
        courseId: courseId ?? "",
        studentId: studentId ?? "",
        title: title ?? "",
        files: files ?? [],
      );
      _scanResult = result;
      await fetchAllQuizzes();
      return result;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isScanningAI = false;
      notifyListeners();
    }
  }

  Future<bool> updateQuiz({
    required String quizId,
    required String courseId,
    String? title,
    List<Map<String, dynamic>>? questions,
  }) async {
    try {
      _isUpdating = true;
      _error = null;
      notifyListeners();
      final success = await _quizService.updateQuiz(
        quizId: quizId,
        title: title,
        questions: questions,
      );
      if (success) {
        await fetchQuizzes(courseId);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<bool> deleteQuiz({
    required String quizId,
    required String courseId,
  }) async {
    try {
      _isDeleting = true;
      _error = null;
      notifyListeners();
      final success = await _quizService.deleteQuiz(quizId);
      if (success) {
        _quizzes.removeWhere((q) => q.id == quizId);
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> createAIMCQQuiz({
    required String courseId,
    required String prompt,
    required String difficulty,
    required int questionCount,
    required int marksPerQuestion,
    required File file,
  }) async {
    try {
      _isGeneratingAI = true;
      _error = null;
      notifyListeners();
      final result = await _quizService.createAIMCQQuiz(
        courseId: courseId,
        prompt: prompt,
        difficulty: difficulty,
        questionCount: questionCount,
        marksPerQuestion: marksPerQuestion,
        file: file,
      );
      return result;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isGeneratingAI = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> createAIQuestionQuiz({
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
      _isGeneratingAI = true;
      _error = null;
      notifyListeners();
      final result = await _quizService.createAIQuestionQuiz(
        courseId: courseId,
        prompt: prompt,
        file: file,
        difficulty: difficulty,
        type: type,
        shortCount: shortCount,
        shortMarks: shortMarks,
        shortEachMark: shortEachMark,
        longCount: longCount,
        longMarks: longMarks,
        longEachMark: longEachMark,
      );
      return result;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isGeneratingAI = false;
      notifyListeners();
    }
  }

  Future<String?> generateAIQuestionQuizPdf({
    required String quizId,
  }) async {
    try {
      _isGeneratingPdf = true;
      _error = null;
      notifyListeners();
      final url = await _quizService.generateAIQuestionQuizPdf(
        quizId: quizId,
      );
      return url;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isGeneratingPdf = false;
      notifyListeners();
    }
  }

  Future<String?> generateQuestionQuizPDF(dynamic positionalId, {String? quizId, String? courseId, String? title}) async {
    try {
      _isGeneratingPdf = true;
      _error = null;
      notifyListeners();
      String finalQuizId = quizId ?? positionalId?.toString() ?? "";
      String finalCourseId = courseId ?? "";
      final url = await _quizService.generateQuestionQuizPDF(
        quizId: finalQuizId,
        courseId: finalCourseId,
        title: title,
      );
      return url;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isGeneratingPdf = false;
      notifyListeners();
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    try {
      final name = invocation.memberName.toString().replaceAll('Symbol("', '').replaceAll('")', '');
      final positionalArgs = invocation.positionalArguments;
      final namedArgs = invocation.namedArguments;

      if (name == 'attemptQuiz') {
        dynamic trackingId = positionalArgs.isNotEmpty ? positionalArgs.first : null;
        if (namedArgs.containsKey(const Symbol('quizId'))) {
          trackingId = namedArgs[const Symbol('quizId')];
        }
        dynamic extractedAnswers;
        for (var arg in positionalArgs) {
          if (arg is List) extractedAnswers = arg;
        }
        namedArgs.forEach((key, val) {
          if (val is List) extractedAnswers = val;
        });
        return attemptQuiz(trackingId, quizId: trackingId?.toString(), answers: extractedAnswers);
      }
    } catch (e) {}
    return super.noSuchMethod(invocation);
  }

  void reset() {
    _quizzes.clear();
    _isLoading = false;
    _isCreating = false;
    _isUpdating = false;
    _isDeleting = false;
    _isAttempting = false;
    _isGeneratingAI = false;
    _isGeneratingPdf = false;
    _quizResults = null;
    _isLoadingQuizResults = false;
    _error = null;
    _scanResult = null;
    _isScanningAI = false;
    notifyListeners();
  }
}
