import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EdgeXTheme {
  // === BASE PALETTE ===
  // True near-black with subtle blue tint (Gemini-esque depth)
  static const Color background = Color(0xFF080C14);
  static const Color surface = Color(0xFF0F172A);
  static const Color surface2 = Color(0xFF1A2338);
  static const Color surfaceHighlight = Color(0xFF2D3F5C);

  // === ACCENT COLORS ===
  static const Color cyanAccent = Color(0xFF06B6D4);
  static const Color cyanGlow = Color(0x4006B6D4);
  static const Color purpleAccent = Color(0xFF8B5CF6);
  static const Color purpleGlow = Color(0x408B5CF6);
  static const Color emeraldAccent = Color(0xFF10B981);
  static const Color amberAccent = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);

  // === GRADIENT DEFINITIONS ===
  static const LinearGradient userBubbleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
  );

  static const RadialGradient shellBackground = RadialGradient(
    center: Alignment(0.7, -0.8),
    radius: 1.4,
    colors: [Color(0xFF1A2338), Color(0xFF080C14)],
  );

  static const LinearGradient navBarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00080C14), Color(0xFF080C14)],
  );

  // === TEXT COLORS ===
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF334155);

  // === THEME DATA ===
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: const ColorScheme.dark(
        primary: cyanAccent,
        secondary: purpleAccent,
        surface: surface,
        error: errorRed,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w900),
        displayMedium: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w800),
        displaySmall: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w800),
        headlineLarge: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w800),
        headlineMedium: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w700),
        headlineSmall: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w600),
        titleSmall: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.outfit(color: textPrimary, fontSize: 16, height: 1.6),
        bodyMedium: GoogleFonts.outfit(color: textPrimary, fontSize: 14, height: 1.5),
        bodySmall: GoogleFonts.outfit(color: textSecondary, fontSize: 12),
        labelLarge: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w600),
        labelMedium: GoogleFonts.outfit(color: textSecondary, fontWeight: FontWeight.w500),
        labelSmall: GoogleFonts.outfit(color: textSecondary, fontWeight: FontWeight.w500),
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerColor: Colors.white.withValues(alpha: 0.06),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: cyanAccent.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.outfit(
              color: cyanAccent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            );
          }
          return GoogleFonts.outfit(
            color: textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? cyanAccent : textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? cyanAccent.withValues(alpha: 0.25)
              : surfaceHighlight.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
