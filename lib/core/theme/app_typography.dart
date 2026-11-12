import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// School Manager typography tokens using Plus Jakarta Sans, Inter, and JetBrains Mono.
class AppTypography {
  AppTypography._();

  // Display / Hero Headings (Plus Jakarta Sans)
  static TextStyle displayLarge = GoogleFonts.plusJakartaSans(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.inkPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static TextStyle displayMedium = GoogleFonts.plusJakartaSans(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.inkPrimary,
    letterSpacing: -0.4,
    height: 1.25,
  );

  static TextStyle displaySmall = GoogleFonts.plusJakartaSans(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.inkPrimary,
    letterSpacing: -0.3,
  );

  // Section Titles (Plus Jakarta Sans)
  static TextStyle titleLarge = GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.inkPrimary,
    letterSpacing: -0.2,
  );

  static TextStyle titleMedium = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.inkPrimary,
  );

  static TextStyle titleSmall = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.inkPrimary,
  );

  // Body & Paragraphs (Inter)
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.inkSecondary,
    height: 1.45,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.inkSecondary,
    height: 1.4,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.inkMuted,
    height: 1.35,
  );

  static TextStyle bodySemibold = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.inkPrimary,
  );

  // Monospace (JetBrains Mono) for Class Codes, Roll Numbers, Times, Percentages
  static TextStyle monoLarge = GoogleFonts.jetBrainsMono(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.brandPrimary,
    letterSpacing: 2.0,
  );

  static TextStyle monoMedium = GoogleFonts.jetBrainsMono(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.inkPrimary,
    letterSpacing: 1.0,
  );

  static TextStyle monoSmall = GoogleFonts.jetBrainsMono(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.inkSecondary,
    letterSpacing: 0.5,
  );

  // Interactive Buttons & Pills
  static TextStyle buttonLabel = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.inkInverse,
    letterSpacing: 0.2,
  );

  static TextStyle pillLabel = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.brandPrimary,
    letterSpacing: 0.2,
  );

  // Material & Convenience Aliases
  static TextStyle get headlineLarge => displayLarge;
  static TextStyle get headlineMedium => displayMedium;
  static TextStyle get headlineSmall => displaySmall;
  static TextStyle get labelLarge => buttonLabel;
  static TextStyle get labelMedium => pillLabel;
  static TextStyle get labelSmall => bodySmall;
  static TextStyle get caption => bodySmall;
  static TextStyle get button => buttonLabel;

  static TextStyle monospace({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? AppColors.inkPrimary,
      );
}
