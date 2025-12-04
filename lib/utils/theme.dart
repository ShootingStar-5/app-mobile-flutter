import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFFFFC107); // Yellow
  static const Color primaryDark = Color(0xFFFFB300);
  static const Color primaryLight = Color(0xFFFFE082);

  // Secondary colors (Navy)
  static const Color secondary = Color(0xFF1A237E); // Navy
  static const Color secondaryDark = Color(0xFF0D1642);
  static const Color secondaryLight = Color(0xFF3F51B5);

  // Background colors
  static const Color background = Color(0xFFFFFBF5); // Warm white
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;

  // Text colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
}

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.secondary,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'SUITE',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'SUITE',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.secondary,
      unselectedItemColor: AppColors.textLight,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 14,
      ),
      elevation: 8,
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardBackground,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.secondary,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.secondary,
      elevation: 4,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
      selectedColor: AppColors.primary,
      labelStyle: const TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}
