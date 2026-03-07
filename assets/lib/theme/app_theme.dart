import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF8B5CF6);
  static const Color primaryAccent = Color(0xFFA855F7);
  static const Color background = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFF6F3FF);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static const double borderRadius = 12.0;

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.primaryAccent,
        surface: AppColors.background,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(color: AppColors.textPrimary),
      ),
    );
  }
}
