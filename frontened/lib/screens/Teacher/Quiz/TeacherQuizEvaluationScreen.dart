import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontened/Provider/quiz_provider.dart';
import 'package:frontened/models/Quiz/quiz_model.dart';
import 'package:frontened/screens/Teacher/Quiz/TeacherScannerOverlay.dart';

class TeacherQuizEvaluationScreen extends StatefulWidget {
  final String attemptId;
  final String quizId;
  final String courseId;
  final String studentId;
  final String studentName;
  final String quizType;
  final int score;
  final int totalMarks;
  final List<dynamic> detailedAnswers;
  final String aiFeedback;
  final List<String> scannedPaperUrls;
  final bool isResultView;

  const TeacherQuizEvaluationScreen({
    super.key,
    this.attemptId = "",
    required this.quizId,
    this.courseId = "",
    this.studentId = "",
    required this.studentName,
    required this.quizType,
    required this.score,
    required this.totalMarks,
    this.detailedAnswers = const [],
    this.aiFeedback = "No AI feedback available for this attempt.",
    this.scannedPaperUrls = const [],
    this.isResultView = false,
  });

  @override
  State<TeacherQuizEvaluationScreen> createState() => _TeacherQuizEvaluationScreenState();
}

class _TeacherQuizEvaluationScreenState extends State<TeacherQuizEvaluationScreen> {
  late int localScore;
  late List<dynamic> localAnswers;
  String localAttemptId = "";

  @override
  void initState() {
    super.initState();
    localScore = widget.score;
    localAnswers = List.from(widget.detailedAnswers);
    localAttemptId = widget.attemptId;
  }

  bool get isSubjective => widget.quizType != 'mcq';

  Future<void> _refreshLocalData() async {
    final res = await Provider.of<QuizProvider>(context, listen: false).fetchQuizResults(widget.quizId, quizId: widget.quizId);
    if (res != null) {
      final attemptList = res["results"] as List;
      final updatedAttempt = attemptList.firstWhere((r) => r["studentId"] == widget.studentId, orElse: () => null);
      if (updatedAttempt != null) {
        setState(() {
          localScore = updatedAttempt["score"];
          localAnswers = updatedAttempt["detailedAnswers"];
          localAttemptId = updatedAttempt["attemptId"];
        });
      }
    }
  }

