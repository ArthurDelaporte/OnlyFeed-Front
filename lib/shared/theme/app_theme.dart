import 'package:flutter/material.dart';

class AppColors {
  static const Color abricot = Color(0xFFFFA07A);      // Abricot chaud
  static const Color basilic = Color(0xFF7BBF6A);      // Vert basilic
  static const Color pain = Color(0xFFF5EBDC);         // Beige pain
  static const Color chocolat = Color(0xFF5C3A21);     // Brun chocolat
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.abricot,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.pain,
      foregroundColor: AppColors.chocolat,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.bold,
        fontSize: 22,
        color: AppColors.chocolat,
      ),
    ),
    colorScheme: const ColorScheme.light(
      primary: AppColors.abricot,
      secondary: AppColors.basilic,
      onPrimary: Colors.white,
      onSecondary: AppColors.chocolat,
      onSurface: AppColors.chocolat,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: AppColors.chocolat),
      bodyMedium: TextStyle(fontSize: 16, fontFamily: 'Inter', color: AppColors.chocolat),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.basilic,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),
  );
}

class AppDarkTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1E1E1E),
    primaryColor: AppColors.abricot,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2A2A2A),
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.bold,
        fontSize: 22,
        color: Colors.white,
      ),
    ),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.abricot,
      secondary: AppColors.basilic,
      onPrimary: Colors.white,
      onSecondary: AppColors.pain,
      onSurface: Colors.white70,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Colors.white),
      bodyMedium: TextStyle(fontSize: 16, fontFamily: 'Inter', color: Colors.white70),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.basilic,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF2D2D2D),
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),
  );
}

