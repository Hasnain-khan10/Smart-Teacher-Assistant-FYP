import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:frontened/Provider/quiz_provider.dart';
import 'package:provider/provider.dart';


class TeacherAIMCQSQuizScreen extends StatefulWidget {
  final String  quizTitle;
  final String courseId;

  const TeacherAIMCQSQuizScreen({
    super.key,
    required this.quizTitle,
    required this.courseId,
  });

  @override
  State<TeacherAIMCQSQuizScreen> createState() =>
      _TeacherAIMCQSQuizScreenState();
}

class _TeacherAIMCQSQuizScreenState
    extends State<TeacherAIMCQSQuizScreen> {

  // ================= CONTROLLERS =================

  final TextEditingController _promptController =
      TextEditingController();

  final TextEditingController _questionCountController =
      TextEditingController(text: "10");

  final TextEditingController _marksController =
      TextEditingController(text: "1");

  String _difficulty = "medium";

  File? _selectedFile;

  // ================= DISPOSE =================

  @override
  void dispose() {
    _promptController.dispose();
    _questionCountController.dispose();
    _marksController.dispose();
    super.dispose();
  }

  // ================= PICK FILE =================

  Future<void> _pickFile() async {
    try {

      final result =
          await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'jpg',
          'jpeg',
          'png',
        ],
      );

      if (result == null) return;

      final file =
          File(result.files.single.path!);

      setState(() {
        _selectedFile = file;
      });

    } catch (e) {
      _showMessage(
        "Failed to pick file",
      );
    }
  }

  // ================= GENERATE QUIZ =================

  Future<void> _generateQuiz() async {

    final prompt =
        _promptController.text.trim();

    if (prompt.isEmpty) {
      _showMessage(
        "Prompt is required",
      );
      return;
    }

    if (_selectedFile == null) {
      _showMessage(
        "Please upload PDF or image",
      );
      return;
    }

    final provider =
        Provider.of<QuizProvider>(
      context,
      listen: false,
    );

    final result =
        await provider.createAIMCQQuiz(

      // ✅ COURSE
      courseId: widget.courseId,

      // ✅ PROMPT
      prompt: prompt,

      // ✅ SETTINGS
      difficulty: _difficulty,

      questionCount:
          int.tryParse(
                _questionCountController.text,
              ) ??
              10,

      marksPerQuestion:
          int.tryParse(
                _marksController.text,
              ) ??
              1,

      // ✅ FILE
      file: _selectedFile!,
    );

    if (!mounted) return;

    if (result != null) {

      _showMessage(
        "AI MCQ Quiz Created Successfully",
      );

      Navigator.pop(context, true);

    } else {

      _showMessage(
        provider.error ??
            "Failed to generate quiz",
      );
    }
  }

  // ================= MESSAGE =================

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {

    final provider =
        context.watch<QuizProvider>();

    return Scaffold(

      backgroundColor:
          Colors.white,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,

        title: const Text(
          "AI MCQ Quiz",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),

        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // ================= COURSE =================

            Container(
              width: double.infinity,

              padding:
                  const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(18),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: 0.05),

                    blurRadius: 10,

                    offset:
                        const Offset(0, 5),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(
                    "Course",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    widget.quizTitle,

                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ================= FILE PICKER =================

            const Text(
              "Upload PDF / Image",
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            GestureDetector(
              onTap: _pickFile,

              child: Container(
                width: double.infinity,

                padding:
                    const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(16),

                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),

                child: Column(
                  children: [

                    const Icon(
                      Icons.upload_file,
                      size: 40,
                      color: Color(0xFF4F46E5),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      _selectedFile == null
                          ? "Tap to upload PDF or image"
                          : _selectedFile!.path
                              .split("/")
                              .last,

                      textAlign: TextAlign.center,

                      style: TextStyle(
                        color:
                            _selectedFile == null
                                ? Colors.grey
                                : Colors.black,

                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ================= PROMPT =================

            const Text(
              "AI Prompt",
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 10),

            TextField(
              controller: _promptController,

              maxLines: 5,

              decoration: InputDecoration(
                hintText:
                    "Example:\nGenerate conceptual MCQS from uploaded PDF.\nFocus on important university exam concepts.",

                filled: true,
                fillColor: Colors.white,

                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),

                  borderSide:
                      BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ================= DIFFICULTY =================

            const Text(
              "Difficulty",
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
              ),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(14),
              ),

              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _difficulty,

                  isExpanded: true,

                  items: const [

                    DropdownMenuItem(
                      value: "easy",
                      child: Text("Easy"),
                    ),

                    DropdownMenuItem(
                      value: "medium",
                      child: Text("Medium"),
                    ),

                    DropdownMenuItem(
                      value: "hard",
                      child: Text("Hard"),
                    ),
                  ],

                  onChanged: (value) {

                    if (value == null) return;

                    setState(() {
                      _difficulty = value;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ================= QUESTION COUNT =================

            const Text(
              "Question Count",
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller:
                  _questionCountController,

              keyboardType:
                  TextInputType.number,

              decoration: InputDecoration(
                hintText:
                    "Enter question count",

                filled: true,
                fillColor: Colors.white,

                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),

                  borderSide:
                      BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ================= MARKS =================

            const Text(
              "Marks Per Question",
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _marksController,

              keyboardType:
                  TextInputType.number,

              decoration: InputDecoration(
                hintText:
                    "Enter marks",

                filled: true,
                fillColor: Colors.white,

                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),

                  borderSide:
                      BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 35),

            // ================= BUTTON =================

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton(

                onPressed:
                    provider.isGeneratingAI
                        ? null
                        : _generateQuiz,

                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xFF4F46E5,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),

                child:
                    provider.isGeneratingAI
                        ? const SizedBox(
                            height: 22,
                            width: 22,

                            child:
                                CircularProgressIndicator(
                              color:
                                  Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Generate AI MCQ Quiz",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}