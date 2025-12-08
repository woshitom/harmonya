import 'package:flutter/material.dart';

class AppTheme {
  // Brown and beige color palette
  static const Color primaryBrown = Color(0xFF6B4423); // Dark brown
  static const Color secondaryBrown = Color(0xFF8B6F47); // Medium brown
  static const Color lightBeige = Color(0xFFF5F1E8); // Light beige
  static const Color mediumBeige = Color(0xFFE8DDD0); // Medium beige
  static const Color darkBeige = Color(0xFFD4C4B0); // Dark beige

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBrown,
        primary: primaryBrown,
        secondary: secondaryBrown,
        surface: lightBeige,
        background: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBrown,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightBeige,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBrown,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightBeige,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: mediumBeige),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: mediumBeige),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryBrown, width: 2),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: primaryBrown,
        ),
        displayMedium: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: primaryBrown,
        ),
        displaySmall: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: primaryBrown,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primaryBrown,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Color(0xFF4A4A4A),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Color(0xFF4A4A4A),
        ),
      ),
    );
  }
}

