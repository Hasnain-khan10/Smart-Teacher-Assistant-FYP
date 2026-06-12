import 'package:flutter/material.dart';
import 'package:frontened/Provider/auth_provider.dart';
import 'package:frontened/main.dart';
import 'package:frontened/screens/Teacher/TeacherPlaceholderScreen.dart';
import 'package:frontened/services/storage_service.dart';
import 'package:frontened/utils/Auth_Widgets/AppLogo.dart';
import 'package:frontened/utils/Auth_Widgets/AuthScaffold.dart';
import 'package:frontened/utils/Auth_Widgets/AuthTextField.dart';
import 'package:provider/provider.dart';

class TeacherSignUpScreen extends StatefulWidget {
  static const String teacherRouteName = '/signup-teacher';

  const TeacherSignUpScreen({super.key});

  @override
  State<TeacherSignUpScreen> createState() => _TeacherSignUpScreenState();
}

class _TeacherSignUpScreenState extends State<TeacherSignUpScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cnicController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _qualificationController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _specialityController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              const AppLogo(width: 175),

              const SizedBox(height: 10),

              const Text(
                "SignUp",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 5),

              const Text(
                "Join Smart Teacher Assistance",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),

              const SizedBox(height: 15),

              /// ================= COLUMN ONLY (TOP TO BOTTOM) =================
              AuthTextField(
                hintText: "Teacher Name",
                icon: Icons.person,
                controller: _nameController,
              ),

              const SizedBox(height: 10),

              AuthTextField(
                hintText: "Father Name",
                icon: Icons.person_outline,
                controller: _fatherNameController,
              ),

              const SizedBox(height: 10),

              AuthTextField(
                hintText: "Email",
                icon: Icons.email,
                controller: _emailController,
              ),

              const SizedBox(height: 10),

              AuthTextField(
                hintText: "CNIC",
                icon: Icons.credit_card,
                controller: _cnicController,
              ),

              const SizedBox(height: 10),

              AuthTextField(
                hintText: "Department",
                icon: Icons.apartment,
                controller: _departmentController,
              ),

              const SizedBox(height: 10),

              AuthTextField(
                hintText: "Qualification",
                icon: Icons.school,
                controller: _qualificationController,
              ),

              const SizedBox(height: 10),

              AuthTextField(
                hintText: "Experience",
                icon: Icons.work,
                controller: _experienceController,
              ),

              const SizedBox(height: 10),

              AuthTextField(
                hintText: "Speciality",
                icon: Icons.star,
                controller: _specialityController,
              ),

              const SizedBox(height: 10),

              AuthTextField(
                hintText: "Password",
                icon: Icons.lock,
                isPassword: true,
                obscureText: _obscurePassword,
                controller: _passwordController,
                onToggle: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),

              const SizedBox(height: 10),

              AuthTextField(
                hintText: "Confirm Password",
                icon: Icons.lock_outline,
                isPassword: true,
                obscureText: _obscureConfirmPassword,
                controller: _confirmPasswordController,
                onToggle: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),

              const SizedBox(height: 18),

              /// ================= SIGNUP BUTTON =================
              GestureDetector(
                onTap: authProvider.isLoading || _loading
                    ? null
                    : () async {
                        String name = _nameController.text.trim();
                        String fatherName = _fatherNameController.text.trim();
                        String email = _emailController.text.trim();
                        String cnic = _cnicController.text.trim();
                        String department = _departmentController.text.trim();
                        String qualification = _qualificationController.text.trim();
                        String experience = _experienceController.text.trim();
                        String speciality = _specialityController.text.trim();

                        String password = _passwordController.text.trim();
                        String confirm = _confirmPasswordController.text.trim();

                        if ([name, fatherName, email, cnic, department, qualification, experience, speciality]
                            .any((e) => e.isEmpty)) {
                          _showError("Please fill all fields");
                          return;
                        }

                        if (!email.endsWith("@gmail.com")) {
                          _showError("Valid Gmail required");
                          return;
                        }

                        if (password.length < 6) {
                          _showError("Password must be 6+ chars");
                          return;
                        }

                        if (password != confirm) {
                          _showError("Passwords do not match");
                          return;
                        }

                        String? role = await StorageService.getRole();
                        if (role != "teacher") {
                          _showError("Invalid role selected");
                          return;
                        }

                        setState(() => _loading = true);

                         await Future.delayed(const Duration(seconds: 5));

                        bool success = await authProvider.signup(
                          name: name,
                          email: email,
                          password: password,
                          role: role!,
                          fatherName: fatherName,
                          cnic: cnic,
                          department: department,
                          qualification: qualification,
                          experience: experience,
                          speciality: speciality,
                        );

                        setState(() => _loading = false);

                        if (!success) {
                          _showError(authProvider.error ?? "Signup failed");
                          return;
                        }

                        _navigate();
                      },

                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                  ),
                  child: Center(
                    child: (_loading || authProvider.isLoading)
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ) : const Text(
                            "SignUp",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 25),
               Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                )
            ],
          );
        },
      ),
    );
  }

  void _navigate() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      TeacherDashboardScreen.teacherRouteName,
      (route) => false,
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
      ),
    );
  }
}