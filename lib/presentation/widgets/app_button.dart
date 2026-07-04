import 'package:flutter/material.dart';
import 'package:salesperson_app/core/constants/app_colors.dart';

enum ButtonType { primary, brand, light }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonType type;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    BorderSide borderSide = BorderSide.none;

    switch (type) {
      case ButtonType.primary:
        bgColor = AppColors.ink;
        textColor = AppColors.white;
        break;
      case ButtonType.brand:
        bgColor = AppColors.brand;
        textColor = AppColors.white;
        break;
      case ButtonType.light:
        bgColor = AppColors.white;
        textColor = AppColors.ink;
        borderSide = const BorderSide(color: AppColors.line);
        break;
    }

    Widget button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: type == ButtonType.light ? 0 : 6,
        shadowColor: type == ButtonType.light ? Colors.transparent : bgColor.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: borderSide,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        minimumSize: const Size(0, 56),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
