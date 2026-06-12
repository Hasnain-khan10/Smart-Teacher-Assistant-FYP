import 'package:flutter/material.dart';
import 'package:frontened/Provider/auth_provider.dart';
import 'package:frontened/Provider/course_provider.dart';
import 'package:frontened/Provider/quiz_provider.dart';
import 'package:provider/provider.dart';


class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  static const String routeName = '/student-home';

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {

   @override
  void initState() {
    super.initState();

     Future.microtask(() {
    context.read<QuizProvider>().fetchAllQuizzes();
    context.read<CourseProvider>().fetchCourses(); 
  });

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

   bool _isCompletedSafe(dynamic quiz) {
    return quiz.isCompleted == true;
  }


  @override
  Widget build(BuildContext context) {
    final quizProvider = context.watch<QuizProvider>();

    final authProvider = context.watch<AuthProvider>();
    final students = authProvider.user;

    final courseProvider = context.watch<CourseProvider>();
    final courses = courseProvider.courses;

    final quizzes = quizProvider.quizzes;

    final upcomingQuizzes =
        quizzes.where((q) => !_isCompletedSafe(q)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const StudentBottomNavBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              /// Header
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    /// NAME + GREETING
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Hello ${students?.name ?? "Student"} 👋",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Ready to learn something new today?",
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    ),

    /// PROFILE IMAGE
    CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      backgroundImage: (students?.profileImage != null &&
              students!.profileImage!.isNotEmpty)
          ? NetworkImage(students.profileImage!)
          : null,
      child: (students?.profileImage == null ||
              students!.profileImage!.isEmpty)
          ? const Icon(Icons.person, color: AppColors.primary)
          : null,
    ),
  ],
),
              const SizedBox(height: 20),

              /// Join Course Button
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/join-course');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      "Join New Course",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// ================= CURRENT COURSES =================
const Text(
  "Current Courses",
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  ),
),

const SizedBox(height: 12),

/// Loading
if (courseProvider.isLoading)
  const Center(
    child: Padding(
      padding: EdgeInsets.all(20),
      child: CircularProgressIndicator(),
    ),
  )

/// Error
else if (courseProvider.error != null)
  Center(
    child: Text(
      courseProvider.error!,
      style: const TextStyle(color: Colors.red),
    ),
  )

/// Empty
else if (courses.isEmpty)
  const Text(
    "No courses found",
    style: TextStyle(color: AppColors.textSecondary),
  )

/// Course List
else
  ...courses.take(15).map(
    (course) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CourseCard(
        title: course.title,
        progress: course.progress ?? 0.0, // if not available use 0
      ),
    ),
  ),

              const SizedBox(height: 24),

               /// ================= UPCOMING QUIZZES =================
              const Text(
                "Upcoming Quizzes",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              /// Loading
              if (quizProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )

              /// Error
              else if (quizProvider.error != null)
                Center(
                  child: Text(
                    quizProvider.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )

              /// Empty
              else if (upcomingQuizzes.isEmpty)
                const Text(
                  "No upcoming quizzes",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                  ),
                )

              /// Quiz List
              else
                ...upcomingQuizzes.take(5).map(
                  (quiz) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: 12),

                    child: QuizCard(
                      title: quiz.title ?? "Untitled Quiz",

                      date: quiz.createdAt != null
                          ? "${quiz.createdAt!.day}/${quiz.createdAt!.month}/${quiz.createdAt!.year}"
                          : "Upcoming",

                      // onTap: () {
                      //   Navigator.pushNamed(
                      //     context,
                      //     '/quiz-attempt',
                      //     arguments: quiz,
                      //   );
                      // },
                    ),
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  final String title;
  final double progress;

  const CourseCard({
    super.key,
    required this.title,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            color: AppColors.primary,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }
}

class QuizCard extends StatelessWidget {
  final String title;
  final String date;

  const QuizCard({
    super.key,
    required this.title,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                date,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StudentBottomNavBar extends StatefulWidget {
  const StudentBottomNavBar({super.key});

  @override
  State<StudentBottomNavBar> createState() => _StudentBottomNavBarState();
}

class _StudentBottomNavBarState extends State<StudentBottomNavBar> {
  int selectedIndex = 0;

  void onTap(int index) {
    setState(() {
      selectedIndex = index;
    });

    if (index == 1) {
      Navigator.pushNamed(context, '/courses');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/quizzes');
    } else if (index == 3) {
      Navigator.pushNamed(context, '/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onTap,
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

class AppColors {
  static const Color primary = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF7C3AED);
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1E1B4B);
  static const Color textSecondary = Color(0xFF6B7280);
}