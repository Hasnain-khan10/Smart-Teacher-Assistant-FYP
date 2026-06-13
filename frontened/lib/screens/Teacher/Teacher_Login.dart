import 'package:flutter/material.dart';
import 'package:frontened/Provider/auth_provider.dart';
import 'package:frontened/main.dart';
import 'package:frontened/screens/Teacher/TeacherPlaceholderScreen.dart';
import 'package:frontened/screens/Teacher/Teacher_SignUp.dart';
import 'package:frontened/services/storage_service.dart';
import 'package:frontened/utils/Auth_Widgets/AppLogo.dart';
import 'package:frontened/utils/Auth_Widgets/AuthScaffold.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

class TeacherLoginScreen extends StatefulWidget {
  static const String teacherRouteName = '/login-teacher';
  const TeacherLoginScreen({super.key});

  @override
  State<TeacherLoginScreen> createState() => _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends State<TeacherLoginScreen> {
  bool _obscurePassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loginLoading = false;
  bool _googleLoading = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: '98935133919-cejkg00o20ctilr0qrjg8po33j8l2gjj.apps.googleusercontent.com',
  );

  String? validateEmail(String value) =>
      value.isEmpty ? "Email is required" : null;

  String? validatePassword(String value) =>
      value.isEmpty ? "Password is required" : null;

  /// ================= LOGIN =================
  Future<void> _handleLogin(AuthProvider authProvider) async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    final emailError = validateEmail(email);
    if (emailError != null) return _showError(emailError);

    final passError = validatePassword(password);
    if (passError != null) return _showError(passError);

    final role = await StorageService.getRole();
    if (role == null || role.isEmpty) {
      return _showError("Please select role first");
    }

    setState(() => _loginLoading = true);

    bool success = await authProvider.login(email, password, role);

    setState(() => _loginLoading = false);

    if (!success) {
      return _showError(authProvider.error ?? "Login failed");
    }

    _navigate(authProvider);
  }

  /// ================= GOOGLE LOGIN =================
  Future<void> _handleGoogleSignIn(AuthProvider authProvider) async {
    try {
      setState(() => _googleLoading = true);

      final role = await StorageService.getRole();
      if (role == null || role.isEmpty) {
        setState(() => _googleLoading = false);
        return _showError("Please select role first");
      }

      final account = await _googleSignIn.signIn();
      if (account == null) {
        setState(() => _googleLoading = false);
        return;
      }

      final auth = await account.authentication;

      if (auth.idToken == null) {
        setState(() => _googleLoading = false);
        return _showError("Google token missing");
      }

      bool success = await authProvider.googleLogin(auth.idToken!, role);

      setState(() => _googleLoading = false);

      if (!success) {
        return _showError(authProvider.error ?? "Google login failed");
      }

      _navigate(authProvider);
    } catch (e) {
      setState(() => _googleLoading = false);
      _showError(e.toString());
    }
  }

  /// ================= NAVIGATION =================
  void _navigate(AuthProvider authProvider) {
    final user = authProvider.user;

    if (user == null) {
      return _showError("User not found");
    }

    Navigator.pushReplacementNamed(
        context, TeacherDashboardScreen.teacherRouteName);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showForgotPasswordSheet() {
    final emailController = TextEditingController();
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();

    int step = 1;
    bool isPasswordVisible = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return Container(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 28,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          step == 1
                              ? "Forgot Password"
                              : step == 2
                              ? "Verify OTP"
                              : "Reset Password",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        /// STEP 1
                        if (step == 1)
                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              labelText: "Email Address",
                              labelStyle: const TextStyle(color: Colors.black54),
                              prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),

                        /// STEP 2
                        if (step == 2)
                          TextField(
                            controller: otpController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              labelText: "Enter 6-Digit OTP",
                              labelStyle: const TextStyle(color: Colors.black54),
                              prefixIcon: const Icon(Icons.pin_outlined, color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),

                        /// STEP 3
                        if (step == 3)
                          TextField(
                            controller: newPasswordController,
                            obscureText: !isPasswordVisible,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              labelText: "New Password",
                              labelStyle: const TextStyle(color: Colors.black54),
                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setModalState(() {
                                    isPasswordVisible = !isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),

                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: authProvider.isLoading
                                ? null
                                : () async {
                              if (step == 1) {
                                bool success = await authProvider
                                    .forgotPassword(emailController.text.trim());
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("OTP sent successfully")),
                                  );
                                  setModalState(() => step = 2);
                                }
                              } else if (step == 2) {
                                bool success = await authProvider.verifyOTP(
                                  email: emailController.text.trim(),
                                  otp: otpController.text.trim(),
                                );
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("OTP verified")),
                                  );
                                  setModalState(() => step = 3);
                                }
                              } else {
                                bool success = await authProvider.resetPassword(
                                  email: emailController.text.trim(),
                                  newPassword: newPasswordController.text.trim(),
                                );
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Password reset successfully")),
                                  );
                                  Navigator.pop(context);
                                }
                              }

                              if (!authProvider.isLoading && authProvider.error != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(authProvider.error!),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: authProvider.isLoading
                                ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                                : Text(
                              step == 1
                                  ? "Send OTP"
                                  : step == 2
                                  ? "Verify OTP"
                                  : "Reset Password",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 14),
              const AppLogo(width: 175),
              const SizedBox(height: 14),
              const Text(
                'Smart Teacher Assistant',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your AI Teaching Assistant',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),

              /// 🔥 EMAIL INPUT DECORATION FIXED WITH CONTRAST & BORDERS
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    hintStyle: const TextStyle(color: Colors.black45),
                    prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              /// 🔥 PASSWORD INPUT DECORATION FIXED WITH CONTRAST & BORDERS
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: const TextStyle(color: Colors.black45),
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _showForgotPasswordSheet,
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              /// LOGIN BUTTON
              GestureDetector(
                onTap: _loginLoading ? null : () => _handleLogin(authProvider),
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Center(
                    child: _loginLoading
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                        : const Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: AppColors.primary,
          fontSize: 18,),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, TeacherSignUpScreen.teacherRouteName);
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "OR",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                ],
              ),
              const SizedBox(height: 24),

              /// GOOGLE LOGIN BUTTON
              GestureDetector(
                onTap: _googleLoading ? null : () => _handleGoogleSignIn(authProvider),
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Center(
                    child: _googleLoading
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/google.jpg',
                          height: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Sign in with Google",
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}