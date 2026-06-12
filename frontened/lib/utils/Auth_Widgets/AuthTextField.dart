
import 'package:flutter/material.dart';
import 'package:frontened/main.dart';

/// ------------------------------------------------------------
/// TEXT FIELD
/// ------------------------------------------------------------

class AuthTextField extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onToggle;
  final TextEditingController? controller;

  const AuthTextField({
    super.key,
    required this.hintText,
    required this.icon,
    this.controller,
    this.isPassword = false,
    this.obscureText = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscureText : false,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          prefixIcon: Icon(icon, color: AppColors.textSecondary),
          hintText: hintText,
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
          ),
          suffixIcon: isPassword
              ? GestureDetector(
                  onTap: onToggle,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("Show"),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}