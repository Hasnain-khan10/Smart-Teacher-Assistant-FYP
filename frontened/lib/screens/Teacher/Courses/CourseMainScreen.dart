import 'dart:io';

import 'package:flutter/material.dart';
import 'package:frontened/Provider/week_plan_provider.dart';
import 'package:frontened/main.dart';
import 'package:frontened/services/week_plan_service.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class TeacherCourseMainScreen extends StatefulWidget {
  static const String courseMain = '/course-main';
  final String courseId;

  const TeacherCourseMainScreen({super.key, required this.courseId});

  @override
  State<TeacherCourseMainScreen> createState() =>
      _TeacherCourseMainScreenState();
}

class _TeacherCourseMainScreenState
    extends State<TeacherCourseMainScreen> {
  bool _loadingFullPdf = false;

  int? _loadingWeekPdf;

  /// ================= FULL AI PDF =================
  Future<void> _openAIPlanPDF() async {
    try {
      setState(() => _loadingFullPdf = true);

      final bytes =
      await WeekPlanService.downloadAIPlanPDF(widget.courseId);

      final dir = await getTemporaryDirectory();

      final file = File(
        "${dir.path}/AI_18_Week_Plan_${widget.courseId}.pdf",
      );

      await file.writeAsBytes(bytes);

      await OpenFile.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() => _loadingFullPdf = false);
    }
  }

  /// ================= WEEK PDF =================
  Future<void> _openWeekPDF(int weekNumber) async {
    setState(() => _loadingWeekPdf = weekNumber);

    await context
        .read<WeekPlanProvider>()
        .downloadAndOpenWeekPDF(widget.courseId, weekNumber);

    if (mounted) {
      setState(() => _loadingWeekPdf = null);
    }
  }

  /// ================= UPDATE AI =================
  void _showUpdateSheet(int weekNumber) {
    final controller = TextEditingController();
    bool isUpdating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Update Week $weekNumber (AI)",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Enter AI instructions...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      onPressed: isUpdating
                          ? null
                          : () async {
                        setModalState(() => isUpdating = true);

                        try {
                          await context
                              .read<WeekPlanProvider>()
                              .updateWeekAI(
                            widget.courseId,
                            weekNumber,
                            prompt: controller.text.trim(),
                          );

                          if (!mounted) return;
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Week $weekNumber updated successfully ✔",
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Update failed: ${e.toString()}",
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: isUpdating
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                          : const Text("Update with AI"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// ================= DELETE WEEK =================
  Future<void> _deleteWeek(int weekNumber) async {
    bool isDeleting = false;

    final confirm = await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.red, size: 40),
                    const SizedBox(height: 10),
                    Text(
                      "Delete Week $weekNumber?",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "This action cannot be undone.",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isDeleting
                                ? null
                                : () => Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: isDeleting
                                ? null
                                : () async {
                              setDialogState(() => isDeleting = true);

                              try {
                                await context
                                    .read<WeekPlanProvider>()
                                    .deleteWeek(
                                    widget.courseId, weekNumber);

                                if (!mounted) return;
                                Navigator.pop(context, true);

                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Week $weekNumber deleted ✔",
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;

                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Delete failed: ${e.toString()}",
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: isDeleting
                                ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                                : const Text("Delete"),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (confirm == true) {
    }
  }


  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<WeekPlanProvider>().fetchPlan(widget.courseId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WeekPlanProvider>();
    final plan = provider.plan;
    final weeks = plan?.weeks ?? [];

    return Scaffold(
      body: Column(
        children: [

          /// ================= HEADER =================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
                top: 50, left: 20, right: 20, bottom: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "AI Course Plan",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  plan?.title ?? "Loading Course...",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  "${plan?.courseCode ?? ''} • 18 Week Plan",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          /// ================= BODY =================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [

                  /// FULL PDF BUTTON
                  GestureDetector(
                    onTap: _loadingFullPdf ? null : _openAIPlanPDF,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf,
                              color: Colors.white),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              "Full AI 18-Week Plan PDF",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          _loadingFullPdf
                              ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white),
                          )
                              : const Icon(Icons.arrow_forward_ios,
                              color: Colors.white, size: 14),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "18 Weekly Plan Structure",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// ================= WEEK LIST =================
                  Expanded(
                    child: provider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                      itemCount: weeks.length,
                      itemBuilder: (context, index) {
                        final week = weeks[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey, width: 1),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x11000000),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [

                              Row(
                                children: [
                                  Container(
                                    height: 42,
                                    width: 42,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                      BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                        Icons.auto_awesome,
                                        color: AppColors.primary),
                                  ),

                                  const SizedBox(width: 10),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Week ${week.weekNumber}",
                                          style: const TextStyle(
                                              fontWeight:
                                              FontWeight.w600),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Topics: ${week.topics.join(', ')}",
                                          style: const TextStyle(
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),

                                  IconButton(
                                    onPressed: _loadingWeekPdf ==
                                        week.weekNumber
                                        ? null
                                        : () => _openWeekPDF(
                                        week.weekNumber),
                                    icon: _loadingWeekPdf ==
                                        week.weekNumber
                                        ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child:
                                      CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                        : const Icon(
                                        Icons.picture_as_pdf,
                                        color:
                                        AppColors.primary),
                                  )
                                ],
                              ),

                              const SizedBox(height: 10),

                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _showUpdateSheet(
                                              week.weekNumber),
                                      icon: const Icon(Icons.edit,
                                          size: 18),
                                      label: const Text("Update"),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style:
                                      OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      onPressed: () => _deleteWeek(
                                          week.weekNumber),
                                      icon: const Icon(Icons.delete,
                                          size: 18),
                                      label: const Text("Delete"),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}