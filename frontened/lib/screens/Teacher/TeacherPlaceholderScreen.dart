import 'package:flutter/material.dart';
import 'package:frontened/Provider/auth_provider.dart';
import 'package:frontened/Provider/course_provider.dart';
import 'package:frontened/Provider/quiz_provider.dart';
import 'package:frontened/models/Quiz/quiz_model.dart';
import 'package:frontened/models/course_model.dart';
import 'package:frontened/screens/Teacher/Courses/CourseMainScreen.dart';
import 'package:frontened/screens/Teacher/Courses/CoursesScreen.dart';
import 'package:frontened/screens/Teacher/Quiz/QuizzesScreen.dart';
import 'package:frontened/screens/Teacher/Teacher_ProfileScreen.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class TeacherDashboardScreen extends StatefulWidget {
  static const String teacherRouteName = '/teacher-dashboard';

  const TeacherDashboardScreen({super.key});

  // ===== App Colors =====
  static const Color primary = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF7C3AED);
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1E1B4B);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color border = Color(0xFFE9EAF4);

  @override
  State<TeacherDashboardScreen> createState() =>
      _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<QuizProvider>().fetchAllQuizzes();
  });
  
    _loadCourses();
    _loadProfile();
  }

   Future<void> _loadProfile() async {
    try {
     await context
                      .read<AuthProvider>()
                      .loadProfile();
    } catch (e) {
      debugPrint(e.toString());
    }
   }

   

  Future<void> _loadCourses() async {
    try {
      await context.read<CourseProvider>().fetchCourses();
    } catch (e) {
      debugPrint(e.toString());
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = context.watch<CourseProvider>();
    final courses = courseProvider.courses;

    final quizProvider = context.watch<QuizProvider>();
    final quizzes = quizProvider.quizzes;

    courses.sort((a, b) {
    return b.id.compareTo(a.id); 
   });

    // Default selected course
    final CourseModel? selectedCourse =
        courses.isNotEmpty ? courses.first : null;

    return Scaffold(
      backgroundColor: TeacherDashboardScreen.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context),

              const SizedBox(height: 18),

              _buildGreetingCard(context),

              const SizedBox(height: 18),

              // =========================
              // ACTION BUTTONS
              _buildActionButtons(context, selectedCourse, quizzes),

              const SizedBox(height: 22),

              // =========================
              // COURSES
              // =========================
              _buildSectionTitle('Your Courses'),

              const SizedBox(height: 12),

              // LOADING
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )

              // EMPTY STATE
              else if (courses.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 40,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: TeacherDashboardScreen.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: TeacherDashboardScreen.border,
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        size: 54,
                        color: TeacherDashboardScreen.textSecondary,
                      ),
                      SizedBox(height: 14),
                      Text(
                        'No Courses Found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: TeacherDashboardScreen.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Create or join a course to continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: TeacherDashboardScreen.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )

              // COURSES LIST
              else
                Column(
                  children: courses.take(15).map((course) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCourseCard(
                        context,
                        iconBg: const Color(0xFFEFE7FF),
                        icon: Icons.auto_awesome,
                        iconColor: TeacherDashboardScreen.secondary,
                        title: course.title,
                        subtitle:
                            '${course.teacherName ?? ''} • ${course.creditHours ?? 0} Credit Hours',
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
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 24),

              // =========================
              // RECENT ACTIVITY
              // =========================
              _buildSectionTitle('Recent Activity'),

              const SizedBox(height: 12),

              _buildRecentActivityCard(context, quizzes),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildTopBar(BuildContext context) {
  final courseProvider = context.watch<CourseProvider>();
  final quizProvider = context.watch<QuizProvider>();

  final totalCourses = courseProvider.courses.length;

  final totalQuizzes = quizProvider.quizzes.length;

  return Row(
    children: [
      /// MENU
      InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TeacherProfileScreen(),
            ),
          );
        },
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(
            Icons.menu_rounded,
            size: 28,
            color: TeacherDashboardScreen.textPrimary,
          ),
        ),
      ),

      const SizedBox(width: 12),

      /// STATIC INFO CARD
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: TeacherDashboardScreen.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: TeacherDashboardScreen.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _topStatItem(
                icon: Icons.menu_book_rounded,
                title: "Courses",
                value: "$totalCourses",
              ),
              _verticalDivider(),
              _topStatItem(
                icon: Icons.quiz_rounded,
                title: "Quizzes",
                value: "$totalQuizzes",
              ),
              _verticalDivider(),
              _topStatItem(
                icon: Icons.school_rounded,
                title: "Role",
                value: "Teacher",
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget _topStatItem({
  required IconData icon,
  required String title,
  required String value,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        icon,
        size: 20,
        color: TeacherDashboardScreen.primary,
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: TeacherDashboardScreen.textPrimary,
        ),
      ),
      Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          color: TeacherDashboardScreen.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

Widget _verticalDivider() {
  return Container(
    height: 34,
    width: 1,
    color: TeacherDashboardScreen.border,
  );
}


Widget _buildGreetingCard(BuildContext context) {
  final authProvider = context.watch<AuthProvider>();

  final user = authProvider.user;

  final teacherName = user?.name ?? "Teacher";
  final teacherProfileImage = user?.profileImage;

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(
      18,
      18,
      18,
      18,
    ),
    decoration: BoxDecoration(
      color: TeacherDashboardScreen.surface,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
      border: Border.all(
        color: TeacherDashboardScreen.border,
      ),
    ),
    child: Row(
      children: [
        Expanded(
          child: user == null
              ? _greetingShimmer()
              : Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $teacherName 👋',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: TeacherDashboardScreen
                            .textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Manage your courses & quizzes easily',
                      style: TextStyle(
                        fontSize: 14.5,
                        color:
                            TeacherDashboardScreen
                                .textSecondary,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),

        const SizedBox(width: 12),

        /// PROFILE IMAGE
        user == null
            ? Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor:
                    Colors.grey.shade100,
                child: const CircleAvatar(
                  radius: 29,
                  backgroundColor:
                      Colors.white,
                ),
              )
            : CircleAvatar(
                radius: 29,
                backgroundColor:
                    const Color(0xFFEFE7FF),

                backgroundImage:
                    teacherProfileImage !=
                                null &&
                            teacherProfileImage
                                .isNotEmpty
                        ? NetworkImage(
                            teacherProfileImage,
                          )
                        : null,

                child:
                    teacherProfileImage ==
                                null ||
                            teacherProfileImage
                                .isEmpty
                        ? Text(
                            teacherName[0]
                                .toUpperCase(),
                            style:
                                const TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              color:
                                  TeacherDashboardScreen
                                      .primary,
                            ),
                          )
                        : null,
              ),
      ],
    ),
  );
}

Widget _greetingShimmer() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          height: 18,
          width: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 14,
          width: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(8),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildActionButtons(
  BuildContext context,
  CourseModel? course,
  List<Quiz> quizzes,
) {
  return Row(
    children: [
      Expanded(
        child: _gradientActionButton(
          context,
          icon: Icons.menu_book_rounded,
          title: 'Courses',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TeacherCoursesScreen(
                  courseId: course?.id ?? '',
                  quiz: quizzes,
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: _gradientActionButton(
          context,
          icon: Icons.edit_note_rounded,
          title: 'Quizzes',
          onTap: () {
            if (course == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No course available'),
                ),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TeacherQuizzesScreen(
                  courseId: course.id,
                  title: course.title,
                  quiz: quizzes,
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

  Widget _gradientActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              TeacherDashboardScreen.primary,
              TeacherDashboardScreen.secondary,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: TeacherDashboardScreen.primary.withValues(alpha: 0.20),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: TeacherDashboardScreen.textPrimary,
      ),
    );
  }

  Widget _buildCourseCard(
    BuildContext context, {
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: TeacherDashboardScreen.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: TeacherDashboardScreen.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: TeacherDashboardScreen.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color:
                            TeacherDashboardScreen.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color:
                            TeacherDashboardScreen.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: TeacherDashboardScreen.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }

 Widget _buildRecentActivityCard(
    BuildContext context,
    List quizzes,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: TeacherDashboardScreen.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TeacherDashboardScreen.border),
      ),
      child: quizzes.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Text("No recent quizzes"),
            )
          : Column(
              children: quizzes.take(10).map((quiz) {
                final isLast = quiz == quizzes.take(10).last;

                return Column(
                  children: [
                    _recentItem(
                      iconBg: const Color(0xFFF1EAFE),
                      icon: Icons.quiz_outlined,
                      iconColor: TeacherDashboardScreen.secondary,
                      title: quiz.title ?? 'Untitled Quiz',
                      time: quiz.createdAt?.toString() ?? 'Recently',
                      onTap: () {},
                    ),
                    if (!isLast) _divider(),
                  ],
                );
              }).toList(),
            ),
    );
  }

  // =========================
  // SINGLE ITEM (FIXED)
  // =========================
  Widget _recentItem({
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: TeacherDashboardScreen.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14),
      child: Divider(height: 1, thickness: 1),
    );
  }
}