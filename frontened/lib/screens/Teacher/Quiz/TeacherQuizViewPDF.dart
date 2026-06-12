import 'dart:io';

import 'package:flutter/material.dart';
import 'package:frontened/Provider/quiz_provider.dart';
import 'package:frontened/main.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../../models/Quiz/quiz_model.dart';

class TeacherQuizViewPDF extends StatefulWidget {
  final List<Quiz> quiz;

  const TeacherQuizViewPDF({
    super.key,
    required this.quiz,
  });

  @override
  State<TeacherQuizViewPDF> createState() =>
      _TeacherQuizViewPDFState();
}

class _TeacherQuizViewPDFState extends State<TeacherQuizViewPDF> {

  bool _isDownloading = false;
  int? _loadingQuizIndex;


  // ================= PDF GENERATION =================
  Future<void> _generateAndOpenPdf(Quiz quiz, int index) async {
    try {
      setState(() {
        _isDownloading = true;
        _loadingQuizIndex = index;
      });

      final provider =
          Provider.of<QuizProvider>(context, listen: false);

      final pdfUrl = await provider.generateQuestionQuizPDF(
        quiz.id, quizId: quiz.id,
        courseId: quiz.course,
        title: quiz.title,
      );

      if (pdfUrl == null) {
        _showMessage("Failed to generate PDF");
        return;
      }

      final response = await http.get(Uri.parse(pdfUrl));

      if (response.statusCode != 200) {
        _showMessage("Failed to download PDF");
        return;
      }

      final dir = await getTemporaryDirectory();

      final filePath = "${dir.path}/${quiz.title}.pdf";

      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      await OpenFile.open(file.path);

      _showMessage("PDF opened successfully");
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      setState(() {
        _isDownloading = false;
        _loadingQuizIndex = null;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message),
      backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
      ),
    );
  }

  // ================= SORT (NEWEST FIRST) =================
  List<Quiz> get sortedQuizzes {
    final list = [...widget.quiz];

    list.sort((a, b) {
      final aDate = a.createdAt ?? DateTime(2000);
      final bDate = b.createdAt ?? DateTime(2000);
      return bDate.compareTo(aDate); // newest on top
    });

    return list;
  }

  // ================= UI CARD =================
  Widget _quizCard(Quiz quiz, int index) {
    final isMCQ = quiz.type == "mcq";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// ================= HEADER =================
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.quiz, color: AppColors.primary),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "${quiz.type.toUpperCase()} • ${quiz.totalMarks} Marks",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// ================= ACTIONS =================
          Row(
            children: [

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isMCQ
                      ? null
                      : _isDownloading
                          ? null
                          : () => _generateAndOpenPdf(quiz, index),
                  icon: _loadingQuizIndex == index
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text("PDF"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final quizzes = sortedQuizzes.take(20).toList();

    return Scaffold(
      body: Column(
        children: [

          /// ================= HEADER (MATCHED STYLE) =================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
                top: 50, left: 20, right: 20, bottom: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Quizzes",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  "All Created Quizzes",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// ================= LIST =================
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                return _quizCard(quizzes[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }
}


