import 'package:flutter/material.dart';
import 'package:frontened/Provider/auth_provider.dart';
import 'package:frontened/main.dart';
import 'package:frontened/screens/Student/Main_Screen.dart';
import 'package:frontened/services/storage_service.dart';
import 'package:frontened/utils/Auth_Widgets/AppLogo.dart';
import 'package:frontened/utils/Auth_Widgets/AuthScaffold.dart';
import 'package:frontened/utils/Auth_Widgets/AuthTextField.dart';
import 'package:provider/provider.dart';

class SignUpScreen extends StatefulWidget {
  static const String routeName = '/signup';

  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;

  final _nameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _departmentController = TextEditingController();
  final _cnicController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? selectedSemester;
  String? selectedSection;

  final List<String> semesters =
  List.generate(8, (index) => "Semester ${index + 1}");

  final List<String> sections = ["A", "B", "C"];

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              const AppLogo(width: 160),
              const SizedBox(height: 12),
              const Text(
                "Create Account",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Join Smart Student Assistance Portal",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              AuthTextField(
                hintText: "Student Full Name",
                icon: Icons.person_outline,
                controller: _nameController,
              ),
              const SizedBox(height: 12),

              AuthTextField(
                hintText: "Father Name",
                icon: Icons.assignment_ind_outlined,
                controller: _fatherNameController,
              ),
              const SizedBox(height: 12),

              AuthTextField(
                hintText: "Email Address",
                icon: Icons.email_outlined,
                controller: _emailController,
              ),
              const SizedBox(height: 12),

              AuthTextField(
                hintText: "Roll Number",
                icon: Icons.badge_outlined,
                controller: _rollNumberController,
              ),
              const SizedBox(height: 12),

              // ================= PREMIUM DROPDOWNS ROW =================
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 58,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200, width: 1.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedSemester,
                          hint: Row(
                            children: const [
                              Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey),
                              SizedBox(width: 10),
                              Text("Semester", style: TextStyle(color: Colors.grey, fontSize: 15)),
                            ],
                          ),
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                          items: semesters.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: const TextStyle(color: AppColors.textPrimary)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSemester = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 58,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200, width: 1.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedSection,
                          hint: Row(
                            children: const [
                              Icon(Icons.layers_outlined, size: 20, color: Colors.grey),
                              SizedBox(width: 10),
                              Text("Section", style: TextStyle(color: Colors.grey, fontSize: 15)),
                            ],
                          ),
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                          items: sections.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: const TextStyle(color: AppColors.textPrimary)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSection = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              AuthTextField(
                hintText: "Department",
                icon: Icons.corporate_fare_outlined,
                controller: _departmentController,
              ),
              const SizedBox(height: 12),

              AuthTextField(
                hintText: "CNIC Number (Without Dashes)",
                icon: Icons.subtitles_outlined,
                controller: _cnicController,
              ),
              const SizedBox(height: 12),

              AuthTextField(
                hintText: "Password",
                icon: Icons.lock_open_outlined,
                isPassword: true,
                obscureText: _obscurePassword,
                controller: _passwordController,
                onToggle: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              const SizedBox(height: 12),

              AuthTextField(
                hintText: "Confirm Password",
                icon: Icons.lock_outline,
                isPassword: true,
                obscureText: _obscureConfirmPassword,
                controller: _confirmPasswordController,
                onToggle: () => setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              const SizedBox(height: 24),

              /// SIGN UP BUTTON WITH SOLID GRADIENT & SHADOW
              GestureDetector(
                onTap: authProvider.isLoading || _loading
                    ? null
                    : () async {
                  if (selectedSemester == null || selectedSection == null) {
                    _showError("Please select semester and section");
                    return;
                  }

                  String name = _nameController.text.trim();
                  String fatherName = _fatherNameController.text.trim();
                  String email = _emailController.text.trim();
                  String rollNumber = _rollNumberController.text.trim();
                  String department = _departmentController.text.trim();
                  String cnic = _cnicController.text.trim();
                  String password = _passwordController.text.trim();
                  String confirm = _confirmPasswordController.text.trim();

                  if (password != confirm) {
                    _showError("Passwords do not match");
                    return;
                  }

                  String? role = await StorageService.getRole();
                  if (role != "student") {
                    _showError("Invalid role selected");
                    return;
                  }

                  setState(() => _loading = true);

                  bool success = await authProvider.signup(
                    name: name,
                    email: email,
                    password: password,
                    role: role!,
                    fatherName: fatherName,
                    rollNumber: rollNumber,
                    semester: selectedSemester!,
                    department: department,
                    cnic: cnic,
                    section: selectedSection!,
                  );

                  setState(() => _loading = false);

                  if (!success) {
                    _showError(authProvider.error ?? "Signup failed");
                    return;
                  }

                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    MainScreen.routeName,
                        (route) => false,
                  );
                },
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
                    child: (_loading || authProvider.isLoading)
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                        : const Text(
                      "Create Account",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
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
                  const Text("Already have an account? ", style: TextStyle(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
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

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}