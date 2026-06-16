import 'package:flutter/material.dart';
import 'package:frontened/Provider/quiz_provider.dart';
import 'package:frontened/Provider/course_provider.dart';
import 'package:provider/provider.dart';

class TeacherManualQuizScreen extends StatefulWidget {
  final String courseId;
  final String quizTitle;

  const TeacherManualQuizScreen({super.key, required this.courseId, required this.quizTitle});

  @override
  State<TeacherManualQuizScreen> createState() => _TeacherManualQuizScreenState();
}

class _TeacherManualQuizScreenState extends State<TeacherManualQuizScreen> {
  // Toggle State: true = MCQ Mode, false = Question Mode
  bool isMcqMode = true;

  List<Map<String, dynamic>> mcqQuestions = [];
  List<Map<String, dynamic>> subjectiveQuestions = [];

  // Edit State Trackers
  int? editingMcqIndex;
  int? editingSubjIndex;

  // Controllers for MCQ
  final mcqStatementCtrl = TextEditingController();
  final optACtrl = TextEditingController();
  final optBCtrl = TextEditingController();
  final optCCtrl = TextEditingController();
  final optDCtrl = TextEditingController();
  final mcqMarksCtrl = TextEditingController(text: "1");
  String correctOption = "A";

  // Controllers for Subjective Questions
  final qStatementCtrl = TextEditingController();
  final qMarksCtrl = TextEditingController(text: "5");
  String qType = "short"; // short or long

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CourseProvider>().fetchCourses());
  }

  @override
  void dispose() {
    mcqStatementCtrl.dispose(); optACtrl.dispose(); optBCtrl.dispose(); optCCtrl.dispose(); optDCtrl.dispose(); mcqMarksCtrl.dispose();
    qStatementCtrl.dispose(); qMarksCtrl.dispose();
    super.dispose();
  }

  // 🔥 Auto-fetch Subject Name
  String _getCourseTitle(BuildContext context) {
    final courses = context.read<CourseProvider>().courses;
    try {
      return courses.firstWhere((c) => c.id == widget.courseId).title;
    } catch (e) {
      return "Unknown Subject";
    }
  }

  // 🧮 Live Total Marks Calculator
  int get _totalMarks {
    int mcqTotal = mcqQuestions.fold(0, (sum, item) => sum + (item["marks"] as int));
    int subjTotal = subjectiveQuestions.fold(0, (sum, item) => sum + (item["marks"] as int));
    return mcqTotal + subjTotal;
  }

  // ==================== MCQ LOGIC ====================
  void _addOrUpdateMCQ() {
    if (mcqStatementCtrl.text.isEmpty || optACtrl.text.isEmpty || optBCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill the statement and at least Options A & B"), backgroundColor: Colors.red));
      return;
    }

    final newMcq = {
      "question": mcqStatementCtrl.text.trim(),
      "options": {
        "A": optACtrl.text.trim(), "B": optBCtrl.text.trim(),
        "C": optCCtrl.text.trim().isNotEmpty ? optCCtrl.text.trim() : "None",
        "D": optDCtrl.text.trim().isNotEmpty ? optDCtrl.text.trim() : "None",
      },
      "correctAnswer": correctOption,
      "marks": int.tryParse(mcqMarksCtrl.text.trim()) ?? 1
    };

    setState(() {
      if (editingMcqIndex != null) {
        mcqQuestions[editingMcqIndex!] = newMcq;
        editingMcqIndex = null; // Exit edit mode
      } else {
        mcqQuestions.add(newMcq);
      }

      // Clear Fields
      mcqStatementCtrl.clear(); optACtrl.clear(); optBCtrl.clear(); optCCtrl.clear(); optDCtrl.clear();
      correctOption = "A"; mcqMarksCtrl.text = "1";
    });

    FocusScope.of(context).unfocus(); // Drops the keyboard
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("MCQ Saved!"), backgroundColor: Colors.green, duration: Duration(milliseconds: 800)));
  }

  void _editMCQ(int index) {
    final q = mcqQuestions[index];
    setState(() {
      editingMcqIndex = index;
      mcqStatementCtrl.text = q["question"];
      optACtrl.text = q["options"]["A"];
      optBCtrl.text = q["options"]["B"];
      optCCtrl.text = q["options"]["C"] == "None" ? "" : q["options"]["C"];
      optDCtrl.text = q["options"]["D"] == "None" ? "" : q["options"]["D"];
      correctOption = q["correctAnswer"];
      mcqMarksCtrl.text = q["marks"].toString();
    });
  }

  // ==================== SUBJECTIVE LOGIC ====================
  void _addOrUpdateSubjectiveQuestion() {
    if (qStatementCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter the question statement"), backgroundColor: Colors.red));
      return;
    }

    final newSubj = {
      "question": qStatementCtrl.text.trim(),
      "marks": int.tryParse(qMarksCtrl.text.trim()) ?? 5,
      "type": qType
    };

    setState(() {
      if (editingSubjIndex != null) {
        subjectiveQuestions[editingSubjIndex!] = newSubj;
        editingSubjIndex = null; // Exit edit mode
      } else {
        subjectiveQuestions.add(newSubj);
      }

      // Clear Fields
      qStatementCtrl.clear(); qMarksCtrl.text = "5";
    });

    FocusScope.of(context).unfocus(); // Drops the keyboard
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Subjective Question Saved!"), backgroundColor: Colors.green, duration: Duration(milliseconds: 800)));
  }

  void _editSubjective(int index) {
    final q = subjectiveQuestions[index];
    setState(() {
      editingSubjIndex = index;
      qStatementCtrl.text = q["question"];
      qMarksCtrl.text = q["marks"].toString();
      qType = q["type"];
    });
  }

  // ==================== SUBMIT QUIZ ====================
  Future<void> _submitManualQuiz() async {
    if (mcqQuestions.isEmpty && subjectiveQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Add at least one question to publish!"), backgroundColor: Colors.red));
      return;
    }

    final provider = context.read<QuizProvider>();

    List<Map<String, dynamic>> shorts = subjectiveQuestions.where((q) => q["type"] == "short").toList();
    List<Map<String, dynamic>> longs = subjectiveQuestions.where((q) => q["type"] == "long").toList();

    String finalType = "mixed";
    if (mcqQuestions.isNotEmpty && shorts.isEmpty && longs.isEmpty) finalType = "mcq";
    if (mcqQuestions.isEmpty && (shorts.isNotEmpty || longs.isNotEmpty)) finalType = "question";

    bool success = await provider.createQuiz(
      courseId: widget.courseId,
      title: widget.quizTitle,
      type: finalType,
      questions: mcqQuestions,
      shortQuestions: shorts,
      longQuestions: longs,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Manual Exam Published Successfully! 🎉"), backgroundColor: Colors.green));
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? "Failed to publish quiz"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuizProvider>();
    final String courseTitle = _getCourseTitle(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.quizTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4F46E5),
        elevation: 0,
        actions: [
          // 🔥 Live Total Marks Badge in App Bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
              child: Text("Total: $_totalMarks Marks", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // ---------------- HEADER SECTION ----------------
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Highlighted Locked Subject Name
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.2))),
                  child: Row(
                    children: [
                      const Icon(Icons.school, color: Color(0xFF4F46E5)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Subject Domain", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                            Text(courseTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                          ],
                        ),
                      ),
                      const Icon(Icons.lock, color: Colors.grey, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Inline Mode Toggles
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          isMcqMode = true;
                          editingSubjIndex = null; // Clear edit state on switch
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(color: isMcqMode ? const Color(0xFF4F46E5) : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: isMcqMode ? const Color(0xFF4F46E5) : Colors.grey.shade300)),
                          child: Center(child: Text("MCQs Maker", style: TextStyle(fontWeight: FontWeight.bold, color: isMcqMode ? Colors.white : Colors.black54))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          isMcqMode = false;
                          editingMcqIndex = null; // Clear edit state on switch
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(color: !isMcqMode ? Colors.green.shade600 : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: !isMcqMode ? Colors.green.shade600 : Colors.grey.shade300)),
                          child: Center(child: Text("Subjective Qs", style: TextStyle(fontWeight: FontWeight.bold, color: !isMcqMode ? Colors.white : Colors.black54))),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ---------------- DYNAMIC BODY SECTION (Scrollable Form + List) ----------------
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 1. INPUT FORM CARD
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: isMcqMode ? _buildMCQForm() : _buildSubjectiveForm(),
                  ),

                  const SizedBox(height: 24),

                  // 2. REAL-TIME FILTERED QUESTIONS LIST
                  _buildQuestionsBankList(),
                ],
              ),
            ),
          ),

          // ---------------- BOTTOM PUBLISH ACTION ----------------
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                icon: provider.isLoading ? const SizedBox.shrink() : const Icon(Icons.cloud_upload, color: Colors.white),
                label: provider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text("Publish Exam (${mcqQuestions.length + subjectiveQuestions.length} Qs)", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: provider.isLoading ? null : _submitManualQuiz,
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGET: MCQ FORM ---
  Widget _buildMCQForm() {
    bool isEditing = editingMcqIndex != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isEditing ? "Edit MCQ Question" : "Design Multiple Choice Question", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
        const SizedBox(height: 16),
        TextField(controller: mcqStatementCtrl, maxLines: 2, decoration: InputDecoration(labelText: "Question Statement", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
        const SizedBox(height: 12),
        Row(children: [ Expanded(child: TextField(controller: optACtrl, decoration: const InputDecoration(labelText: "Option A", isDense: true))), const SizedBox(width: 10), Expanded(child: TextField(controller: optBCtrl, decoration: const InputDecoration(labelText: "Option B", isDense: true))) ]),
        const SizedBox(height: 12),
        Row(children: [ Expanded(child: TextField(controller: optCCtrl, decoration: const InputDecoration(labelText: "Option C", isDense: true))), const SizedBox(width: 10), Expanded(child: TextField(controller: optDCtrl, decoration: const InputDecoration(labelText: "Option D", isDense: true))) ]),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: correctOption,
                isExpanded: true,
                decoration: InputDecoration(labelText: "Correct Answer Key", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                items: ["A", "B", "C", "D"].map((e) => DropdownMenuItem(value: e, child: Text("Option $e"))).toList(),
                onChanged: (val) => setState(() => correctOption = val!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: TextField(controller: mcqMarksCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Marks", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
            width: double.infinity,
            height: 45,
            child: OutlinedButton.icon(
                onPressed: _addOrUpdateMCQ,
                icon: Icon(isEditing ? Icons.update : Icons.add),
                label: Text(isEditing ? "Update MCQ" : "Add MCQ to Bank", style: const TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF4F46E5), side: const BorderSide(color: Color(0xFF4F46E5)))
            )
        ),
      ],
    );
  }

  // --- WIDGET: SUBJECTIVE FORM ---
  Widget _buildSubjectiveForm() {
    bool isEditing = editingSubjIndex != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isEditing ? "Edit Subjective Question" : "Design Subjective Question", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
        const SizedBox(height: 16),
        TextField(controller: qStatementCtrl, maxLines: 3, decoration: InputDecoration(labelText: "Question Statement", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: qType,
                isExpanded: true,
                decoration: InputDecoration(labelText: "Question Size", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                items: const [
                  DropdownMenuItem(value: "short", child: Text("Short Answer", overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: "long", child: Text("Long Essay", overflow: TextOverflow.ellipsis))
                ],
                onChanged: (val) => setState(() => qType = val!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: qMarksCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Marks", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
            width: double.infinity,
            height: 45,
            child: OutlinedButton.icon(
                onPressed: _addOrUpdateSubjectiveQuestion,
                icon: Icon(isEditing ? Icons.update : Icons.add),
                label: Text(isEditing ? "Update Question" : "Add Question to Bank", style: const TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.green, side: const BorderSide(color: Colors.green))
            )
        ),
      ],
    );
  }

  // --- WIDGET: FILTERED QUESTIONS BANK LIST (Real-time View) ---
  Widget _buildQuestionsBankList() {
    // Determine which list to show based on the active tab
    List<Map<String, dynamic>> activeList = isMcqMode ? mcqQuestions : subjectiveQuestions;

    if (activeList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(isMcqMode ? "Added MCQs Bank" : "Added Subjective Bank", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        ),

        ...activeList.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> q = entry.value;

          if (isMcqMode) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: const Color(0xFF4F46E5), child: const Icon(Icons.format_list_bulleted, color: Colors.white, size: 18)),
                title: Text(q["question"], style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text("Ans: Option ${q["correctAnswer"]}  •  Marks: ${q["marks"]}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editMCQ(index)),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => setState(() => mcqQuestions.removeAt(index))),
                  ],
                ),
              ),
            );
          } else {
            bool isShort = q["type"] == "short";
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: Colors.green, child: Icon(isShort ? Icons.short_text : Icons.subject, color: Colors.white, size: 18)),
                title: Text(q["question"], style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text("Type: ${isShort ? 'Short Answer' : 'Long Essay'}  •  Marks: ${q["marks"]}", style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 13)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editSubjective(index)),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => setState(() => subjectiveQuestions.removeAt(index))),
                  ],
                ),
              ),
            );
          }
        }),
      ],
    );
  }
}