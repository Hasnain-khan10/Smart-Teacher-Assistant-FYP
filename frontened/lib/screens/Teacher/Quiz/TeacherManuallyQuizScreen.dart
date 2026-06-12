import 'package:flutter/material.dart';
import 'package:frontened/Provider/quiz_provider.dart';
import 'package:provider/provider.dart';


class TeacherManuallyQuizScreen extends StatefulWidget {
  final String courseId;
 
  final String quizTitle;

  const TeacherManuallyQuizScreen({
    super.key,
    required this.courseId,
    required this.quizTitle,
  });

  @override
  State<TeacherManuallyQuizScreen> createState() =>
      _TeacherManuallyQuizScreenState();
}

class _TeacherManuallyQuizScreenState
    extends State<TeacherManuallyQuizScreen> {

  final TextEditingController _titleController = TextEditingController();

  String _selectedType = "mcq";

  final List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
     _titleController.text = widget.quizTitle;
    _addQuestion();
  }

  @override
  void dispose() {
    _titleController.dispose();

    for (final q in _questions) {
      (q["question"] as TextEditingController).dispose();
      (q["optionA"] as TextEditingController).dispose();
      (q["optionB"] as TextEditingController).dispose();
      (q["optionC"] as TextEditingController).dispose();
      (q["optionD"] as TextEditingController).dispose();
      (q["marks"] as TextEditingController).dispose();
    }

    super.dispose();
  }

  // ================================
  // ADD QUESTION
  // ================================
  void _addQuestion() {
    setState(() {
      _questions.add({
        "question": TextEditingController(),

        // MCQ
        "optionA": TextEditingController(),
        "optionB": TextEditingController(),
        "optionC": TextEditingController(),
        "optionD": TextEditingController(),
        "correctAnswer": "A",

        // COMMON
        "marks": TextEditingController(text: "1"),
      });
    });
  }

  // ================================
  // REMOVE QUESTION
  // ================================
  void _removeQuestion(int index) {
    if (_questions.length == 1) return;

    setState(() {
      _questions.removeAt(index);
    });
  }

  // ================================
  // CREATE QUIZ
  // ================================
  // ================================
