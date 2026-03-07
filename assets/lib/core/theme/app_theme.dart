import 'package:flutter/material.dart';

/// Minimal dark theme color palette for OcSafe CyberGuard.
class AppColors {
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F7FF);
  static const Color cardSurface = Color(0xFFF8F7FF);
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  static const Color primary = Color(0xFF8B5CF6); // Purple
  static const Color primaryAccent = Color(0xFFA855F7); // Lighter Purple
  static const Color primaryLight = Color(0xFFF3F0FF);
  
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);
}

class AppTheme {
  static const double borderRadius = 12.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primary,
        surface: AppColors.surfaceWhite,
        error: AppColors.error,
        onSurface: AppColors.textPrimary,
        onPrimary: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          fontFamily: 'InstrumentSans', // Suggesting modern sans if available
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.primary, size: 24),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
          letterSpacing: -0.8,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceWhite,
        indicatorColor: AppColors.primary.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.primary, 
              fontWeight: FontWeight.w800,
              fontSize: 12,
            );
          }
          return const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          );
        }),
      ),
    );
  }
}
