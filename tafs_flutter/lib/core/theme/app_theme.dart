import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color blue100 = Color(0xFFBCD0EA);
  static const Color blue200 = Color(0xFFB1C7E4);
  static const Color blue300 = Color(0xFF4C617F);
  static const Color navy = Color(0xFF021A54);

  // Status Colors
  static const Color paid = Color(0xFF22C27B);
  static const Color success = paid;
  static const Color paidBg = Color(0xFFE8FAF3);
  static const Color unpaid = Color(0xFFE84646);
  static const Color danger = unpaid;
  static const Color unpaidBg = Color(0xFFFDEAEA);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF3C7);

  // Gradients
  static const LinearGradient navyGradient = LinearGradient(
    colors: [navy, Color(0xFF1B436D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF22C27B), Color(0xFF109D5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFE84646), Color(0xFFC02A2A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [white, Color(0xFFF8FAFC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Spacing
  static const double space1 = 4.0;
  static const double space2 = 8.0;
  static const double space3 = 12.0;
  static const double space4 = 16.0;
  static const double space5 = 20.0;
  static const double space6 = 24.0;
  static const double space8 = 32.0;
  static const double space10 = 40.0;
  static const double space12 = 48.0;
  static const double space16 = 64.0;

  // Radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusFull = 9999.0;

  // Status Colors (Legacy support for consistency)
  static const Color primary = navy;
  static const Color accent = blue200;
  static const Color background = white;
  static const Color surface1 = white;
  static const Color surface2 = Color(0xFFF8FAFC);
  static const Color textMain = navy;
  static const Color textMuted = blue300;
  static const Color borderSubtle = blue100;
  static const Color error = unpaid;

  // Shadows tinted with Navy
  static List<BoxShadow> shadowXs = [
    BoxShadow(
      color: navy.withOpacity(0.06),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];
  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: navy.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: navy.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  static List<BoxShadow> shadowLg = [
    BoxShadow(
      color: navy.withOpacity(0.16),
      blurRadius: 32,
      offset: const Offset(0, 8),
    ),
  ];

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.readexProTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: navy,
        primary: navy,
        secondary: blue200,
        surface: white,
        surfaceTint: navy,
        onPrimary: white,
        onSurface: navy,
        error: unpaid,
      ),
      scaffoldBackgroundColor: white,
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(fontSize: 34, fontWeight: FontWeight.w700, color: navy),
        displayMedium: baseTextTheme.displayMedium?.copyWith(fontSize: 27, fontWeight: FontWeight.w700, color: navy),
        displaySmall: baseTextTheme.displaySmall?.copyWith(fontSize: 21, fontWeight: FontWeight.w600, color: navy),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontSize: 21, fontWeight: FontWeight.w600, color: navy),
        titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: 17, fontWeight: FontWeight.w500, color: navy),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w400, color: navy),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w400, color: navy),
        labelLarge: baseTextTheme.labelLarge?.copyWith(fontSize: 11, fontWeight: FontWeight.w400, color: blue300),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(horizontal: space4, vertical: space3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: blue200, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: blue200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: navy, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: unpaid, width: 1.5),
        ),
        hintStyle: TextStyle(color: blue300, fontSize: 15),
        labelStyle: TextStyle(color: navy.withOpacity(0.7), fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
          padding: const EdgeInsets.symmetric(vertical: space3, horizontal: space6),
          textStyle: GoogleFonts.readexPro(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: navy,
          side: const BorderSide(color: navy, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
          padding: const EdgeInsets.symmetric(vertical: space3, horizontal: space6),
          textStyle: GoogleFonts.readexPro(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: blue100,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          side: const BorderSide(color: blue100, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: navy,
        contentTextStyle: GoogleFonts.readexPro(color: white, fontSize: 15),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: white,
        foregroundColor: navy,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.readexPro(
          color: navy,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: white,
        surfaceTintColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: GoogleFonts.readexPro(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: navy,
        ),
        contentTextStyle: GoogleFonts.readexPro(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: navy,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(space4, 0, space4, space4),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface2,
        surfaceTintColor: surface2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: white,
        surfaceTintColor: white,
        textStyle: GoogleFonts.readexPro(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: navy,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(white),
          surfaceTintColor: WidgetStateProperty.all(white),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd),
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: navy,
          textStyle: GoogleFonts.readexPro(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}


