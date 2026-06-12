import 'dart:io';

import 'package:frontened/core/api.dart';
import 'package:frontened/services/storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PdfService {
  static Future<Map<String, String>> _headers() async {
    final token = await StorageService.getToken();

    return {
      "Authorization": "Bearer $token",
    };
  }

  // =========================
  // DOWNLOAD + SAVE (APP STORAGE)
  // =========================
  static Future<File?> downloadPDF(String courseId) async {
    try {
      final response = await http.get(
        Uri.parse("${Api.baseUrl}/pdf/course/$courseId"),
        headers: await _headers(),
      );

      print("STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();

        final file = File("${dir.path}/course_outline_$courseId.pdf");

        await file.writeAsBytes(response.bodyBytes);

        return file;
      }

      return null;
    } catch (e) {
      print("PDF ERROR: $e");
      return null;
    }
  }
}