import 'package:flutter/material.dart';
import 'package:salesperson_app/core/constants/app_colors.dart';

class AppInput extends StatelessWidget {
  final String? placeholder;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;

  const AppInput({
    super.key,
    this.placeholder,
    this.obscureText = false,
    this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.ink,
        ),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(color: AppColors.muted),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
