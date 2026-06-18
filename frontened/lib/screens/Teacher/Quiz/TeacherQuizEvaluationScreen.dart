import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// 🔥 FIX: Yahan 'providers' ki jagah Capital 'Provider' kar diya hai
import 'package:frontened/Provider/quiz_provider.dart';

class TeacherQuizEvaluationScreen extends StatefulWidget {
  final String attemptId;
  final String quizId;
  final String studentName;
  final String quizType;
  final int score;
  final int totalMarks;
  final List<dynamic> detailedAnswers;
  final String aiFeedback;
  final List<String> scannedPaperUrls;

  const TeacherQuizEvaluationScreen({
    super.key,
    this.attemptId = "",
    this.quizId = "",
    required this.studentName,
    required this.quizType,
    required this.score,
    required this.totalMarks,
    this.detailedAnswers = const [],
    this.aiFeedback = "No AI feedback available for this attempt.",
    this.scannedPaperUrls = const [],
  });

  @override
  State<TeacherQuizEvaluationScreen> createState() => _TeacherQuizEvaluationScreenState();
}

class _TeacherQuizEvaluationScreenState extends State<TeacherQuizEvaluationScreen> {
  late int currentScore;

  @override
  void initState() {
    super.initState();
    currentScore = widget.score;
  }

  // 🔥 EDIT MARKS DIALOG BOX
  void _showEditMarksDialog() {
    TextEditingController scoreController = TextEditingController(text: currentScore.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Manual Override", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
        content: TextField(
          controller: scoreController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Enter New Score",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon: const Icon(Icons.edit_note, color: Color(0xFF4F46E5)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              int newScore = int.tryParse(scoreController.text) ?? currentScore;
              if (newScore > widget.totalMarks) newScore = widget.totalMarks;

              Navigator.pop(context);

              bool success = await Provider.of<QuizProvider>(context, listen: false)
                  .updateManualMarks(attemptId: widget.attemptId, manualScore: newScore, quizId: widget.quizId);

              if (success) {
                setState(() => currentScore = newScore);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Marks updated successfully!"), backgroundColor: Colors.green),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to update marks."), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // 🔥 FULL SCREEN IMAGE VIEWER
  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4F46E5),
        title: const Text("Student Result", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 1),

              // ================= STUDENT PROFILE & NAME =================
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF4F46E5), width: 3)),
                child: const CircleAvatar(radius: 50, backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.person, size: 60, color: Color(0xFF4F46E5))),
              ),
              const SizedBox(height: 20),

              Text(widget.studentName.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B), letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                    const SizedBox(width: 6),
                    Text("Evaluated Successfully", style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // ================= OBTAINED MARKS & EDIT ICON =================
              const Text("OBTAINED MARKS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5)),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 40),
                  Text(
                    "$currentScore",
                    style: const TextStyle(fontSize: 90, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5), height: 1.0),
                  ),
                  if (widget.attemptId.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.grey, size: 28),
                      onPressed: _showEditMarksDialog,
                      tooltip: "Edit Marks manually",
                    ),
                ],
              ),

              const Padding(padding: EdgeInsets.symmetric(horizontal: 80, vertical: 10), child: Divider(thickness: 2, color: Colors.grey)),

              // ================= TOTAL MARKS =================
              const Text("TOTAL MARKS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5)),
              const SizedBox(height: 5),
              Text("${widget.totalMarks}", style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.green)),

              const Spacer(flex: 1),

              // ================= SCANNED PAPER IMAGES (HORIZONTAL SCROLL) =================
              if (widget.scannedPaperUrls.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Attached Answer Sheets (${widget.scannedPaperUrls.length})", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.scannedPaperUrls.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _showFullScreenImage(widget.scannedPaperUrls[index]),
                        child: Container(
                          margin: const EdgeInsets.only(right: 15),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300, width: 2),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 3))],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.scannedPaperUrls[index],
                              width: 80,
                              fit: BoxFit.cover,
                              loadingBuilder: (ctx, child, progress) => progress == null ? child : const SizedBox(width: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                              errorBuilder: (ctx, err, stack) => Container(width: 80, color: Colors.grey.shade100, child: const Icon(Icons.broken_image, color: Colors.grey)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              if (widget.scannedPaperUrls.isEmpty) const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}