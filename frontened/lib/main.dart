
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:frontened/Provider/auth_provider.dart';
import 'package:frontened/Provider/course_provider.dart';
import 'package:frontened/Provider/pdf_provider.dart';
import 'package:frontened/Provider/quiz_provider.dart';
import 'package:frontened/Provider/week_plan_provider.dart';
import 'package:frontened/firebase_options.dart';
import 'package:frontened/screens/RoleSelectionScreen.dart';
import 'package:frontened/screens/SplashScreen.dart';
import 'package:frontened/screens/Student/Authentication/ForgotPasswordScreen.dart';
import 'package:frontened/screens/Student/Authentication/LoginScreen.dart';
import 'package:frontened/screens/Student/Authentication/SignUpScreen.dart';
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
import 'package:frontened/screens/Teacher/Courses/Ai%20plain%20progress%20popup.dart';
import 'package:frontened/screens/Teacher/Courses/CourseDetailScreen.dart';
import 'package:frontened/screens/Teacher/Courses/CourseMainScreen.dart';
import 'package:frontened/screens/Teacher/Courses/CoursesScreen.dart';
import 'package:frontened/screens/Teacher/Courses/CreatecourseScreen.dart';
import 'package:frontened/screens/Teacher/Courses/GenerateAIPlanScreen.dart';
import 'package:frontened/screens/Teacher/Courses/Student%20show%20screen.dart';
import 'package:frontened/screens/Teacher/Quiz/AI%20check%20popup%20screen.dart';
import 'package:frontened/screens/Teacher/Quiz/AiQuestionQuizScreen.dart';
import 'package:frontened/screens/Teacher/Quiz/AiQuizGeneratePopUpScreen.dart';
import 'package:frontened/screens/Teacher/Quiz/CreateQuizScreen.dart';
import 'package:frontened/screens/Teacher/Quiz/QuizResultScreen.dart';
import 'package:frontened/screens/Teacher/Quiz/QuizzesScreen.dart';
import 'package:frontened/screens/Teacher/Quiz/Scan%20quiz%20screen.dart';
import 'package:frontened/screens/Teacher/Quiz/TeacherManuallyQuizScreen.dart';
import 'package:frontened/screens/Teacher/TeacherPlaceholderScreen.dart';
import 'package:frontened/screens/Teacher/Teacher_Forget_Screen.dart';
import 'package:frontened/screens/Teacher/Teacher_Login.dart';
import 'package:frontened/screens/Teacher/Teacher_ProfileScreen.dart';
import 'package:frontened/screens/Teacher/Teacher_SignUp.dart';
import 'package:frontened/utils/Auth_Widgets/Colors.dart';
import 'package:provider/provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pehle check karein ke kya Firebase pehle se initialize to nahi hai
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  runApp(const SmartTeacherAssistantApp());}

class SmartTeacherAssistantApp extends StatelessWidget {
  // final String? token;
  // final String? role;

  const SmartTeacherAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),

        ChangeNotifierProvider<CourseProvider>(
          create: (_) => CourseProvider(),
        ),

        ChangeNotifierProvider<WeekPlanProvider>(
          create: (_) => WeekPlanProvider(),
        ),

        ChangeNotifierProvider<PdfProvider>(
          create: (_) => PdfProvider(),
        ),

        // ✅ ADD THIS
        ChangeNotifierProvider<QuizProvider>(
          create: (_) => QuizProvider(),
        ),
      ],

      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Smart Teacher Assistant',
        theme: AppTheme.theme,

        // Pass token to Splash
        initialRoute: SplashScreen.routeName,

        routes: {
          SplashScreen.routeName: (_) => SplashScreen(),
          StudentLoginScreen.routeName: (_) => const StudentLoginScreen(),
          SignUpScreen.routeName: (_) => const SignUpScreen(),
          ForgotPasswordScreen.routeName: (_) => const ForgotPasswordScreen(),
          TeacherLoginScreen.teacherRouteName: (_) => const TeacherLoginScreen(),
          TeacherSignUpScreen.teacherRouteName: (_) => const TeacherSignUpScreen(),
          TeacherForgetScreen.teacherRouteName: (_) => const TeacherForgetScreen(),
          RoleSelectionScreen.routeName: (_) => const RoleSelectionScreen(),
          // GoogleRoleSelectionScreen.routeName: (_) => const GoogleRoleSelectionScreen(),
          TeacherDashboardScreen.teacherRouteName: (_) =>
          const TeacherDashboardScreen(),
          MainScreen.routeName: (_) =>
          const MainScreen(),


          /// Student Dashboard Routes
          '/student-home': (context) => StudentHomeScreen(),
          '/join-course': (context) => JoinCourseScreen(),
          '/courses': (context) => CoursesScreen(),
          '/course-detail': (context) => CourseDetailScreen(),
          '/quizzes': (context) => QuizzesScreen(),
          '/quiz-attempt': (context) => QuizAttemptScreen(),
          '/quiz-result': (context) => QuizResultScreen(),
          '/quiz-tips': (context) => QuizTipsScreen(),
          '/profile': (context) => StudentProfileScreen(),



          /// Teacher Dashboard Routes
          /// ================= COURSES =================
          '/teacher-courses': (context) => const TeacherCoursesScreen(courseId: '', quiz: [],),
          '/teacher-createCourse': (context) => const TeacherCreateCourseScreen(quiz: [],),
          '/teacher-courseDetail': (context) => const TeacherCourseDetailScreen(courseId: '', quiz: [],),
          '/teacher-courseMain': (context) => const TeacherCourseMainScreen(courseId: '',),

          /// ================= AI PLAN =================
          '/teacher-generateAIPlan': (context) => const TeacherGenerateAIPlanScreen(courseId: '',),
          '/teacher-aiPlanLoading': (context) => const TeacherAIPlanLoadingScreen(),   // popup but route added

          /// ================= STUDENTS =================
          '/students': (context) => const StudentsScreen(courseId: '', quiz: [],),

          /// ================= SCAN QUIZ =================
          '/teacher-scanQuiz': (context) => const TeacherScanQuizScreen(),
          '/quizProcessing': (context) => const TeacherQuizUploadProcessingScreen(),

          /// ================= QUIZZES =================
          '/teacher-quizzes': (context) => const TeacherQuizzesScreen(courseId: '', title: '', quiz: []),
          '/teacher-createQuiz': (context) => const TeacherCreateQuizScreen(courseId: '', courseTitle: '',),
          '/teacher-questionBuilder': (context) => const TeacherManuallyQuizScreen(courseId: '', quizTitle: '',),
          '/teacher-aiQuiz': (context) => const TeacherAIQuestionQuizScreen(quizTitle: '', courseId: '',),
          '/teacher-aiQuizLoading': (context) => const TeacherAIQuizLoadingScreen(),

          /// ================= RESULTS =================
          '/teacher-quizResults': (context) => const TeacherQuizResultsScreen(quizId: '',),

          /// ================= PROFILE =================
          '/teacher-teacherProfile': (context) => const TeacherProfileScreen(),
        },
      ),
    );
  }
}



class AppColors {
  static const Color primary = Color(0xFF4F46E5); // Indigo
  static const Color secondary = Color(0xFF7C3AED); // Purple
  static const Color background = Color(0xFFFFFFFF); // Soft Off-White
  static const Color surface = Color(0xFFFFFFFF); // White

  static const Color textPrimary = Color(0xFF1E1B4B);
  static const Color textSecondary = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  static const Color border = Color(0xFFFFFFFF);
  static const Color shadow = Color(0x14000000);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, secondary],
  );
}
