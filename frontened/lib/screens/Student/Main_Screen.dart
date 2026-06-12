import 'package:flutter/material.dart';
import 'package:frontened/screens/Student/Profile/ProfileScreen.dart';
import 'package:frontened/screens/Student/student_home_screen.dart';

import 'Courses/CoursesScreen.dart';
import 'Quizzes/QuizzesScreen.dart';

// COLORS
const Color kPrimary = Color(0xFF4F46E5);
const Color kNavInactive = Color(0xFF938DB2);

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
    QuizzesScreen(),
    StudentProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          screens[currentIndex],

          /// Bottom Nav Positioned
          Align(
            alignment: Alignment.bottomCenter,
            child: _BottomNavBar(
              currentIndex: currentIndex,
              onTap: (index) {
                setState(() => currentIndex = index);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'Home'),
      (Icons.menu_book_outlined, 'Courses'),
      (Icons.check_box_outlined, 'Quizzes'),
      (Icons.person_outline_rounded, 'Profile'),
    ];

    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFEAEAEA),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final active = index == currentIndex;

          return Expanded(
            child: InkWell(
              onTap: () => onTap(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    items[index].$1,
                    size: 24,
                    color: active ? kPrimary : kNavInactive,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[index].$2,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight:
                          active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? kPrimary : kNavInactive,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

