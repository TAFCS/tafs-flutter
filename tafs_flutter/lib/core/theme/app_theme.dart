import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF255A94);
  static const Color accent = Color(0xFFD56637);
  
  // Text Colors
  static const Color textMain = Color(0xFF1A1A1A);
  static const Color textMuted = Color(0xFF6C757D);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  // Surface Levels
  static const Color background = Color(0xFFF8F9FA); // Surface 0
  static const Color surface1 = Color(0xFFFFFFFF);   // Level 1: Base Component
  static const Color surface2 = Color(0xFFFFFFFF);   // Level 2: Elevated Card
  static const Color surface3 = Color(0xFFFFFFFF);   // Level 3: Overlay/Tooltip
  
  // Colors
  static const Color borderSubtle = Color(0xFFE9ECEF);
  static const Color error = Color(0xFFDC3545);
  
  // Box Shadows
  static const List<BoxShadow> shadowL1 = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 3, offset: Offset(0, 1))
  ];
  static const List<BoxShadow> shadowL2 = [
    BoxShadow(color: Color(0x12000000), blurRadius: 6, offset: Offset(0, 4))
  ];
  static const List<BoxShadow> shadowL3 = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 15, offset: Offset(0, 10))
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: surface1,
        onPrimary: textOnPrimary,
        onSurface: textMain,
        error: Colors.redAccent,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.dmSansTextTheme().apply(
        bodyColor: textMain,
        displayColor: textMain,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface1,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        labelStyle: const TextStyle(color: textMuted),
        hintStyle: const TextStyle(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textOnPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          minimumSize: const Size(44, 44), // Minimum touch target as per guidelines
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          minimumSize: const Size(44, 44),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
