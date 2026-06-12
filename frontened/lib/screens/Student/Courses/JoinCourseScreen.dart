import 'package:flutter/material.dart';
import 'package:frontened/Provider/course_provider.dart';
import 'package:provider/provider.dart';


class JoinCourseScreen extends StatefulWidget {
  const JoinCourseScreen({super.key});

  static const String routeName = '/join-course';

  @override
  State<JoinCourseScreen> createState() => _JoinCourseScreenState();
}


class _JoinCourseScreenState extends State<JoinCourseScreen> {
  final TextEditingController _inviteController = TextEditingController();

  Future<void> _joinCourse() async {
  String input = _inviteController.text.trim();

  if (input.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please enter invite code")),
    );
    return;
  }

  //  FIX: extract code from full link if needed
  String code = input.split("/").last;

  final provider = Provider.of<CourseProvider>(context, listen: false);

  final success = await provider.joinCourse(code);

  if (!mounted) return;

  if (success) {
    _inviteController.clear();
    await provider.fetchCourses();

    ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: const Text(
      "Course joined successfully 🎉",
      style: TextStyle(color: Colors.white),
    ),
    backgroundColor: Colors.green,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.error ?? "Invalid join code"),
      backgroundColor: Colors.red,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
      ),
    );
  }
}

  @override
  void dispose() {
    _inviteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CourseProvider>(
      builder: (context, provider, child) {
        final courses = provider.courses.toList();
        courses.sort((a, b) => b.id.compareTo(a.id));

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "Join Course",
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
                const SizedBox(height: 20),

                /// Title
                const Text(
                  "Enter Invite Code",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 10),

                /// Input Field
                TextField(
                  controller: _inviteController,
                  decoration: InputDecoration(
                    hintText: "Paste course invite link/code",
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// Join Button (WITH LOADING)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: provider.isJoining ? null : _joinCourse,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: provider.isJoining
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Join Course",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 30),

                /// Courses Title
                const Text(
                  "Your Courses",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 12),

                /// Course List
                Expanded(
  child: provider.isLoading
      ? const Center(child: CircularProgressIndicator())
      : provider.courses.isEmpty
          ? const Center(
              child: Text(
                "No courses joined yet",
                style: TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          : ListView.builder(
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];

                return CourseItem(title: course.title);
              },
            ),
)
              ],
            ),
          ),
        );
      },
    );
  }
}

class CourseItem extends StatelessWidget {
  final String title;

  const CourseItem({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: AppColors.success,
          )
        ],
      ),
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
  static const Color success = Color(0xFF22C55E);
}