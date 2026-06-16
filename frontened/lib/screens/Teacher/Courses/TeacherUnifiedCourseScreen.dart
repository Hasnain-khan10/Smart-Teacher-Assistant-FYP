import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontened/Provider/course_provider.dart';
import 'package:frontened/Provider/quiz_provider.dart';
import 'package:frontened/Provider/week_plan_provider.dart';
import 'package:frontened/screens/Teacher/Courses/GenerateAIPlanScreen.dart';
import 'package:frontened/screens/Teacher/Quiz/CreateQuizScreen.dart';
import 'package:frontened/screens/Teacher/Quiz/TeacherQuizManagementCenter.dart';
import 'package:frontened/models/week_plan_model.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart'; // 🔥 Naya Share import

class TeacherUnifiedCourseScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const TeacherUnifiedCourseScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<TeacherUnifiedCourseScreen> createState() => _TeacherUnifiedCourseScreenState();
}

class _TeacherUnifiedCourseScreenState extends State<TeacherUnifiedCourseScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    Future.microtask(() {
      context.read<WeekPlanProvider>().fetchPlan(widget.courseId);
      context.read<QuizProvider>().fetchAllQuizzes();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _copyJoinLink() {
    try {
      final courses = context.read<CourseProvider>().courses;
      final currentCourse = courses.firstWhere((c) => c.id == widget.courseId);

      if (currentCourse.joinLink != null && currentCourse.joinLink!.isNotEmpty) {
        Clipboard.setData(ClipboardData(text: currentCourse.joinLink!));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Join link copied to clipboard!"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invite link not available."), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Course data not found."), backgroundColor: Colors.red));
    }
  }

  // Share Content with ChatGPT / Gemini
  void _shareWeekToAI(WeekModel week) {
    String textToShare = """
I am preparing a lecture for university students. Can you provide a highly detailed and expansive explanation for the following topic?

*Course:* ${widget.courseTitle}
*Week ${week.weekNumber}:* ${week.title}
*Definition:* ${week.definition}
*Sub-Topics:* ${week.subTopics.join(", ")}
*Analogy Idea:* ${week.realWorldAnalogy}

Please expand on this comprehensively.
""";
    Share.share(textToShare);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4F46E5),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.courseTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const Text("Course Management Workspace", style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: "Copy Student Invite Link",
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _copyJoinLink,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(15)),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              labelColor: const Color(0xFF4F46E5),
              unselectedLabelColor: Colors.white,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [Tab(text: "18-Week Syllabus"), Tab(text: "Quizzes & Exams")],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSyllabusTab(),
          _buildQuizzesTab(),
        ],
      ),
    );
  }

  // ===============================================
  // SYLLABUS TAB
  // ===============================================
  Widget _buildSyllabusTab() {
    final provider = context.watch<WeekPlanProvider>();
    final plan = provider.plan;

    if (provider.isLoading) return const Center(child: CircularProgressIndicator());

    if (plan == null || plan.weeks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AnimatedWaveButtonSquare(
              title: "Create AI Weekly Plan",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherAIWeekPlanScreen(courseId: widget.courseId))),
            ),
            const SizedBox(height: 20),
            const Text("No Syllabus Found", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 🔥 EXTRA PDF CARD REMOVED AS REQUESTED!

        // EXPANDABLE WEEKS LIST
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Padding adjusted
            itemCount: plan.weeks.length,
            itemBuilder: (context, index) {
              final week = plan.weeks[index];
              final bool isWorking = provider.isWeekActionLoading(week.weekNumber);

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade300)),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
                      child: isWorking
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text("${week.weekNumber}", style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                    ),
                    title: Text(week.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text(week.subTopics.join(", "), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12)),

                    // 🔥 NEW REQUESTED ACTION ICONS
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                          tooltip: "Edit Week",
                          onPressed: () => _showEditChoiceDialog(week, plan.id, plan.weeks),
                        ),
                        IconButton(
                          icon: const Icon(Icons.download, color: Colors.blue, size: 20),
                          tooltip: "Download/Open PDF",
                          onPressed: () => provider.downloadAndOpenWeekPDF(widget.courseId, week.weekNumber),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.green, size: 20),
                          tooltip: "Share to AI / App",
                          onPressed: () => _shareWeekToAI(week),
                        ),
                      ],
                    ),

                    childrenPadding: const EdgeInsets.all(16),
                    children: [
                      // Definition
                      if (week.definition.isNotEmpty)
                        Container(
                          width: double.infinity, padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10), border: const Border(left: BorderSide(color: Colors.blue, width: 4))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Core Definition", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                              const SizedBox(height: 4),
                              Text(week.definition, style: TextStyle(fontSize: 14, color: Colors.blue.shade900)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),

                      // Explanation
                      if (week.detailedExplanation.isNotEmpty) ...[
                        const Align(alignment: Alignment.centerLeft, child: Text("Brief Explanation", style: TextStyle(fontWeight: FontWeight.bold))),
                        const SizedBox(height: 6),
                        Text(week.detailedExplanation, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
                        const SizedBox(height: 12),
                      ],

                      // Code
                      if (week.codeOrQuerySnippet.isNotEmpty) ...[
                        Container(
                          width: double.infinity, padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(children: [Icon(Icons.code, color: Colors.grey, size: 16), SizedBox(width: 8), Text("Code / Snippet", style: TextStyle(color: Colors.grey, fontSize: 12))]),
                              const SizedBox(height: 8),
                              Text(week.codeOrQuerySnippet, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 13)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Analogy
                      if (week.realWorldAnalogy.isNotEmpty)
                        Container(
                          width: double.infinity, padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.shade200)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lightbulb, color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Real-World Analogy", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                    const SizedBox(height: 4),
                                    Text(week.realWorldAnalogy, style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.orange.shade900)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ===============================================
  // DIALOGS: Edit Options (AI / Manual)
  // ===============================================

  void _showEditChoiceDialog(WeekModel week, String planId, List<WeekModel> allWeeks) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Week"),
        content: const Text("How would you like to edit this week?"),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            label: const Text("By Prompt (AI)", style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pop(ctx);
              _showAIEditDialog(week);
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            icon: const Icon(Icons.edit, color: Colors.white, size: 16),
            label: const Text("Manually", style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pop(ctx);
              _showManualEditDialog(week, planId, allWeeks);
            },
          ),
        ],
      ),
    );
  }

  void _showAIEditDialog(WeekModel week) {
    final TextEditingController promptCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [const Icon(Icons.auto_awesome, color: Color(0xFF4F46E5)), const SizedBox(width: 8), Text("AI Edit Week ${week.weekNumber}")]),
        content: TextField(
          controller: promptCtrl,
          maxLines: 3,
          decoration: InputDecoration(hintText: "Tell AI what to change...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5)),
            onPressed: () {
              if (promptCtrl.text.isNotEmpty) {
                context.read<WeekPlanProvider>().updateWeekAI(widget.courseId, week.weekNumber, prompt: promptCtrl.text);
              }
              Navigator.pop(ctx);
            },
            child: const Text("Apply", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _showManualEditDialog(WeekModel week, String planId, List<WeekModel> allWeeks) {
    final TextEditingController titleCtrl = TextEditingController(text: week.title);
    final TextEditingController defCtrl = TextEditingController(text: week.definition);
    final TextEditingController expCtrl = TextEditingController(text: week.detailedExplanation);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Manual Edit Week ${week.weekNumber}"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Topic Title")),
              const SizedBox(height: 10),
              TextField(controller: defCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Definition")),
              const SizedBox(height: 10),
              TextField(controller: expCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "Brief Explanation")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              final updatedWeek = WeekModel(
                weekNumber: week.weekNumber,
                title: titleCtrl.text,
                definition: defCtrl.text,
                detailedExplanation: expCtrl.text,
                subTopics: week.subTopics,
                codeOrQuerySnippet: week.codeOrQuerySnippet,
                realWorldAnalogy: week.realWorldAnalogy,
              );
              final index = allWeeks.indexWhere((w) => w.weekNumber == week.weekNumber);
              if (index != -1) {
                allWeeks[index] = updatedWeek;
                context.read<WeekPlanProvider>().updatePlan(planId, allWeeks);
              }
              Navigator.pop(ctx);
            },
            child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // ===============================================
  // QUIZZES TAB
  // ===============================================
  Widget _buildQuizzesTab() {
    final provider = context.watch<QuizProvider>();
    final courseQuizzes = provider.quizzes.where((q) => q.course == widget.courseId).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _AnimatedWaveButtonSquare(
            title: "Create New Exam",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherCreateQuizScreen(courseId: widget.courseId, courseTitle: widget.courseTitle))),
          ),
        ),
        Expanded(
          child: courseQuizzes.isEmpty
              ? const Center(child: Text("No quizzes found.", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: courseQuizzes.length,
            itemBuilder: (context, index) {
              final quiz = courseQuizzes[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))]
                ),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.green.shade50, child: const Icon(Icons.assignment, color: Colors.green)),
                  title: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${quiz.type.toUpperCase()} Format • ${quiz.totalMarks} Marks", style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TeacherQuizManagementCenter(
                          quizId: quiz.id,
                          courseId: widget.courseId,
                          quizTitle: quiz.title,
                          quizType: quiz.type,
                          totalMarks: quiz.totalMarks
                      )),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AnimatedWaveButtonSquare extends StatefulWidget {
  final VoidCallback onTap;
  final String title;
  const _AnimatedWaveButtonSquare({required this.onTap, required this.title});
  @override
  State<_AnimatedWaveButtonSquare> createState() => _AnimatedWaveButtonSquareState();
}

class _AnimatedWaveButtonSquareState extends State<_AnimatedWaveButtonSquare> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 1.0 + (_controller.value * 0.2),
                child: Opacity(
                  opacity: 1.0 - _controller.value,
                  child: Container(width: 250, height: 60, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0xFF4F46E5).withOpacity(0.4))),
                ),
              ),
              Container(
                width: 250, height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Center(child: Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
              ),
            ],
          );
        },
      ),
    );
  }
}