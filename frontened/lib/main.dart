import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:frontened/Provider/auth_provider.dart';
import 'package:frontened/Provider/course_provider.dart';
import 'package:frontened/Provider/pdf_provider.dart';
import 'package:frontened/Provider/quiz_provider.dart';
import 'package:frontened/Provider/week_plan_provider.dart';

import 'package:frontened/screens/RoleSelectionScreen.dart';

// UNIFIED AUTH SCREENS
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

// 🔥 BACKGROUND NOTIFICATION HANDLER
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

// 🔥 NOTIFICATION CHANNELS INITIALIZATION
late AndroidNotificationChannel channel;
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

String initialAppRoute = RoleSelectionScreen.routeName;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  // Set background messaging handler safely
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Configure Local Notifications for Foreground Channels
  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  channel = const AndroidNotificationChannel(
    'smart_teacher_channel',
    'High Importance Notifications',
    description: 'This channel is used for academic alerts.',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Request Notification Permissions from Device
  await FirebaseMessaging.instance.requestPermission(
    alert: true, badge: true, sound: true,
  );

  // Print device token for backend registration
  String? fcmToken = await FirebaseMessaging.instance.getToken();
  debugPrint("Device FCM Token: $fcmToken");

  // Handle Foreground Messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (notification != null && android != null) {
      // 🔥 FIXED PERMANENTLY: Added explicit named parameters to resolve compiler restrictions
      flutterLocalNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  });

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