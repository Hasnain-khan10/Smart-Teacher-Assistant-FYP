import 'package:flutter/material.dart';
import 'package:frontened/screens/Student/Courses/CoursesScreen.dart';
import 'package:frontened/screens/Student/Profile/ProfileScreen.dart';
import 'package:frontened/screens/Student/Quizzes/QuizzesScreen.dart';
import 'package:frontened/screens/Student/student_home_screen.dart';

class MainScreen extends StatefulWidget {
  static const String routeName = '/student-placeholder';
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  final List<Widget> screens = const [
    StudentHomeScreen(),
    CoursesScreen(),
    SizedBox.shrink(), // Dummy placeholder for Assignments
    StudentProfileScreen(),
  ];

  // 🔥 Future Work / Coming Soon Dialog Popup Function
  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_clock_rounded, color: Color(0xFF4F46E5)),
            SizedBox(width: 10),
            Text("Future Work", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📚 Smart Assignment Manager", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
            SizedBox(height: 6),
            Text("This feature is currently under development. In the next release, students can upload and evaluate handwritten assignments directly via AI scanning.", style: TextStyle(color: Colors.grey, fontSize: 13)),
            SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text("Coming Soon...", style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Got it!", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
            child: BottomNavigationBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              currentIndex: currentIndex,
              // 🔥 Yahan Check Lagaya Hai: Agar Index 2 (Assignments) ho to Screen change nahi hogi, Popup aayega!
              onTap: (index) {
                if (index == 2) {
                  _showComingSoonDialog(context);
                } else {
                  setState(() => currentIndex = index);
                }
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF4F46E5),
              unselectedItemColor: Colors.grey.shade400,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_rounded), activeIcon: Icon(Icons.home_rounded, size: 28), label: 'Home'),
                // 🔥 Icon aur Text Update kar diya
                BottomNavigationBarItem(icon: Icon(Icons.auto_stories_rounded), activeIcon: Icon(Icons.auto_stories_rounded, size: 28), label: 'Class & Quizzes'),
                // 🔥 Quizzes ko Assignments bana diya
                BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in_rounded), activeIcon: Icon(Icons.assignment_turned_in_rounded, size: 28), label: 'Assignments'),
                BottomNavigationBarItem(icon: Icon(Icons.person_rounded), activeIcon: Icon(Icons.person_rounded, size: 28), label: 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}