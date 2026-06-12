import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:async';

import 'package:frontened/main.dart';
import 'package:frontened/screens/RoleSelectionScreen.dart';
import 'package:frontened/screens/Student/Authentication/LoginScreen.dart';
import 'package:frontened/screens/Student/Main_Screen.dart';
import 'package:frontened/screens/Teacher/TeacherPlaceholderScreen.dart';
import 'package:frontened/screens/Teacher/Teacher_Login.dart';
import 'package:frontened/services/storage_service.dart';
import 'package:frontened/utils/Auth_Widgets/AppLogo.dart';
import 'package:frontened/utils/Auth_Widgets/AuthScaffold.dart';

/// ------------------------------------------------------------
///  SPLASH
/// ------------------------------------------------------------

class SplashScreen extends StatefulWidget {
  static const String routeName = '/';
  static const String teaherRouteName = '/';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(seconds: 5));

    final token = await StorageService.getToken();
    final role = await StorageService.getRole();

    if (!mounted) return;

    // =============================
    // 🔥 USER IS LOGGED IN
    // =============================
    if (token != null && token.isNotEmpty) {
      if (role == "student") {
        Navigator.pushReplacementNamed(context, MainScreen.routeName);
      }
      else if (role == "teacher") {
        Navigator.pushReplacementNamed(
          context,
          TeacherDashboardScreen.teacherRouteName,
        );
      }
      else {
        Navigator.pushReplacementNamed(context, RoleSelectionScreen.routeName);
      }
      return;
    }

    // =============================
    // 🔥 USER IS NOT LOGGED IN
    // =============================
    if (role == "student") {
      Navigator.pushReplacementNamed(context, StudentLoginScreen.routeName);
    }
    else if (role == "teacher") {
      Navigator.pushReplacementNamed(context, TeacherLoginScreen.teacherRouteName);
    }
    else {
      Navigator.pushReplacementNamed(context, RoleSelectionScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Spacer(flex: 2),
          AppLogo(width: 180),
          SizedBox(height: 24),
          Text(
            'Smart Teacher\nAssistant',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              height: 1.16,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'AI-Powered Academic Assistant',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(flex: 3),

          // 🔥 LIVE BOUNCING DOTS ANIMATION 🔥
          SpinKitThreeBounce(
            color: Color(0xFFFFFFFF),
            size: 25.0,
          ),

          SizedBox(height: 48),
        ],
      ),
    );
  }
}