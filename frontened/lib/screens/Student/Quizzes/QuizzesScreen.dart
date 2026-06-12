import "dart:io";
import "package:flutter/material.dart";
import "package:frontened/Provider/quiz_provider.dart";
import "package:frontened/utils/Auth_Widgets/Colors.dart";
import "package:http/http.dart" as http;
import "package:open_file/open_file.dart";
import "package:path_provider/path_provider.dart";
import "package:provider/provider.dart";
class QuizzesScreen extends StatefulWidget {
  const QuizzesScreen({super.key});
  static const String routeName = "/quizzes";
  @override
  State<QuizzesScreen> createState() => _QuizzesScreenState();
}
class _QuizzesScreenState extends State<QuizzesScreen> {
  bool _isDownloading = false;
  int? _loadingQuizIndex;
  @override
  void initState() {
    super.initState();
    Future.microtask(() { context.read<QuizProvider>().fetchAllQuizzes(); });
  }
  Future<void> _refresh() async { await context.read<QuizProvider>().fetchAllQuizzes(); }
  Future<void> _generateAndOpenPdf(dynamic quiz, int index) async {
    try {
      setState(() { _isDownloading = true; _loadingQuizIndex = index; });
      final provider = Provider.of<QuizProvider>(context, listen: false);
      final pdfUrl = await provider.generateQuestionQuizPDF(quiz.id, quizId: quiz.id, courseId: quiz.course, title: quiz.title);
      if (pdfUrl == null) { _showMessage("Failed to generate PDF", isError: true); return; }
      final response = await http.get(Uri.parse(pdfUrl));
      if (response.statusCode != 200) { _showMessage("Failed to download PDF", isError: true); return; }
      final dir = await getTemporaryDirectory();
      final filePath = "${dir.path}/${quiz.title}.pdf";
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      await OpenFile.open(file.path);
      _showMessage("PDF opened successfully");
    } catch (e) { _showMessage(e.toString(), isError: true); }
    finally { setState(() { _isDownloading = false; _loadingQuizIndex = null; }); }
  }
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: isError ? Colors.redAccent : AppColors.primary, behavior: SnackBarBehavior.floating));
  }
  List _sortByCreatedAt(List quizzes) {
    quizzes.sort((a, b) {
      final DateTime aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return quizzes;
  }
  bool _isCompletedSafe(dynamic quiz) => quiz.isCompleted == true;
  bool _isQuestionQuiz(dynamic quiz) => quiz.type != "mcq";
  bool _isNewQuiz(dynamic quiz) {
    final DateTime date = quiz.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.now().difference(date).inHours <= 24;
  }
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuizProvider>();
    final quizzes = provider.quizzes;
    final upcoming = quizzes.where((q) => !_isCompletedSafe(q) && q.evaluatedByAI != true).toList();
    final attempted = quizzes.where((q) => _isCompletedSafe(q) || q.evaluatedByAI == true).toList();
    _sortByCreatedAt(upcoming); _sortByCreatedAt(attempted);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0, pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text("Quizzes", style: TextStyle(fontWeight: FontWeight.bold)),
              background: Container(
                decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary])),
                child: const Padding(
                  padding: EdgeInsets.only(left: 20, bottom: 60),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Dashboard", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text("Learning Journey", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                  ]),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Upcoming", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (upcoming.isEmpty) const Text("None") else SizedBox(height: 150, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: upcoming.length, itemBuilder: (c, i) => _buildCard(upcoming[i]))),
                const SizedBox(height: 20),
                const Text("Attempted", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ...attempted.map((q) => _buildAttempted(q)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildCard(dynamic quiz) {
    return Container(width: 200, margin: const EdgeInsets.only(right: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]), child: Center(child: Text(quiz.title)));
  }
  Widget _buildAttempted(dynamic quiz) {
    return ListTile(title: Text(quiz.title), subtitle: Text("Score: ${quiz.score ?? 0}"));
  }
}
