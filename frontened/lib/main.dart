import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:frontened/Provider/auth_provider.dart';
import 'package:frontened/Provider/course_provider.dart';
import 'package:frontened/Provider/pdf_provider.dart';
import 'package:frontened/Provider/quiz_provider.dart';
import 'package:frontened/Provider/week_plan_provider.dart';
import 'package:frontened/firebase_options.dart';

import 'package:frontened/screens/RoleSelectionScreen.dart';

// 🔥 UNIFIED AUTH SCREENS
import 'package:frontened/screens/Teacher/TeacherAuthScreen.dart';
import 'package:frontened/screens/Student/Authentication/StudentAuthScreen.dart';

// STUDENT SCREENS
import 'package:frontened/screens/Student/Courses/Course_detail_screen.dart';
import 'package:frontened/screens/Student/Courses/CoursesScreen.dart';
import 'package:frontened/screens/Student/Courses/JoinCourseScreen.dart';
import 'package:frontened/screens/Student/Main_Screen.dart';
import 'package:frontened/screens/Student/Profile/ProfileScreen.dart';
import 'package:frontened/screens/Student/Quizzes/QuizAttemptScreen.dart';
import 'package:frontened/screens/Student/Quizzes/QuizResultScreen.dart';
import 'package:frontened/screens/Student/Quizzes/QuizzesScreen.dart';
import 'package:frontened/screens/Student/Quizzes/quiz_tips_screen.dart';
import 'package:frontened/screens/Student/student_home_screen.dart';

// TEACHER SCREENS
import 'package:frontened/screens/Teacher/TeacherPlaceholderScreen.dart';
import 'package:frontened/services/storage_service.dart';
import 'package:provider/provider.dart';

String initialAppRoute = RoleSelectionScreen.routeName;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  bool expired = await StorageService.isSessionExpired();
  if (expired) {
    await StorageService.removeToken();
  }

  final token = await StorageService.getToken();
  final role = await StorageService.getRole();

  if (token != null && token.isNotEmpty) {
    if (role?.toLowerCase() == "student") {
      initialAppRoute = MainScreen.routeName;
    } else if (role?.toLowerCase() == "teacher") {
      initialAppRoute = TeacherDashboardScreen.teacherRouteName;
    }
  } else if (role != null && role.isNotEmpty) {
    if (role.toLowerCase() == "student") {
      // 🔥 POINTING TO THE NEW STUDENT AUTH SCREEN
      initialAppRoute = StudentAuthScreen.routeName;
    } else if (role.toLowerCase() == "teacher") {
      initialAppRoute = TeacherAuthScreen.routeName;
    }
  } else {
    initialAppRoute = RoleSelectionScreen.routeName;
  }

  runApp(const SmartTeacherAssistantApp());
}

class SmartTeacherAssistantApp extends StatelessWidget {
  const SmartTeacherAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<CourseProvider>(create: (_) => CourseProvider()),
        ChangeNotifierProvider<WeekPlanProvider>(create: (_) => WeekPlanProvider()),
        ChangeNotifierProvider<PdfProvider>(create: (_) => PdfProvider()),
        ChangeNotifierProvider<QuizProvider>(create: (_) => QuizProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Smart Teacher Assistant',
        theme: AppTheme.theme,
        initialRoute: initialAppRoute,
        routes: {
          RoleSelectionScreen.routeName: (_) => const RoleSelectionScreen(),

          // 🔥 NEW UNIFIED AUTH SCREENS
          TeacherAuthScreen.routeName: (_) => const TeacherAuthScreen(),
          StudentAuthScreen.routeName: (_) => const StudentAuthScreen(),

          // Dashboards
          MainScreen.routeName: (_) => const MainScreen(),
          TeacherDashboardScreen.teacherRouteName: (_) => const TeacherDashboardScreen(),

          // Student Dashboard Routes
          '/student-home': (_) => const StudentHomeScreen(),
          '/join-course': (_) => const JoinCourseScreen(),
          '/courses': (_) => const CoursesScreen(),
          '/course-detail': (_) => const CourseDetailScreen(),
          '/quizzes': (_) => const QuizzesScreen(),
          '/quiz-attempt': (_) => const QuizAttemptScreen(),
          '/quiz-result': (_) => const QuizResultScreen(),
          '/quiz-tips': (_) => const QuizTipsScreen(),
          '/profile': (_) => const StudentProfileScreen(),
        },
      ),
    );
  }
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
  );
}

class AppColors {
  static const Color primary = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF7C3AED);
  static const Color background = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E1B4B);
  static const Color textSecondary = Color(0xFF6B7280);
}