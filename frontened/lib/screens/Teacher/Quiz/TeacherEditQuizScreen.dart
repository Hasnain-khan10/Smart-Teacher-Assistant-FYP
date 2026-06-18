import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontened/Provider/quiz_provider.dart';
import 'package:frontened/models/Quiz/quiz_model.dart';

class TeacherEditQuizScreen extends StatefulWidget {
  final Quiz quiz;
  final String courseId;

  const TeacherEditQuizScreen({super.key, required this.quiz, required this.courseId});

  @override
  State<TeacherEditQuizScreen> createState() => _TeacherEditQuizScreenState();
}

class _TeacherEditQuizScreenState extends State<TeacherEditQuizScreen> {
  late TextEditingController _titleController;

  // Maps to hold editable data
  List<Map<String, dynamic>> editableMcqs = [];
  List<Map<String, dynamic>> editableShorts = [];
  List<Map<String, dynamic>> editableLongs = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.quiz.title);

    // Load existing data into editable maps
    if (widget.quiz.type == 'mcq') {
      editableMcqs = widget.quiz.questions.map((q) => {
        "question": q.question,
        "options": Map<String, String>.from(q.options),
        "correctAnswer": q.correctAnswer,
        "marks": q.marks,
        "explanation": q.explanation
      }).toList();
    } else {
      editableShorts = widget.quiz.shortQuestions.map((q) => {
        "question": q.question, "idealAnswer": q.idealAnswer, "rubric": q.rubric, "marks": q.marks
      }).toList();

      editableLongs = widget.quiz.longQuestions.map((q) => {
        "question": q.question, "idealAnswer": q.idealAnswer, "rubric": q.rubric, "marks": q.marks
      }).toList();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _saveQuiz() async {
    final quizProvider = context.read<QuizProvider>();

    // Show Loading
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    final success = await quizProvider.updateQuiz(
      quizId: widget.quiz.id,
      courseId: widget.courseId,
      title: _titleController.text,
      questions: widget.quiz.type == 'mcq' ? editableMcqs : null,
      shortQuestions: widget.quiz.type != 'mcq' ? editableShorts : null,
      longQuestions: widget.quiz.type != 'mcq' ? editableLongs : null,
    );

    if (mounted) Navigator.pop(context); // Close loading

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Quiz Updated Successfully!"), backgroundColor: Colors.green));
      if (mounted) Navigator.pop(context); // Go back to previous screen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Update Failed: ${quizProvider.error}"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Edit Quiz", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4F46E5),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveQuiz,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Quiz Title", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            if (widget.quiz.type == 'mcq') ...[
              const Text("Edit MCQs", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF4F46E5))),
              ...editableMcqs.asMap().entries.map((e) => _buildMcqEditor(e.value, e.key)).toList(),
            ] else ...[
              if (editableShorts.isNotEmpty) ...[
                const Text("Edit Short Questions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal)),
                ...editableShorts.asMap().entries.map((e) => _buildSubjectiveEditor(e.value, e.key, "Short")).toList(),
                const SizedBox(height: 24),
              ],
              if (editableLongs.isNotEmpty) ...[
                const Text("Edit Long Questions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.purple)),
                ...editableLongs.asMap().entries.map((e) => _buildSubjectiveEditor(e.value, e.key, "Long")).toList(),
              ]
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMcqEditor(Map<String, dynamic> q, int index) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Q${index + 1}.", style: const TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              initialValue: q["question"],
              onChanged: (val) => q["question"] = val,
              decoration: const InputDecoration(hintText: "Question statement"),
            ),
            const SizedBox(height: 10),
            ...['A', 'B', 'C', 'D'].map((opt) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextFormField(
                initialValue: q["options"][opt],
                onChanged: (val) => q["options"][opt] = val,
                decoration: InputDecoration(prefixText: "$opt) ", isDense: true),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectiveEditor(Map<String, dynamic> q, int index, String type) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$type Q${index + 1}.", style: const TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              initialValue: q["question"],
              onChanged: (val) => q["question"] = val,
              decoration: const InputDecoration(labelText: "Question"),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: q["idealAnswer"],
              onChanged: (val) => q["idealAnswer"] = val,
              decoration: const InputDecoration(labelText: "Ideal Answer / Key"),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}