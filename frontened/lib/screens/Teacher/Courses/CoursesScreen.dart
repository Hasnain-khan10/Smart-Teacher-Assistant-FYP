import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontened/Provider/course_provider.dart';
import 'package:frontened/main.dart';
import 'package:frontened/models/Quiz/quiz_model.dart';
import 'package:frontened/models/course_model.dart';
import 'package:frontened/screens/Teacher/Courses/CourseDetailScreen.dart';
import 'package:frontened/screens/Teacher/Courses/CourseMainScreen.dart';
import 'package:frontened/screens/Teacher/Courses/CreatecourseScreen.dart';
import 'package:provider/provider.dart';

class TeacherCoursesScreen extends StatefulWidget {
  static const String courses = '/teacher-courses';
  final String courseId;
  final List<Quiz> quiz;

  const TeacherCoursesScreen({super.key, required this.courseId, required this.quiz});

  @override
  State<TeacherCoursesScreen> createState() =>
      _TeacherCoursesScreenState();
}

class _TeacherCoursesScreenState extends State<TeacherCoursesScreen> {
  String? expandedCourseId;

  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<CourseProvider>().fetchCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();

    final sortedCourses = [...provider.courses];
    sortedCourses.sort((a, b) => b.id.compareTo(a.id));

    List<CourseModel> applyFilter(List<CourseModel> list) {
      if (searchQuery.isEmpty) return list;

      return list.where((c) {
        final q = searchQuery.toLowerCase();
        return c.title.toLowerCase().contains(q) ||
            c.courseCode.toLowerCase().contains(q) ||
            (c.teacherName ?? "").toLowerCase().contains(q);
      }).toList();
    }

    final currentCourses =
    applyFilter(sortedCourses.where((c) => c.progress < 100).toList());

    final previousCourses =
    applyFilter(sortedCourses.where((c) => c.progress >= 100).toList());

    return Scaffold(
      backgroundColor: Colors.white, /// 🔥 PURE WHITE BACKGROUND ENFORCED
      body: Container(
        color: Colors.white, /// 🔥 PURPLE GRADIENT COMPLETELY REMOVED
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// HEADER
                Row(
                  children: [
                    const Icon(Icons.menu, size: 24, color: AppColors.textPrimary),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Courses",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                  ],
                ),

                const SizedBox(height: 18),

                /// CREATE BUTTON
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>  TeacherCreateCourseScreen(quiz: widget.quiz),
                      ),
                    );
                  },
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "Create New Course",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                /// VIEW DETAIL BUTTON
                GestureDetector(
                  onTap: () {
                    if (sortedCourses.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("No courses available"),
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeacherCourseDetailScreen(
                          courseId: sortedCourses.first.id,
                          quiz: widget.quiz,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: const Center(
                      child: Text(
                        "View Course Details",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                /// SEARCH BAR FIXED WITH SUBTLE BORDER
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: (val) {
                      setState(() {
                        searchQuery = val;
                      });
                    },
                    style: const TextStyle(color: Colors.black87),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.grey),
                      hintText: "Search courses...",
                      hintStyle: TextStyle(color: Colors.black45),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: provider.isLoading
                      ? _buildShimmerList()
                      : provider.courses.isEmpty
                      ? const Center(child: Text("No courses available", style: TextStyle(color: Colors.black54)))
                      : RefreshIndicator(
                    onRefresh: () =>
                        context.read<CourseProvider>().fetchCourses(),
                    child: ListView(
                      children: [
                        const Text(
                          "Current Courses",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...currentCourses.take(15).map((c) => _courseCard(c)),
                        const SizedBox(height: 20),
                        const Text(
                          "Previous Courses",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...previousCourses.take(15).map((c) => _courseCard(c)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _courseCard(CourseModel course) {
    final isExpanded = expandedCourseId == course.id;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherCourseMainScreen(
              courseId: course.id,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondary.withValues(alpha: 0.3),
                        AppColors.primary.withValues(alpha: 0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.title,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(
                        "${course.teacherName ?? "Unknown"} • ${course.courseCode} • ${course.creditHours} Credit Hour",
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      expandedCourseId =
                      isExpanded ? null : course.id;
                    });
                  },
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(course.joinLink ?? "No join link", style: const TextStyle(color: Colors.black87)),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () async {
                          final link = course.joinLink;
                          if (link == null) return;

                          await Clipboard.setData(
                            ClipboardData(text: link),
                          );

                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Join link copied ✔"),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.secondary
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text("Copy",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, _) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}