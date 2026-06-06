import 'package:flutter/material.dart';

/// Semantic color tokens for the Dharma bedtime story experience.
///
/// Screens should consume these tokens or [Theme.of] colors rather than
/// defining raw color values locally.
abstract final class AppColors {
  // Night surfaces.
  static const surfaceBase = Color(0xFF0F1425);
  static const surfaceDark = Color(0xFF080D1D);
  static const surfaceDeep = Color(0xFF070B19);
  static const surfaceElevated = Color(0xFF1E2952);
  static const surfaceCard = Color(0xFF16203C);
  static const surfaceCardDeep = Color(0xFF10183D);
  static const surfaceOverlay = Color(0xFF11184A);
  static const surfaceNavigation = Color(0xFF111735);
  static const surfaceImageFallback = Color(0xFF202A5F);
  static const surfaceImageFallbackDark = Color(0xFF111832);
  static const surfaceInk = Color(0xFF050914);
  static const surfaceBlack = Color(0xFF000000);
  static const surfaceWhite = Color(0xFFFFFFFF);
  static const transparent = Color(0x00000000);

  // Primary interaction.
  static const accentPrimary = Color(0xFF7A5CFF);
  static const accentPrimaryLight = Color(0xFFA9A7FF);
  static const accentPrimarySoft = Color(0xFFC8BBFF);
  static const accentPrimaryDim = Color(0xFF6F5FE0);
  static const accentSecondary = Color(0xFF6FA3FF);
  static const accentSecondaryDeep = Color(0xFF283A8C);
  static const accentLavender = Color(0xFF8192FF);

  // Emotional and status colors.
  static const emotionalWarmth = Color(0xFFFFD96B);
  static const emotionalWarmthBright = Color(0xFFFFE06B);
  static const emotionalWarmthLight = Color(0xFFFFE6A4);
  static const emotionalWarmthSoft = Color(0xFFFFECA1);
  static const successGreen = Color(0xFF4ECB71);
  static const warningOrange = Color(0xFFFF9500);
  static const attentionRed = Color(0xFFFF6B6B);

  // Night-theme text and icon colors.
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB8C3E0);
  static const textTertiary = Color(0xFF8A99BB);
  static const textOnAccent = Color(0xFF091026);
  static const textOnAccentSoft = Color(0xFF18172E);

  // Warm story-player palette.
  static const playerBackground = Color(0xFFFFF8EE);
  static const playerSurface = Color(0xFFFFFFFF);
  static const playerPrimary = Color(0xFFFF6B5A);
  static const playerWarmGold = Color(0xFFFFC95C);
  static const playerWarmGoldLight = Color(0xFFFFD47A);
  static const playerPurple = Color(0xFF4B3A73);
  static const playerPurpleMuted = Color(0xFF6D5C9F);
  static const playerPurpleDeep = Color(0xFF2D216F);
  static const playerText = Color(0xFF3B3451);
  static const playerTextSecondary = Color(0xFF746B84);
  static const playerGreen = Color(0xFF5F8F68);
  static const playerDisabled = Color(0xFF756A82);
  static const playerBorder = Color(0xFFF1E7D8);
  static const playerShadow = Color(0xFF5B4636);

  // Auth and companion accents.
  static const authSurface = Color(0xFF15162F);
  static const authSurfacePurple = Color(0xFF151333);
  static const authSurfaceDark = Color(0xFF090E1A);
  static const companionBadgeSurface = Color(0xFF332B2C);
  static const companionGold = Color(0xFFFFD65B);
  static const companionGoldLight = Color(0xFFFFEB80);

  // Light theme foundations.
  static const lightSurfaceBase = Color(0xFFF8F7FC);
  static const lightSurfaceElevated = Color(0xFFFFFFFF);
  static const lightSurfaceCard = Color(0xFFF0F1FA);
  static const lightTextPrimary = Color(0xFF171B2E);
  static const lightTextSecondary = Color(0xFF4F5873);
  static const lightTextTertiary = Color(0xFF727B95);

  // Predefined opacity tokens.
  static const textHighEmphasis = Color(0xC2FFFFFF);
  static const textMediumEmphasis = Color(0xA3FFFFFF);
  static const textLowEmphasis = Color(0x8AFFFFFF);
  static const textDisabled = Color(0x61FFFFFF);
  static const borderLight = Color(0x1CFFFFFF);
  static const borderMedium = Color(0x24FFFFFF);
  static const borderDark = Color(0x12FFFFFF);
  static const borderStrong = Color(0x47FFFFFF);
  static const surfaceWhite05 = Color(0x0DFFFFFF);
  static const surfaceWhite08 = Color(0x14FFFFFF);
  static const surfaceWhite12 = Color(0x1FFFFFFF);
  static const surfaceWhite16 = Color(0x29FFFFFF);
  static const surfaceWhite18 = Color(0x2EFFFFFF);
  static const overlayBlack18 = Color(0x2E000000);
  static const overlayBlack22 = Color(0x38000000);
  static const overlayBlack24 = Color(0x3D000000);
  static const overlayBlack28 = Color(0x47000000);
  static const overlayBlack46 = Color(0x75000000);
  static const overlayBlack62 = Color(0x9E000000);
  static const featuredOverlaySoft = Color(0x2E050914);
  static const featuredOverlayStrong = Color(0xD1050914);
  static const playerShadowSoft = Color(0x245B4636);

  static Color textPrimaryWith(double opacity) =>
      textPrimary.withValues(alpha: opacity);

  static Color textSecondaryWith(double opacity) =>
      textSecondary.withValues(alpha: opacity);

  static Color accentPrimaryWith(double opacity) =>
      accentPrimary.withValues(alpha: opacity);

  static Color emotionalWarmthWith(double opacity) =>
      emotionalWarmth.withValues(alpha: opacity);

  static Color surfaceCardWith(double opacity) =>
      surfaceCard.withValues(alpha: opacity);

  static Color surfaceOverlayWith(double opacity) =>
      surfaceOverlay.withValues(alpha: opacity);
}
