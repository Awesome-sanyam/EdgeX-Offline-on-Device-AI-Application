import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EdgeXTheme {
  // Brand Colors
  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceHighlight = Color(0xFF334155);
  
  static const Color cyanAccent = Color(0xFF06B6D4);
  static const Color cyanGlow = Color(0x3306B6D4); // 20% opacity cyan
  static const Color purpleAccent = Color(0xFF8B5CF6);
  
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent, // Background handled by AppShell
      colorScheme: const ColorScheme.dark(
        primary: cyanAccent,
        secondary: purpleAccent,
        surface: surface,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.bold),
        displaySmall: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.bold),
        headlineSmall: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w600),
        titleSmall: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.outfit(color: textPrimary),
        bodyMedium: GoogleFonts.outfit(color: textPrimary),
        bodySmall: GoogleFonts.outfit(color: textSecondary),
        labelLarge: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w600),
        labelMedium: GoogleFonts.outfit(color: textSecondary, fontWeight: FontWeight.w500),
        labelSmall: GoogleFonts.outfit(color: textSecondary, fontWeight: FontWeight.w500),
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerColor: Colors.white.withValues(alpha: 0.1),
    );
  }
}
