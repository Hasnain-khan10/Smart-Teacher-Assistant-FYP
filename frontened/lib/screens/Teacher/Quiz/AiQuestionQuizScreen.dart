import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:frontened/Provider/quiz_provider.dart';
import 'package:frontened/main.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class TeacherAIQuestionQuizScreen extends StatefulWidget {
  final String quizTitle;
  final String courseId;

  const TeacherAIQuestionQuizScreen({
    super.key,
    required this.quizTitle,
    required this.courseId,
  });

  @override
  State<TeacherAIQuestionQuizScreen> createState() =>
      _TeacherAIQuestionQuizScreenState();
}

class _TeacherAIQuestionQuizScreenState
    extends State<TeacherAIQuestionQuizScreen> {

  final TextEditingController _promptController = TextEditingController();

  String _difficulty = "medium";
  String _quizType = "both";

  final TextEditingController _shortCountController = TextEditingController();
  final TextEditingController _shortEachMarksController = TextEditingController();

  final TextEditingController _longCountController = TextEditingController();
  final TextEditingController _longEachMarksController = TextEditingController();

  bool _isGenerating = false;
  File? _selectedFile;

  // ==========================================
  // FILE PICKER
  // ==========================================
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  // ==========================================
  // VALIDATION HELPER
  // ==========================================
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  bool _validateAllFields() {
    // PROMPT
    if (_promptController.text.trim().isEmpty) {
      _showError("Please enter AI prompt");
      return false;
    }

    // FILE
    if (_selectedFile == null) {
      _showError("Please upload PDF or Image");
      return false;
    }

    // SHORT VALIDATION
    if (_quizType == "short" || _quizType == "both") {
      if (_shortCountController.text.trim().isEmpty ||
          int.tryParse(_shortCountController.text) == null ||
          int.parse(_shortCountController.text) <= 0) {
        _showError("Enter valid Short Questions count");
        return false;
      }

      if (_shortEachMarksController.text.trim().isEmpty ||
          int.tryParse(_shortEachMarksController.text) == null ||
          int.parse(_shortEachMarksController.text) <= 0) {
        _showError("Enter valid Short Each Marks");
        return false;
      }
    }

    // LONG VALIDATION
    if (_quizType == "long" || _quizType == "both") {
      if (_longCountController.text.trim().isEmpty ||
          int.tryParse(_longCountController.text) == null ||
          int.parse(_longCountController.text) <= 0) {
        _showError("Enter valid Long Questions count");
        return false;
      }

      if (_longEachMarksController.text.trim().isEmpty ||
          int.tryParse(_longEachMarksController.text) == null ||
          int.parse(_longEachMarksController.text) <= 0) {
        _showError("Enter valid Long Each Marks");
        return false;
      }
    }

    return true;
  }

  // ==========================================
  // GENERATE QUIZ (ONLY VALIDATION ADDED)
  // ==========================================
  Future<void> _generateQuiz() async {

    if (!_validateAllFields()) return;

    try {
      setState(() {
        _isGenerating = true;
      });

      final provider = Provider.of<QuizProvider>(
        context,
        listen: false,
      );

      final Map<String, dynamic>? result = await provider.createAIQuestionQuiz(
        courseId: widget.courseId,
        prompt: _promptController.text.trim(),
        file: _selectedFile!,
        difficulty: _difficulty,
        type: _quizType,

        shortCount: _quizType == "short" || _quizType == "both"
            ? int.tryParse(_shortCountController.text) ?? 0
            : 0,

        shortEachMark: _quizType == "short" || _quizType == "both"
            ? int.tryParse(_shortEachMarksController.text) ?? 0
            : 0,

        shortMarks:
            (int.tryParse(_shortCountController.text) ?? 0) *
                (int.tryParse(_shortEachMarksController.text) ?? 0),

        longCount: _quizType == "long" || _quizType == "both"
            ? int.tryParse(_longCountController.text) ?? 0
            : 0,

        longEachMark: _quizType == "long" || _quizType == "both"
            ? int.tryParse(_longEachMarksController.text) ?? 0
            : 0,

        longMarks:
            (int.tryParse(_longCountController.text) ?? 0) *
                (int.tryParse(_longEachMarksController.text) ?? 0),
      );

      if (result == null) {
        _showError("Failed to generate quiz");
        return;
      }

      final pdfUrl = result["pdfUrl"];

      if (pdfUrl == null) {
        _showError("PDF not found");
        return;
      }

      final response = await http.get(Uri.parse(pdfUrl));

      if (response.statusCode != 200) {
        _showError("Failed to download PDF");
        return;
      }

      final dir = await getTemporaryDirectory();

      final file = File("${dir.path}/ai_question_quiz.pdf");

      await file.writeAsBytes(response.bodyBytes);

      await OpenFile.open(file.path);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("AI Quiz Generated Successfully"),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _shortCountController.dispose();
    _shortEachMarksController.dispose();
    _longCountController.dispose();
    _longEachMarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),

            child: SingleChildScrollView(
  child: ConstrainedBox(
    constraints: BoxConstraints(
      minHeight:
          MediaQuery.of(context).size.height -
          100,
    ),

    child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
              
                children: [
              
                  // ======================================
                  // HEADER
                  // ======================================
                  Row(
                    children: [
              
                      GestureDetector(
                        onTap: () =>
                            Navigator.pop(
                          context,
                        ),
              
                        child: const Icon(
                          Icons.arrow_back_ios,
                          size: 20,
                        ),
                      ),
              
                      const SizedBox(
                        width: 10,
                      ),
              
                      const Expanded(
                        child: Text(
                          "AI Quiz Generation",
              
                          textAlign:
                              TextAlign.center,
              
                          style: TextStyle(
                            fontSize: 20,
              
                            fontWeight:
                                FontWeight.w700,
              
                            color:
                                AppColors
                                    .textPrimary,
                          ),
                        ),
                      ),
              
                      const SizedBox(
                        width: 20,
                      ),
                    ],
                  ),
              
                  const SizedBox(
                    height: 20,
                  ),
              
                  // ======================================
                  // COURSE
                  // ======================================
                  Text(
                    widget.quizTitle,
              
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w600,
              
                      color:
                          AppColors.textPrimary,
                    ),
                  ),
              
                  const SizedBox(height: 6),
              
                  const Text(
                    "Generate AI Question Quiz PDF",
              
                    style: TextStyle(
                      fontSize: 13,
              
                      color:
                          AppColors.textSecondary,
                    ),
                  ),
              
                  const SizedBox(height: 20),
              
                  // ======================================
                  // PROMPT FIELD
                  // ======================================
                  Container(
                    padding:
                        const EdgeInsets.all(
                      14,
                    ),
              
                    decoration: BoxDecoration(
                      color: Colors.white,
              
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
              
                      border: Border.all(
                        color:
                            AppColors.border,
                      ),
                    ),
              
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
              
                      children: [
              
                        const Text(
                          "AI Prompt",
              
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
              
                        const SizedBox(
                          height: 10,
                        ),
              
                        TextField(
                          controller:
                              _promptController,
              
                          maxLines: 5,
              
                          decoration:
                              const InputDecoration(
                            hintText:
                                "Generate important short and long questions from uploaded PDF focusing on definitions, theory, concepts and problem solving.",
              
                            border:
                                InputBorder.none,
                          ),
                        ),
                      ],
                    ),
                  ),
              
                  const SizedBox(height: 16),
              
                  // ======================================
                  // FILE PICKER
                  // ======================================
                  GestureDetector(
                    onTap: _pickFile,
              
                    child: Container(
                      width: double.infinity,
              
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),
              
                      decoration: BoxDecoration(
                        color: Colors.white,
              
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
              
                        border: Border.all(
                          color:
                              AppColors.border,
                        ),
                      ),
              
                      child: Row(
                        children: [
              
                          const Icon(
                            Icons.upload_file,
                            color:
                                AppColors.primary,
                          ),
              
                          const SizedBox(
                            width: 12,
                          ),
              
                          Expanded(
                            child: Text(
                              _selectedFile ==
                                      null
                                  ? "Upload PDF or Image"
                                  : _selectedFile!
                                      .path
                                      .split("/")
                                      .last,
              
                              style: TextStyle(
                                color:
                                    _selectedFile ==
                                            null
                                        ? Colors.grey
                                        : Colors
                                            .black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              
                  const SizedBox(height: 16),
              
                  // ======================================
                  // DIFFICULTY
                  // ======================================
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
              
                    decoration: BoxDecoration(
                      color: Colors.white,
              
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
              
                      border: Border.all(
                        color:
                            AppColors.border,
                      ),
                    ),
              
                    child:
                        DropdownButtonHideUnderline(
                      child:
                          DropdownButton<String>(
                        value: _difficulty,
              
                        isExpanded: true,
              
                        items: const [
              
                          DropdownMenuItem(
                            value: "easy",
                            child: Text(
                              "Easy",
                            ),
                          ),
              
                          DropdownMenuItem(
                            value: "medium",
                            child: Text(
                              "Medium",
                            ),
                          ),
              
                          DropdownMenuItem(
                            value: "hard",
                            child: Text(
                              "Hard",
                            ),
                          ),
                        ],
              
                        onChanged: (value) {
              
                          setState(() {
                            _difficulty =
                                value!;
                          });
                        },
                      ),
                    ),
                  ),
              
                  const SizedBox(height: 16),
              
                  // ======================================
                  // QUIZ TYPE
                  // ======================================
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
              
                    decoration: BoxDecoration(
                      color: Colors.white,
              
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
              
                      border: Border.all(
                        color:
                            AppColors.border,
                      ),
                    ),
              
                    child:
                        DropdownButtonHideUnderline(
                      child:
                          DropdownButton<String>(
                        value: _quizType,
              
                        isExpanded: true,
              
                        items: const [
              
                          DropdownMenuItem(
                            value: "short",
                            child: Text(
                              "Short Questions",
                            ),
                          ),
              
                          DropdownMenuItem(
                            value: "long",
                            child: Text(
                              "Long Questions",
                            ),
                          ),
              
                          DropdownMenuItem(
                            value: "both",
                            child: Text(
                              "Short + Long",
                            ),
                          ),
                        ],
              
                        onChanged: (value) {
              
                          setState(() {
                            _quizType =
                                value!;
                          });
                        },
                      ),
                    ),
                  ),
              
                  const SizedBox(height: 16),
              
                  // ======================================
                  // SHORT QUESTIONS
                  // ======================================
                  if (_quizType == "short" ||
                      _quizType == "both")
                    Row(
                      children: [
              
                        Expanded(
                          child: _textField(
                            label:
                                "Short Count",
              
                            controller:
                                _shortCountController,
                          ),
                        ),
              
                        const SizedBox(
                          width: 12,
                        ),
              
                        Expanded(
                          child: _textField(
                            label:
                                "Marks Each",
              
                            controller:
                                _shortEachMarksController,
                          ),
                        ),
                      ],
                    ),
              
                  if (_quizType == "short" ||
                      _quizType == "both")
                    const SizedBox(height: 16),
              
                  // ======================================
                  // LONG QUESTIONS
                  // ======================================
                  if (_quizType == "long" ||
                      _quizType == "both")
                    Row(
                      children: [
              
                        Expanded(
                          child: _textField(
                            label:
                                "Long Count",
              
                            controller:
                                _longCountController,
                          ),
                        ),
              
                        const SizedBox(
                          width: 12,
                        ),
              
                        Expanded(
                          child: _textField(
                            label:
                                "Marks Each",
              
                            controller:
                                _longEachMarksController,
                          ),
                        ),
                      ],
                    ),
              
                  SizedBox(height: 20),
              
                  // ======================================
                  // BUTTON
                  // ======================================
                  GestureDetector(
                    onTap:
                        _isGenerating
                            ? null
                            : _generateQuiz,
              
                    child: Container(
                      height: 58,
              
                      decoration: BoxDecoration(
                        gradient:
                            const LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.secondary,
                          ],
                        ),
              
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
              
                        boxShadow: [
              
                          BoxShadow(
                            color: AppColors
                                .primary
                                .withValues(
                              alpha: 0.3,
                            ),
              
                            blurRadius: 18,
              
                            offset:
                                const Offset(
                              0,
                              8,
                            ),
                          ),
                        ],
                      ),
              
                      child: Center(
                        child:
                            _isGenerating
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
              
                                    child:
                                        CircularProgressIndicator(
                                      color:
                                          Colors
                                              .white,
              
                                      strokeWidth:
                                          2,
                                    ),
                                  )
                                : const Text(
                                    "Generate Quiz",
              
                                    style: TextStyle(
                                      color:
                                          Colors
                                              .white,
              
                                      fontWeight:
                                          FontWeight
                                              .w600,
              
                                      fontSize: 16,
                                    ),
                                  ),
                      ),
                    ),
                  ),
              
                  const SizedBox(height: 12),
                ],
                          
            ),
          ),
        ),
      ),
    ),
  ),
),
      );
  }

  // ====================================================
  // TEXT FIELD
  // ====================================================
  Widget _textField({
    required String label,
    required TextEditingController controller,
  }) {

    return Container(
      padding:
          const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: AppColors.border,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Text(
            label,

            style: const TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: controller,

            keyboardType:
                TextInputType.number,

            decoration:
                const InputDecoration(
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}

