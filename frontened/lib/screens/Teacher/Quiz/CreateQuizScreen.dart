import 'package:flutter/material.dart';
import 'package:frontened/main.dart';
import 'package:frontened/screens/Teacher/Quiz/AiMCQSQuizScreen.dart';
import 'package:frontened/screens/Teacher/Quiz/AiQuestionQuizScreen.dart';
import 'package:frontened/screens/Teacher/Quiz/TeacherManuallyQuizScreen.dart';
class TeacherCreateQuizScreen extends StatefulWidget {
  static const String createQuiz = '/create-quiz';
  final String courseId;
  final String courseTitle;

  const TeacherCreateQuizScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<TeacherCreateQuizScreen> createState() =>
      _TeacherCreateQuizScreenState();
}

class _TeacherCreateQuizScreenState
    extends State<TeacherCreateQuizScreen> {
  
  // ✅ ADD CONTROLLER
  final TextEditingController _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// HEADER
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Create Quiz",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),

                const SizedBox(height: 20),

                /// QUIZ TITLE FIELD (REAL INPUT NOW)
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: "Enter Quiz Title",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  "Choose how you want to create your quiz",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 20),

                /// MANUAL BUTTON (WITH VALIDATION)
                _optionButton(
                  icon: Icons.edit_note,
                  title: "Create Manually",
                  onTap: () {
                    final title = _titleController.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please enter quiz title first",
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TeacherManuallyQuizScreen(
                          courseId: widget.courseId,
                          quizTitle: title,
                          
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 14),

                /// AI Generate Question
                _optionButton(
                  icon: Icons.auto_awesome,
                  title: "Generate Questions with AI",
                  onTap: () {
                    final title = _titleController.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please enter quiz title first",
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TeacherAIQuestionQuizScreen(
                              quizTitle: title,
                              courseId: widget.courseId,
                            ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 14),

                /// AI Generate MCQS
                 _optionButton(
                  icon: Icons.auto_awesome,
                  title: "Generate MCQS with AI",
                  onTap: () {
                    final title = _titleController.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please enter quiz title first",
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TeacherAIMCQSQuizScreen(
                              quizTitle: title,
                              courseId: widget.courseId,
                            ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _optionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}