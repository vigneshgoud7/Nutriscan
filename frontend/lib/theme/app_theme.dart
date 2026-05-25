import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand Colors ────────────────────────────────────────────
  static const Color primary = Color(0xFF00C896);       // vibrant mint green
  static const Color primaryDark = Color(0xFF00A87A);
  static const Color surface = Color(0xFF0F1923);        // near-black blue
  static const Color surfaceCard = Color(0xFF1A2634);    // card bg
  static const Color surfaceElevated = Color(0xFF243040); // elevated card
  static const Color onSurface = Color(0xFFF0F4F8);
  static const Color onSurfaceMuted = Color(0xFF8FA3B3);
  static const Color border = Color(0xFF2A3A4A);
  static const Color danger = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFB74D);
  static const Color info = Color(0xFF4FC3F7);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          onPrimary: Color(0xFF001A12),
          secondary: Color(0xFF4FC3F7),
          surface: surface,
          onSurface: onSurface,
          error: danger,
        ),
        scaffoldBackgroundColor: surface,
        cardColor: surfaceCard,
        dividerColor: border,
        textTheme: GoogleFonts.dmSansTextTheme().copyWith(
          displayLarge: GoogleFonts.dmSans(
            fontSize: 32, fontWeight: FontWeight.w700, color: onSurface, letterSpacing: -0.5,
          ),
          displayMedium: GoogleFonts.dmSans(
            fontSize: 24, fontWeight: FontWeight.w600, color: onSurface, letterSpacing: -0.3,
          ),
          titleLarge: GoogleFonts.dmSans(
            fontSize: 18, fontWeight: FontWeight.w600, color: onSurface,
          ),
          titleMedium: GoogleFonts.dmSans(
            fontSize: 16, fontWeight: FontWeight.w500, color: onSurface,
          ),
          bodyLarge: GoogleFonts.dmSans(
            fontSize: 16, fontWeight: FontWeight.w400, color: onSurface, height: 1.6,
          ),
          bodyMedium: GoogleFonts.dmSans(
            fontSize: 14, fontWeight: FontWeight.w400, color: onSurfaceMuted, height: 1.5,
          ),
          labelLarge: GoogleFonts.dmSans(
            fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2,
          ),
        ).apply(
          bodyColor: onSurface,
          displayColor: onSurface,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          iconTheme: const IconThemeData(color: onSurface),
          titleTextStyle: GoogleFonts.dmSans(
            fontSize: 18, fontWeight: FontWeight.w600, color: onSurface,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: const Color(0xFF001A12),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            side: const BorderSide(color: primary, width: 1.5),
            textStyle: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceCard,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: danger),
          ),
          labelStyle: GoogleFonts.dmSans(color: onSurfaceMuted, fontSize: 14),
          hintStyle: GoogleFonts.dmSans(color: onSurfaceMuted, fontSize: 14),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: surfaceElevated,
          contentTextStyle: GoogleFonts.dmSans(color: onSurface, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surfaceCard,
          selectedItemColor: primary,
          unselectedItemColor: onSurfaceMuted,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
        ),
      );
}
