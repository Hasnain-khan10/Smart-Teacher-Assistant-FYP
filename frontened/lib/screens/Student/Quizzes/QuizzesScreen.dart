import "dart:async";
import "dart:io";
import "package:flutter/material.dart";
import "package:frontened/Provider/quiz_provider.dart";
import "package:http/http.dart" as http;
import "package:open_file/open_file.dart";
import "package:path_provider/path_provider.dart";
import "package:provider/provider.dart";
import "package:intl/intl.dart";

class AppColors {
  static const Color primary = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF7C3AED);
}

class QuizzesScreen extends StatefulWidget {
  const QuizzesScreen({super.key});
  static const String routeName = "/quizzes";
  @override
  State<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen> {
  bool _isDownloading = false;
  int? _loadingQuizIndex;

  // 🔥 REAL-TIME ENGINE: For live countdowns and auto-locking/unlocking
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() { context.read<QuizProvider>().fetchAllQuizzes(); });

    // Updates UI every second to keep countdowns accurate
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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

  // 🔥 SAFE PARSERS: To handle dynamic model structures before we update quiz_model.dart
  DateTime? _getSafeDate(dynamic rawDate) {
    if (rawDate == null) return null;
    if (rawDate is DateTime) return rawDate;
    return DateTime.tryParse(rawDate.toString());
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return "00:00:00";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String days = d.inDays > 0 ? "${d.inDays}d " : "";
    String hours = twoDigits(d.inHours.remainder(24));
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$days$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuizProvider>();
    final quizzes = provider.quizzes;
    final now = DateTime.now();

    // 🔥 AUTOMATED FILTERING ENGINE
    final upcoming = quizzes.where((q) {
      if (_isCompletedSafe(q) || q.evaluatedByAI == true) return false; // Already done

      final deadline = _getSafeDate(q.deadlineDateTime);
      if (deadline != null && now.isAfter(deadline)) {
        // DEADLINE PASSED: Automatically terminate and vanish from dashboard
        return false;
      }
      return true;
    }).toList();

    final attempted = quizzes.where((q) => _isCompletedSafe(q) || q.evaluatedByAI == true).toList();
    _sortByCreatedAt(upcoming);
    _sortByCreatedAt(attempted);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 180.0, pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text("Quizzes", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                background: Container(
                  decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary])),
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
                  const Text("Scheduled & Active Exams", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                  const SizedBox(height: 10),
                  if (upcoming.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
                      child: const Center(child: Text("No scheduled or active exams.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                    )
                  else
                    ...upcoming.map((q) {
                      final openDate = _getSafeDate(q.openDateTime);
                      final deadline = _getSafeDate(q.deadlineDateTime);

                      final isLocked = openDate != null && now.isBefore(openDate);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: isLocked ? Colors.grey.shade50 : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isLocked ? Colors.grey.shade300 : Colors.blue.shade200, width: 1.5)
                        ),
                        child: Row(
                          children: [
                            Icon(isLocked ? Icons.lock_clock : Icons.timer, color: isLocked ? Colors.grey : Colors.blue, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(q.title ?? "Untitled Exam", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isLocked ? Colors.grey.shade700 : const Color(0xFF1E1B4B))),
                                  const SizedBox(height: 6),

                                  // Live Countdown or Lock Timer
                                  if (isLocked)
                                    Text("Unlocks at: ${DateFormat('dd MMM, hh:mm a').format(openDate)}", style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold))
                                  else if (deadline != null)
                                    Text("Ends in: ${_formatDuration(deadline.difference(now))}", style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold))
                                  else
                                    const Text("Active Now", style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold))
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                if (isLocked) {
                                  _showMessage("Exam Locked! This exam will activate precisely at ${DateFormat('hh:mm a, dd MMM').format(openDate)}", isError: true);
                                } else {
                                  Navigator.pushNamed(context, '/quiz-attempt', arguments: q);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isLocked ? Colors.grey.shade400 : const Color(0xFF4F46E5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: isLocked ? 0 : 2,
                              ),
                              child: Text(isLocked ? "Locked" : "Attempt", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 30),
                  const Text("Attempted Quizzes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                  const SizedBox(height: 10),
                  if (attempted.isEmpty)
                    const Text("No attempted quizzes.", style: TextStyle(color: Colors.grey))
                  else
                    ...attempted.map((q) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                      child: ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: Text(q.title ?? "Untitled", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Score: ${q.score ?? 0}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Navigator.pushNamed(context, '/quiz-result', arguments: q),
                      ),
                    )),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}