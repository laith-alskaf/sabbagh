import 'package:flutter/material.dart';
import 'package:sabbagh_app/core/constants/app_colors.dart';

/// Application theme configuration
class AppThemes {
  /// Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: AppColors.primaryGreen,
      secondary: AppColors.secondaryGreen,
      error: AppColors.error,
      background: AppColors.background,
      surface: AppColors.cardColor,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onError: AppColors.white,
      onBackground: AppColors.black,
      onSurface: AppColors.black,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      color: AppColors.cardColor,
      elevation: 2,
      shadowColor: AppColors.shadowColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        minimumSize: const Size(120, 48),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryGreen,
        side: const BorderSide(color: AppColors.primaryGreen),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        minimumSize: const Size(120, 48),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.mediumGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.mediumGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryGreen),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      hintStyle: const TextStyle(color: AppColors.darkGray),
      labelStyle: const TextStyle(color: AppColors.darkGray),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.mediumGray,
      thickness: 1,
      space: 1,
    ),
    fontFamily: 'Cairo',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.black,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.black,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.black,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.black,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.black,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.black,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.black,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.black,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.black,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: AppColors.black,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.black,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: AppColors.darkGray,
      ),
    ),
  );

  /// Dark theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryGreen,
      secondary: AppColors.secondaryGreen,
      error: AppColors.error,
      background: const Color(0xFF121212),
      surface: const Color(0xFF1E1E1E),
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onError: AppColors.white,
      onBackground: AppColors.white,
      onSurface: AppColors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shadowColor: AppColors.shadowColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        minimumSize: const Size(120, 48),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryGreen,
        side: const BorderSide(color: AppColors.primaryGreen),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        minimumSize: const Size(120, 48),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF424242)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF424242)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryGreen),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
      labelStyle: const TextStyle(color: Color(0xFFAAAAAA)),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF424242),
      thickness: 1,
      space: 1,
    ),
    fontFamily: 'Cairo',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: AppColors.white,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.white,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: Color(0xFFAAAAAA),
      ),
    ),
  );
}