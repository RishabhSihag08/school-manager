import 'package:flutter/material.dart';

/// School Manager color design tokens matching DESIGN.md
class AppColors {
  AppColors._();

  // Surface Elevation Tokens (Warm tactile light mode)
  static const Color surfaceCanvas = Color(0xFFF7F6F2); // Warm Alabaster Canvas
  static const Color surfaceCard = Color(0xFFFFFFFF); // Pure White Elevated Bento Surface
  static const Color surfaceField = Color(0xFFEFECE6); // Soft Sand Input / Recessed Field Fill
  static const Color surfaceGlass = Color(0xD9FFFFFF); // Frosted Glass (rgba(255, 255, 255, 0.85))
  static const Color surfaceMuted = Color(0xFFF4F2EC); // Muted container tint
  static const Color surfaceBorder = Color(0xFFE6E4DD); // Subtle 1px Sand Outline

  // Backwards compatibility aliases
  static const Color canvasBackground = surfaceCanvas;
  static const Color cardSurface = surfaceCard;
  static const Color cardBorder = surfaceBorder;
  static const Color secondarySurface = surfaceField;

  // Typography / Ink Colors (The Refined Dark Ink Rule: never harsh #000000)
  static const Color inkPrimary = Color(0xFF18181B); // Carbon Ink (WCAG AAA >= 13.8:1)
  static const Color inkSecondary = Color(0xFF52525B); // Muted Slate (WCAG AA >= 7.2:1)
  static const Color inkMuted = Color(0xFFA1A1AA); // Subtle Stone captions/hints (>= 4.5:1)
  static const Color inkInverse = Color(0xFFFFFFFF); // Pure White on dark/saturated fills

  // Brand & Semantic Accents
  static const Color brandPrimary = Color(0xFF4F46E5); // Royal Oxford / Electric Indigo
  static const Color brandPrimaryHover = Color(0xFF4338CA);
  static const Color brandPrimaryLight = Color(0xFFEEF2FF);

  // Milestone & Live Urgency Accents
  static const Color accentStreak = Color(0xFFFF6B4A); // Signal Tangerine / CoVibe Coral Streak
  static const Color coralStreak = accentStreak;
  static const Color coralLight = Color(0xFFFFEBE6);
  static const Color accentPop = accentStreak;

  // Subject & House Accents
  static const Color accentStem = Color(0xFF7C3AED); // Electric Violet (STEM / Computer / Tech)
  static const Color electricViolet = accentStem;
  static const Color accentStemBg = Color(0xFFF5F3FF);

  static const Color accentAchievement = Color(0xFFF59E0B); // Golden Topaz (Awards / Honors / Milestones)
  static const Color goldenTopaz = accentAchievement;
  static const Color accentAchievementBg = Color(0xFFFEF3C7);

  // Semantic Feedback
  static const Color success = Color(0xFF10B981); // Emerald Mint
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B); // Warm Amber
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFEF4444); // Vibrant Crimson
  static const Color dangerBg = Color(0xFFFEE2E2);

  // Indian School House Colors
  static const Color houseRed = Color(0xFFEF4444);
  static const Color houseRedBg = Color(0xFFFEE2E2);
  static const Color houseBlue = Color(0xFF2563EB);
  static const Color houseBlueBg = Color(0xFFDBEAFE);
  static const Color houseGreen = Color(0xFF10B981);
  static const Color houseGreenBg = Color(0xFFD1FAE5);
  static const Color houseYellow = Color(0xFFF59E0B);
  static const Color houseYellowBg = Color(0xFFFEF3C7);

  // Subject Accents (Soft Pastel Pill BG + Bold Primary Icon)
  static const Color subjectMathBg = Color(0xFFEEF2FF);
  static const Color subjectMathFg = Color(0xFF4F46E5);

  static const Color subjectScienceBg = Color(0xFFECFDF5);
  static const Color subjectScienceFg = Color(0xFF059669);

  static const Color subjectEnglishBg = Color(0xFFFFF1F2);
  static const Color subjectEnglishFg = Color(0xFFE11D48);

  static const Color subjectHindiBg = Color(0xFFFFFBEB);
  static const Color subjectHindiFg = Color(0xFFD97706);

  static const Color subjectSstBg = Color(0xFFF0F9FF);
  static const Color subjectSstFg = Color(0xFF0284C7);

  static const Color subjectComputerBg = accentStemBg;
  static const Color subjectComputerFg = accentStem;

  static const Color subjectStemBg = accentStemBg;
  static const Color subjectStemFg = accentStem;

  static const Color subjectAchievementBg = accentAchievementBg;
  static const Color subjectAchievementFg = accentAchievement;

  // Subtle Bento Gradients
  static const LinearGradient cardSubtleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFFAF9F6),
    ],
  );

  static const LinearGradient glassSubtleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xE6FFFFFF), // 90% opacity white
      Color(0xCCFFFFFF), // 80% opacity white
    ],
  );

  // Helpers for House colors
  static Color getHouseColor(String? house) {
    switch (house?.toLowerCase()) {
      case 'red':
        return houseRed;
      case 'blue':
        return houseBlue;
      case 'green':
        return houseGreen;
      case 'yellow':
        return houseYellow;
      default:
        return brandPrimary;
    }
  }

  static Color getHouseBgColor(String? house) {
    switch (house?.toLowerCase()) {
      case 'red':
        return houseRedBg;
      case 'blue':
        return houseBlueBg;
      case 'green':
        return houseGreenBg;
      case 'yellow':
        return houseYellowBg;
      default:
        return brandPrimaryLight;
    }
  }

  static Color getSubjectColor(String? codeOrName) {
    return getSubjectColors(codeOrName).$2;
  }

  // Helper for Subject colors
  static (Color bg, Color fg) getSubjectColors(String? codeOrName) {
    final query = codeOrName?.toLowerCase() ?? '';
    if (query.contains('math')) {
      return (subjectMathBg, subjectMathFg);
    } else if (query.contains('sci')) {
      return (subjectScienceBg, subjectScienceFg);
    } else if (query.contains('eng')) {
      return (subjectEnglishBg, subjectEnglishFg);
    } else if (query.contains('hin') || query.contains('san')) {
      return (subjectHindiBg, subjectHindiFg);
    } else if (query.contains('sst') || query.contains('soc')) {
      return (subjectSstBg, subjectSstFg);
    } else if (query.contains('comp') || query.contains('it') || query.contains('stem') || query.contains('robot')) {
      return (subjectComputerBg, subjectComputerFg);
    } else if (query.contains('achieve') || query.contains('award') || query.contains('topaz')) {
      return (subjectAchievementBg, subjectAchievementFg);
    }
    return (brandPrimaryLight, brandPrimary);
  }
}
