import 'package:flutter/material.dart';
import 'package:frontened/Provider/auth_provider.dart';
import 'package:frontened/main.dart';
import 'package:frontened/utils/Auth_Widgets/AppLogo.dart';
import 'package:frontened/utils/Auth_Widgets/AuthScaffold.dart';
import 'package:frontened/utils/Auth_Widgets/AuthTextField.dart';
import 'package:provider/provider.dart';



class ForgotPasswordScreen extends StatefulWidget {
  static const String routeName = '/forgot-password';

  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {

  final TextEditingController _emailController = TextEditingController();


  Future<void> _handleForgotPassword() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar("Please enter your email");
      return;
    }

    final success = await authProvider.forgotPassword(email);

    if (success) {
      _showSnackBar("Reset link sent to your email");

    } else {
      _showSnackBar(authProvider.error ?? "Something went wrong");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const AppLogo(width: 175),
          const SizedBox(height: 16),

          const Text(
            'Forgot Password',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            "Enter your email address and we’ll\nsend you a link to reset your password.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 22),

          // EMAIL FIELD
          AuthTextField(
            hintText: 'Enter your email',
            icon: Icons.email_outlined,
            controller: _emailController,
          ),

          const SizedBox(height: 22),

          // BUTTON WITH LOADING
          authProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : GradientPrimaryButton(
                  text: 'Send Reset Link',
                  onPressed: _handleForgotPassword,
                ),

          const SizedBox(height: 22),

          const _BackToLoginText(),

          const Spacer(),
        ],
      ),
    );
  }
}

class _BackToLoginText extends StatelessWidget {
  const _BackToLoginText();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: const Text(
        'Back to Login',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}