  void _showEditMarksDialog({int? index, int currentMarks = 0, int maxMarks = 100}) {
    if (localAttemptId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Scan at least one question first to generate an attempt."), backgroundColor: Colors.orange));
      return;
    }

    TextEditingController scoreController = TextEditingController(text: currentMarks.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(index != null ? "Edit Q${index+1} Marks" : "Manual Override", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
        content: TextField(
          controller: scoreController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: "Enter New Score (Max: $maxMarks)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), prefixIcon: const Icon(Icons.edit_note, color: Color(0xFF4F46E5))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              int newScore = int.tryParse(scoreController.text) ?? currentMarks;
              if (newScore > maxMarks) newScore = maxMarks;

              Navigator.pop(context);
              bool success = await Provider.of<QuizProvider>(context, listen: false).updateManualMarks(attemptId: localAttemptId, manualScore: newScore, quizId: widget.quizId, questionIndex: index);

              if (success) {
                await _refreshLocalData();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Marks updated successfully!"), backgroundColor: Colors.green));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update marks."), backgroundColor: Colors.red));
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> _scanQuestion(int index, String qText, int maxMarks) async {
    final List<File>? scannedPages = await Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherScannerOverlay(studentName: widget.studentName, quizTitle: "Scanning Q${index+1}")));

    if (scannedPages != null && scannedPages.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Row(
            children: [CircularProgressIndicator(color: Color(0xFF4F46E5)), SizedBox(width: 20), Expanded(child: Text("🤖 AI is checking this answer...", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))))],
          ),
        ),
      );

      final result = await Provider.of<QuizProvider>(context, listen: false).scanAIQuizMarks(
          courseId: widget.courseId, studentId: widget.studentId, title: widget.quizType, quizId: widget.quizId, files: scannedPages,
          questionIndex: index, questionText: qText, maxMarks: maxMarks
      );

      if (mounted) Navigator.pop(context);

      if (result != null) {
        await _refreshLocalData();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Answer Evaluated Successfully!"), backgroundColor: Colors.green));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Scan Failed."), backgroundColor: Colors.red));
      }
    }
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent, insetPadding: const EdgeInsets.all(10),
        child: InteractiveViewer(panEnabled: true, boundaryMargin: const EdgeInsets.all(20), minScale: 0.5, maxScale: 4, child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(imageUrl, fit: BoxFit.contain))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Quiz? originalQuiz;
    try { originalQuiz = Provider.of<QuizProvider>(context, listen: false).quizzes.firstWhere((q) => q.id == widget.quizId); } catch(e) {}

    List<SubjectiveQuestion> allSubjQs = [];
    if (originalQuiz != null && isSubjective) {
      allSubjQs = [...originalQuiz.shortQuestions, ...originalQuiz.longQuestions];
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0, backgroundColor: const Color(0xFF4F46E5),
        title: Text(widget.isResultView ? "${widget.studentName}'s Result" : "Evaluate ${widget.studentName}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white), centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30),
            width: double.infinity,
            decoration: const BoxDecoration(color: Color(0xFF4F46E5), borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
            child: Column(
              children: [
                const Text("Grand Total Score", style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 40),
                    Text("$localScore / ${widget.totalMarks}", style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                    if (!isSubjective && localAttemptId.isNotEmpty)
                      IconButton(icon: const Icon(Icons.edit, color: Colors.white70, size: 28), onPressed: () => _showEditMarksDialog(currentMarks: localScore, maxMarks: widget.totalMarks)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
              child: isSubjective
                  ? ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: allSubjQs.length,
                  itemBuilder: (ctx, index) {
                    final q = allSubjQs[index];
                    final ans = localAnswers.length > index ? localAnswers[index] : null;
                    final int obtained = ans != null ? (ans['obtained_marks'] ?? 0) : 0;
                    final String? imageUrl = ans != null ? ans['scannedImageUrl'] : null;
                    final String feedback = ans != null ? (ans['aiFeedback'] ?? "") : ""; // 🔥 FETCH FEEDBACK

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Q${index+1}. ${q.question}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                          const Divider(height: 20),

                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                child: Text("Marks: $obtained / ${q.marks}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              ),
                              const Spacer(),

                              if (ans != null && localAttemptId.isNotEmpty)
                                IconButton(icon: const Icon(Icons.edit, color: Colors.grey), onPressed: () => _showEditMarksDialog(index: index, currentMarks: obtained, maxMarks: q.marks)),

                              if (widget.isResultView)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(horizontal: 10)),
                                  icon: const Icon(Icons.image, size: 16, color: Colors.white),
                                  label: const Text("View Paper", style: TextStyle(color: Colors.white)),
                                  onPressed: (imageUrl != null && imageUrl.isNotEmpty)
                                      ? () => _showFullScreenImage(imageUrl)
                                      : () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No scanned paper available."), backgroundColor: Colors.orange)); },
                                )
                              else
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), padding: const EdgeInsets.symmetric(horizontal: 10)),
                                  icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                  label: const Text("Scan", style: TextStyle(color: Colors.white)),
                                  onPressed: () => _scanQuestion(index, q.question, q.marks),
                                )
                            ],
                          ),

                          // 🔥 SHOW AI FEEDBACK IF AVAILABLE
                          if (feedback.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text("AI Evaluation Note:\n$feedback", style: TextStyle(color: Colors.amber.shade900, fontSize: 13, fontStyle: FontStyle.italic, height: 1.4))),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  }
              )
                  : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: localAnswers.length,
                  itemBuilder: (ctx, index) {
                    final ans = localAnswers[index];
                    final isCorrect = ans['isCorrect'] ?? false;
                    return Card(
                      elevation: 1, margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: isCorrect ? Colors.green : Colors.red, child: Icon(isCorrect ? Icons.check : Icons.close, color: Colors.white)),
                        title: Text("Q${index+1}. ${ans['question_text']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Student: ${ans['student_answer']}\nCorrect: ${ans['correct_answer']}"),
                      ),
                    );
                  }
              )
          )
        ],
      ),
    );
  }
}