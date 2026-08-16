import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryCyan,
        secondary: AppColors.warningAmber,
        surface: AppColors.surface,
        error: AppColors.alertRed,
        onPrimary: AppColors.background,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryCyan,
          foregroundColor: AppColors.background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryCyan, width: 1.5),
        ),
        hintStyle: GoogleFonts.outfit(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
      ),
    );
  }
}