// CREATE QUIZ
// ================================
Future<void> _createQuiz() async {
  final provider = context.read<QuizProvider>();

  final title = _titleController.text.trim();

  if (title.isEmpty) {
    _show("Enter quiz title");
    return;
  }

  final List<Map<String, dynamic>> mcqQuestions = [];
  final List<Map<String, dynamic>> shortQuestions = [];

  for (final q in _questions) {
    final question =
        (q["question"] as TextEditingController).text.trim();

    final marks =
        int.tryParse((q["marks"] as TextEditingController).text.trim()) ?? 1;

    if (question.isEmpty) continue;

    if (_selectedType == "mcq") {
      final a = (q["optionA"] as TextEditingController).text.trim();
      final b = (q["optionB"] as TextEditingController).text.trim();
      final c = (q["optionC"] as TextEditingController).text.trim();
      final d = (q["optionD"] as TextEditingController).text.trim();

      if (a.isEmpty || b.isEmpty || c.isEmpty || d.isEmpty) {
        _show("Fill all MCQ options");
        return;
      }

      mcqQuestions.add({
        "question": question,
        "options": {
          "A": a,
          "B": b,
          "C": c,
          "D": d,
        },
        "correctAnswer": q["correctAnswer"] ?? "A",
        "marks": marks,
      });
    } else {
      shortQuestions.add({
        "question": question,
        "marks": marks,
      });
    }
  }

  if (_selectedType == "mcq" && mcqQuestions.isEmpty) {
    _show("Add at least one MCQ");
    return;
  }

  if (_selectedType == "question" && shortQuestions.isEmpty) {
    _show("Add at least one question");
    return;
  }

  final success = await provider.createQuiz(
    courseId: widget.courseId,
    title: title, 
    type: _selectedType,

    questions: _selectedType == "mcq" ? mcqQuestions : null,
    shortQuestions: _selectedType == "question" ? shortQuestions : null,
    longQuestions: [],
  );

  if (!mounted) return;

  if (success) {
    Navigator.pop(context);
    _show("Quiz created successfully");
  } else {
    _show(provider.error ?? "Failed to create quiz");
  }
}

  // ================================
  // SNACKBAR
  // ================================
  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuizProvider>();

    final isMCQ = _selectedType == "mcq";

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // =================================
              // HEADER
              // =================================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
                        ),
                      ),
                    ),

                    const Expanded(
                      child: Text(
                        "Create Quiz",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                    ),

                    const SizedBox(width: 42),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // =================================
                    // COURSE CARD
                    // =================================
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withValues(alpha: 0.08),
                            blurRadius: 25,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 58,
                            width: 58,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF8B5CF6),
                                  Color(0xFF6D28D9),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Quiz",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.quizTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Color(0xFF1E1E1E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // =================================
                    // TYPE SELECTOR
                    // =================================
                    Row(
                      children: [
                        Expanded(
                          child: _typeButton(
                            title: "MCQ Quiz",
                            icon: Icons.quiz_rounded,
                            value: "mcq",
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: _typeButton(
                            title: "Questions",
                            icon: Icons.description_rounded,
                            value: "question",
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // =================================
                    // TITLE FIELD
                    // =================================
                   _inputField(
  controller: _titleController,
  hint: "Enter Quiz Title",
  icon: Icons.title_rounded,
),

                    const SizedBox(height: 24),

                    // =================================
                    // QUESTIONS
                    // =================================
                    ListView.builder(
                      itemCount: _questions.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (_, index) {
                        return _questionCard(index, isMCQ);
                      },
                    ),

                    const SizedBox(height: 10),

                    // =================================
                    // ADD QUESTION
                    // =================================
                    GestureDetector(
                      onTap: _addQuestion,
                      child: Container(
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.deepPurple,
                            width: 1.4,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline_rounded,
                              color: Colors.deepPurple,
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Add Question",
                              style: TextStyle(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // =================================
                    // CREATE BUTTON
                    // =================================
                    GestureDetector(
                      onTap:
                          provider.isCreating ? null : _createQuiz,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF7C3AED),
                              Color(0xFF5B21B6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: provider.isCreating
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  "Create Quiz",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =================================
  // TYPE BUTTON
  // =================================
  Widget _typeButton({
    required String title,
    required IconData icon,
    required String value,
  }) {
    final selected = _selectedType == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = value;
          _questions.clear();
          _addQuestion();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [
                    Color(0xFF8B5CF6),
                    Color(0xFF6D28D9),
                  ],
                )
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Colors.deepPurple.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? Colors.deepPurple.withValues(alpha: 0.22)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : Colors.deepPurple,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =================================
  // QUESTION CARD
  // =================================
  Widget _questionCard(int index, bool isMCQ) {
    final q = _questions[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // ================= HEADER
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF8B5CF6),
                      Color(0xFF6D28D9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    "${index + 1}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Text(
                  "Question",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),

              GestureDetector(
                onTap: () => _removeQuestion(index),
                child: Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ================= QUESTION FIELD
          _inputField(
            controller: q["question"],
            hint: "Enter your question",
            icon: Icons.help_outline_rounded,
            maxLines: 3,
          ),

          const SizedBox(height: 16),

          // ================= MCQ
          if (isMCQ) ...[
            _optionField(
              label: "A",
              controller: q["optionA"],
            ),

            const SizedBox(height: 12),

            _optionField(
              label: "B",
              controller: q["optionB"],
            ),

            const SizedBox(height: 12),

            _optionField(
              label: "C",
              controller: q["optionC"],
            ),

            const SizedBox(height: 12),

            _optionField(
              label: "D",
              controller: q["optionD"],
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: q["correctAnswer"],
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(16),
                  items: const [
                    DropdownMenuItem(
                      value: "A",
                      child: Text("Correct Answer: A"),
                    ),
                    DropdownMenuItem(
                      value: "B",
                      child: Text("Correct Answer: B"),
                    ),
                    DropdownMenuItem(
                      value: "C",
                      child: Text("Correct Answer: C"),
                    ),
                    DropdownMenuItem(
                      value: "D",
                      child: Text("Correct Answer: D"),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() {
                      q["correctAnswer"] = v;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],

          // ================= MARKS
          _inputField(
            controller: q["marks"],
            hint: "Marks",
            icon: Icons.star_outline_rounded,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  // =================================
  // INPUT FIELD
  // =================================
  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.deepPurple.withValues(alpha: 0.08),
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: Colors.deepPurple,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  // =================================
  // OPTION FIELD
  // =================================
  Widget _optionField({
    required String label,
    required TextEditingController controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF8B5CF6),
                  Color(0xFF6D28D9),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Enter option",
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}