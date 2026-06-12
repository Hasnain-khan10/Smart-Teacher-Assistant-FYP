import 'package:flutter/material.dart';
import 'package:frontened/Provider/pdf_provider.dart';
import 'package:frontened/Provider/week_plan_provider.dart';
import 'package:provider/provider.dart';

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key});

  static const String routeName = '/course-detail';

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool _loaded = false;

  late final course;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_loaded) return;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args != null) {
      course = args;

      Future.microtask(() {
        Provider.of<WeekPlanProvider>(context, listen: false)
            .fetchPlan(course.id);
      });

      _loaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = Provider.of<WeekPlanProvider>(context).plan;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              size: 22, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Course Details",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            Text(
              course.title ?? "Course Title",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "Instructor: ${course.teacherName ?? "Unknown"}",
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 20),

            /// COURSE PDF
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf,
                      color: AppColors.error, size: 30),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Course Outline.pdf",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  Consumer<PdfProvider>(
                    builder: (context, pdfProvider, _) {
                      return TextButton(
                        onPressed: pdfProvider.isLoading
                            ? null
                            : () async {
                                await pdfProvider.openPDF(course.id);

                                if (pdfProvider.file == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text("Failed to open PDF"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "PDF opened successfully"),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                        child: pdfProvider.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Text(
                                "Open",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: "Weekly Plan ",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (plan?.semesterDuration != null)
                    TextSpan(
                      text:
                          "(${plan!.semesterDuration} Weeks)",
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: Consumer<WeekPlanProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  if (provider.plan == null ||
                      provider.plan!.weeks.isEmpty) {
                    return const Center(
                      child: Text("No Weekly Plan Found"),
                    );
                  }

                  final weeks = provider.plan!.weeks;

                  return ListView.builder(
                    itemCount: weeks.length,
                    itemBuilder: (context, index) {
                      final week = weeks[index];

                      return WeekItem(
                        courseId: course.id,
                        weekNumber: week.weekNumber,
                        week: "Week ${week.weekNumber}",
                        topic: week.topics.isNotEmpty
    ? week.topics.map((t) => t).join("\n")
    : "No topics available",
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================
/// WEEK ITEM
/// ============================
class WeekItem extends StatelessWidget {
  final String courseId;
  final int weekNumber;
  final String week;
  final String topic;

  const WeekItem({
    super.key,
    required this.courseId,
    required this.weekNumber,
    required this.week,
    required this.topic,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<WeekPlanProvider>(
      builder: (context, provider, _) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      week,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topic,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              /// 📄 PDF BUTTON
              provider.isWeekLoading(weekNumber)
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.picture_as_pdf,
                          color: AppColors.error),
                      onPressed: () async {
                        final success =
                            await provider.downloadAndOpenWeekPDF(
                          courseId,
                          weekNumber,
                        );

                        if (!success) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Failed to open Week PDF"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                  "Week $weekNumber PDF opened"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                    ),
            ],
          ),
        );
      },
    );
  }
}

/// ============================
/// COLORS
/// ============================
class AppColors {
  static const Color primary = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF7C3AED);
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1E1B4B);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color error = Color(0xFFEF4444);
}