import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette
  static const Color primaryOrange = Color(0xFFFD6F24);
  static const Color primaryOrangeLight = Color(0xFFFF8A50);
  static const Color primaryOrangeDark = Color(0xFFE55A10);
  static const Color accentYellow = Color(0xFFF1F3C2);
  static const Color accentYellowLight = Color(0xFFF9FAD8);
  static const Color accentYellowDark = Color(0xFFE8EAA0);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color successGreenLight = Color(0xFF81C784);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFE53935);
  static const Color infoBlue = Color(0xFF2196F3);
  static const Color infoBlueLight = Color(0xFF64B5F6);
  static const Color purpleAccent = Color(0xFF9C27B0);
  static const Color purpleAccentLight = Color(0xFFBA68C8);
  
  // Neutral Colors
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575);
  static const Color gray700 = Color(0xFF616161);
  static const Color gray800 = Color(0xFF424242);
  static const Color gray900 = Color(0xFF212121);

  // Simple Card Shadow
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          offset: const Offset(0, 2),
          blurRadius: 8,
          spreadRadius: 0,
        ),
      ];

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryOrange,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.light(
        primary: primaryOrange,
        secondary: accentYellow,
        surface: gray50,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: gray900,
        onSurface: gray900,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        shadowColor: Colors.black.withValues(alpha: 0.08),
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: gray900,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: gray900,
          letterSpacing: -0.5,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: gray900,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: gray900,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: gray900,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: gray900,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: gray800,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: gray700,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.normal,
          color: gray600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: gray900,
        ),
        iconTheme: const IconThemeData(color: gray900),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryOrange,
        unselectedItemColor: gray600,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryOrange,
      scaffoldBackgroundColor: gray900,
      colorScheme: ColorScheme.dark(
        primary: primaryOrange,
        secondary: accentYellow,
        surface: gray800,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: gray900,
        onSurface: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: gray800,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: gray300,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.normal,
          color: gray400,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: gray900,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: gray800,
        selectedItemColor: primaryOrange,
        unselectedItemColor: gray400,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.normal,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
