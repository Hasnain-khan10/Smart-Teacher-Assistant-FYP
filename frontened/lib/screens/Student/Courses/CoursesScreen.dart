import 'package:flutter/material.dart';
import 'package:frontened/Provider/course_provider.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';


class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  static const String routeName = '/courses';

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  
  Future<void> _refresh() async {
    await Provider.of<CourseProvider>(context, listen: false)
        .fetchCourses();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<CourseProvider>(context, listen: false).fetchCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseProvider>(
      builder: (context, provider, child) {
        final courses = provider.courses.toList()
        ..sort((a, b) => b.id.compareTo(a.id));

        final activeCourses =
    courses.where((c) => c.progress < 1.0).toList()
      ..sort((a, b) => b.id.compareTo(a.id));

final completedCourses =
    courses.where((c) => c.progress >= 1.0).toList()
      ..sort((a, b) => b.id.compareTo(a.id));

        return Scaffold(
          backgroundColor: AppColors.background,
          bottomNavigationBar:
              const StudentBottomNavBar(currentIndex: 1),

          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: provider.isLoading
                    ? const CoursesShimmer()
                    : ListView(
                        children: [
                          const SizedBox(height: 10),

                          const Text(
                            "My Courses",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          const SizedBox(height: 6),

                          const Text(
                            "Track your enrolled courses",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            "Active Courses",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          const SizedBox(height: 12),

                          if (courses.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: Center(
                                child: Text("No courses enrolled"),
                              ),
                            )
                          else
                            ...activeCourses.map(
                              (course) => CourseCard(
                                title: course.title,
                                progress:
                                    (course.progress / 100).clamp(0.0, 1.0),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/course-detail',
                                    arguments: course,
                                  );
                                },
                              ),
                            ),

                          const SizedBox(height: 20),

                          if (completedCourses.isNotEmpty) ...[
                            const Text(
                              "Completed Courses",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),

                            ...completedCourses.map(
                              (course) => CourseCard(
                                title: course.title,
                                progress: 1.0,
                                isCompleted: true,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/course-detail',
                                    arguments: course,
                                  );
                                },
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ============================
/// COURSE CARD
/// ============================
class CourseCard extends StatelessWidget {
  final String title;
  final double progress;
  final bool isCompleted;
  final VoidCallback onTap;

  const CourseCard({
    super.key,
    required this.title,
    required this.progress,
    required this.onTap,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (isCompleted)
                  const Icon(Icons.check_circle,
                      color: AppColors.success),
              ],
            ),
            const SizedBox(height: 10),

            LinearProgressIndicator(
              value: progress,
              color: isCompleted
                  ? AppColors.success
                  : AppColors.primary,
              backgroundColor:
                  AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),

            const SizedBox(height: 6),

            Text(
              "${(progress * 100).toInt()}% Completed",
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================
/// FACEBOOK STYLE SHIMMER
/// ============================
class CoursesShimmer extends StatelessWidget {
  const CoursesShimmer({super.key});

  Widget box({double h = 14, double w = double.infinity}) {
    return Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView(
        children: [
          const SizedBox(height: 20),

          box(h: 22, w: 160),
          const SizedBox(height: 10),
          box(h: 14, w: 220),

          const SizedBox(height: 20),

          box(h: 18, w: 140),
          const SizedBox(height: 12),

          ...List.generate(
            6,
            (index) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  box(h: 16, w: 180),
                  const SizedBox(height: 10),
                  box(h: 10),
                  const SizedBox(height: 6),
                  box(h: 10, w: 200),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================
/// BOTTOM NAV
/// ============================
class StudentBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const StudentBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/student-home');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/courses');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/quizzes');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (i) => _onTap(context, i),
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.book), label: "Courses"),
        BottomNavigationBarItem(icon: Icon(Icons.quiz), label: "Quizzes"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
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
  static const Color success = Color(0xFF22C55E);
}