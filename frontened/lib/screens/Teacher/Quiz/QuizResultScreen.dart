import 'package:flutter/material.dart';
import 'package:frontened/Provider/quiz_provider.dart';
import 'package:frontened/main.dart';
import 'package:provider/provider.dart';

class TeacherQuizResultsScreen extends StatefulWidget {
  final String quizId;

  const TeacherQuizResultsScreen({
    super.key,
    required this.quizId,
  });

  @override
  State<TeacherQuizResultsScreen> createState() =>
      _TeacherQuizResultsScreenState();
}

class _TeacherQuizResultsScreenState
    extends State<TeacherQuizResultsScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      Provider.of<QuizProvider>(context, listen: false)
          .fetchQuizResults(widget.quizId, quizId: widget.quizId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<QuizProvider>(context);

    final data = provider.quizResults;

    final quiz = data?["quiz"];
    final results = (data?["results"] as List?) ?? [];

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
                /// ================= HEADER =================
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Quiz Results",
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

                const SizedBox(height: 18),

                /// ================= LOADING =================
                if (provider.isLoadingQuizResults)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  /// ================= QUIZ INFO =================
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz?["title"] ?? "Quiz Results",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Total Marks: ${quiz?["totalMarks"] ?? 0}",
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Student Results",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// ================= RESULTS =================
                  Expanded(
                    child: results.isEmpty
                        ? const Center(
                            child: Text("No results found"),
                          )
                        : ListView.builder(
                            itemCount: results.length,
                            itemBuilder: (context, index) {
                              final r = results[index] ?? {};

                              final name =
                                  r["name"] ?? "Student";

                              final id =
                                  r["email"] ?? "";

                              final int score =
                                  (r["score"] ?? 0).toInt();

                              final int total =
                                  (r["total"] ??
                                          quiz?["totalMarks"] ??
                                          0)
                                      .toInt();

                              final bool evaluatedByAI =
                                  r["evaluatedByAI"] ?? false;

                              return _resultCard(
                                name,
                                id,
                                score,
                                total,
                                evaluatedByAI,
                              );
                            },
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ================= RESULT CARD =================
  Widget _resultCard(
    String name,
    String id,
    int marks,
    int total,
    bool evaluatedByAI,
  ) {
    final double percentage =
        total == 0 ? 0 : marks / total;

    final Color markColor = percentage >= 0.7
        ? AppColors.success
        : (percentage >= 0.4
            ? AppColors.warning
            : AppColors.error);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          )
        ],
      ),
      child: Row(
        children: [
          /// AVATAR
          const CircleAvatar(
            radius: 22,
            backgroundImage:
                NetworkImage('https://i.pravatar.cc/150'),
          ),

          const SizedBox(width: 12),

          /// TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(width: 6),

                    /// AI BADGE
                    if (evaluatedByAI)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "AI Evaluated",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.purple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  id,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          /// ================= MARKS =================
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: markColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              /// 🔥 FINAL RULE (SAFE + CLEAN)
              "$marks / $total",
              style: TextStyle(
                color: markColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
