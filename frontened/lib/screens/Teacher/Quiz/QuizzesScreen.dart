import 'package:flutter/material.dart';
import 'package:frontened/Provider/quiz_provider.dart';
import 'package:frontened/main.dart';
import 'package:frontened/models/Quiz/quiz_model.dart';
import 'package:frontened/screens/Teacher/Quiz/CreateQuizScreen.dart';
import 'package:frontened/screens/Teacher/Quiz/QuizResultScreen.dart';
import 'package:frontened/screens/Teacher/Quiz/TeacherQuizViewPDF.dart';
import 'package:provider/provider.dart';

class TeacherQuizzesScreen extends StatefulWidget {
  static const String quizzes = '/quizzes';

  final String courseId;
  final String title;


  final List<Quiz> quiz;

  const TeacherQuizzesScreen({
    super.key,
    required this.courseId,
    required this.title,
    required this.quiz,
  });

  @override
  State<TeacherQuizzesScreen> createState() =>
      _TeacherQuizzesScreenState();
}

class _TeacherQuizzesScreenState
    extends State<TeacherQuizzesScreen> {

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      Provider.of<QuizProvider>(
        context,
        listen: false,
      ).fetchAllQuizzes();
    });
  }

  List<Quiz> get sortedQuizzes {
    final list = [...widget.quiz];

    list.sort((a, b) {
      final aDate = a.createdAt ?? DateTime(2000);
      final bDate = b.createdAt ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {

    final provider = Provider.of<QuizProvider>(context);

  
    final List<Quiz> quizzes = sortedQuizzes;

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
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                /// ================= HEADER =================
                Row(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: 10),

                    const Expanded(
                      child: Text(
                        "Quizzes",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              AppColors.textPrimary,
                        ),
                      ),
                    ),

                    const SizedBox(width: 20),
                  ],
                ),

                const SizedBox(height: 18),

                /// ================= CREATE QUIZ =================
                _actionButton(
                  title: "Create Quiz",
                  icon: Icons.add_rounded,
                  gradient: const [
                    AppColors.primary,
                    AppColors.secondary,
                  ],

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TeacherCreateQuizScreen(
                          courseId:
                              widget.courseId,
                          courseTitle:
                              widget.title,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                /// ================= QUIZ PDF =================
                _actionButton(
                  title: "View Quiz PDF",
                  icon:
                      Icons.picture_as_pdf_rounded,

                  gradient: const [
                    AppColors.primary,
                    AppColors.secondary,
                  ],

                  onTap: () {

                    if (quizzes.isEmpty) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TeacherQuizViewPDF(
                          quiz: quizzes,
                        ),
                      ),
                    );
                  },
                ),
                //  const SizedBox(height: 12),
                //  _actionButton(
                //   title: "AI Question PDF",
                //   icon:
                //       Icons.picture_as_pdf_outlined,

                //   gradient: const [
                //     AppColors.primary,
                //     AppColors.secondary,
                //   ],

                //   onTap: () {

                //     if (quizzes.isEmpty) return;

                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //         builder: (_) =>
                //             AIQuestionPDF(
                //           quiz: quizzes,
                //         ),
                //       ),
                //     );
                //   },
                // ),

                const SizedBox(height: 20),
                Text("Student Result",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                 ),
                ),
                const SizedBox(height: 20),

                /// ================= QUIZ LIST =================
                Expanded(
                  child: provider.isLoading
                      ? const Center(
                          child:
                              CircularProgressIndicator(),
                        )

                      : ListView(
                          children:
                              quizzes.take(20).map((quiz) {

                            return _quizCard(
                              context,
                              quiz,
                            );

                          }).toList(),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {

    return GestureDetector(
      onTap: onTap,

      child: Container(
        height: 64,

        decoration: BoxDecoration(
          gradient:
              LinearGradient(colors: gradient),

          borderRadius:
              BorderRadius.circular(22),

          boxShadow: [
            BoxShadow(
              color: gradient.first
                  .withValues(alpha: 0.25),

              blurRadius: 18,

              offset: const Offset(0, 10),
            ),
          ],
        ),

        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            Container(
              padding: const EdgeInsets.all(8),

              decoration: BoxDecoration(
                color:
                    Colors.white.withValues(alpha: 0.18),

                borderRadius:
                    BorderRadius.circular(12),
              ),

              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),

            const SizedBox(width: 10),

            Flexible(
              child: Text(
                title,

                overflow:
                    TextOverflow.ellipsis,

                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quizCard(
    BuildContext context,
    Quiz quiz,
  ) {

    return GestureDetector(

      onTap: () {
        Navigator.push(
          context,

          MaterialPageRoute(
            builder: (_) =>
                TeacherQuizResultsScreen(
                  quizId: quiz.id,
                ),
          ),
        );
      },

      child: Container(
        margin:
            const EdgeInsets.only(bottom: 14),

        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),

          borderRadius:
              BorderRadius.circular(20),

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

            Container(
              height: 46,
              width: 46,

              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondary
                        .withValues(alpha: 0.3),

                    AppColors.primary
                        .withValues(alpha: 0.3),
                  ],
                ),

                borderRadius:
                    BorderRadius.circular(14),
              ),

              child: const Icon(
                Icons.quiz,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    quiz.title,

                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w600,

                      color:
                          AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "${quiz.type.toUpperCase()} • ${quiz.totalMarks} Marks",

                    style: const TextStyle(
                      fontSize: 13,

                      color:
                          AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}