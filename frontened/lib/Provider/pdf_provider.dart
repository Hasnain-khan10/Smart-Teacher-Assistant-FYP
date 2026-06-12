import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';

import '../services/pdf_service.dart';

class PdfProvider extends ChangeNotifier {
  File? _file;
  bool _isLoading = false;

  File? get file => _file;
  bool get isLoading => _isLoading;

  // =========================
  // OPEN PDF ONLY
  // =========================
  Future<void> openPDF(String courseId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _file = await PdfService.downloadPDF(courseId);

      if (_file != null) {
        await OpenFile.open(_file!.path);
      }
    } catch (e) {
      _file = null;
      print("OPEN ERROR: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}