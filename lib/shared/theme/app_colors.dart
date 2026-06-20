import 'package:flutter/material.dart';

/// Semantic color tokens for the Dharma bedtime story experience.
///
/// Screens should consume these tokens or [Theme.of] colors rather than
/// defining raw color values locally.
abstract final class AppColors {
  // Figma primitive palette.
  static const blue900 = Color(0xFF004660);
  static const blue800 = Color(0xFF00688E);
  static const blue700 = Color(0xFF0082B2);
  static const blue600 = Color(0xFF009DD7);
  static const blue500 = Color(0xFF00AEEF);
  static const blue400 = Color(0xFF33C0F3);
  static const blue300 = Color(0xFF66D2F7);
  static const blue200 = Color(0xFF99E1FA);
  static const blue100 = Color(0xFFC2EEFC);
  static const blue50 = Color(0xFFE6F9FE);
  static const blue25 = Color(0xFFF5FAFF);

  static const fuchsia900 = Color(0xFF851651);
  static const fuchsia800 = Color(0xFF9E165F);
  static const fuchsia700 = Color(0xFFC11574);
  static const fuchsia600 = Color(0xFFDD2590);
  static const fuchsia500 = Color(0xFFEE46BC);
  static const fuchsia400 = Color(0xFFF670C7);
  static const fuchsia300 = Color(0xFFFAA7E0);
  static const fuchsia200 = Color(0xFFFCCEEE);
  static const fuchsia100 = Color(0xFFFCE7F6);
  static const fuchsia50 = Color(0xFFFDF2FA);
  static const fuchsia25 = Color(0xFFFEF6FB);

  static const gray900 = Color(0xFF101828);
  static const gray800 = Color(0xFF1D2939);
  static const gray700 = Color(0xFF344054);
  static const gray600 = Color(0xFF475467);
  static const gray500 = Color(0xFF667085);
  static const gray400 = Color(0xFF98A2B3);
  static const gray300 = Color(0xFFD0D5DD);
  static const gray200 = Color(0xFFE4E7EC);
  static const gray100 = Color(0xFFF2F4F7);
  static const gray50 = Color(0xFFF9FAFB);
  static const gray25 = Color(0xFFFCFCFD);

  static const error900 = Color(0xFF7A092B);
  static const error800 = Color(0xFF930F2C);
  static const error700 = Color(0xFFB7192E);
  static const error600 = Color(0xFFDB242D);
  static const error500 = Color(0xFFFF3932);
  static const error400 = Color(0xFFFF7765);
  static const error300 = Color(0xFFFF9D83);
  static const error200 = Color(0xFFFFC4AD);
  static const error100 = Color(0xFFFFE5D6);
  static const error50 = Color(0xFFFFF4EF);
  static const error25 = Color(0xFFFFFCEA);

  static const warning900 = Color(0xFF7A2E0E);
  static const warning800 = Color(0xFF93370D);
  static const warning700 = Color(0xFFB54708);
  static const warning600 = Color(0xFFDC6803);
  static const warning500 = Color(0xFFF79009);
  static const warning400 = Color(0xFFFDB022);
  static const warning300 = Color(0xFFFEC84B);
  static const warning200 = Color(0xFFFEDF89);
  static const warning100 = Color(0xFFFEF0C7);
  static const warning50 = Color(0xFFFFFAEB);
  static const warning25 = Color(0xFFFFFCE5);

  static const success900 = Color(0xFF145607);
  static const success800 = Color(0xFF21680C);
  static const success700 = Color(0xFF338213);
  static const success600 = Color(0xFF489B1C);
  static const success500 = Color(0xFF60B527);
  static const success400 = Color(0xFF8FD256);
  static const success300 = Color(0xFFB4E87B);
  static const success200 = Color(0xFFD6F7A9);
  static const success100 = Color(0xFFE6FBC7);
  static const success50 = Color(0xFFFFFAEB);
  static const success25 = Color(0xFFF9FFEF);

  static const orange900 = Color(0xFF7E2410);
  static const orange800 = Color(0xFF9C2A10);
  static const orange700 = Color(0xFFC4320A);
  static const orange600 = Color(0xFFEC4A0A);
  static const orange500 = Color(0xFFFB6514);
  static const orange400 = Color(0xFFFD853A);
  static const orange300 = Color(0xFFFEB273);
  static const orange200 = Color(0xFFFDDCAB);
  static const orange100 = Color(0xFFFFEAD5);
  static const orange50 = Color(0xFFFFF6ED);
  static const orange25 = Color(0xFFFFFAF5);

  static const purple900 = Color(0xFF3E1C96);
  static const purple800 = Color(0xFF4A1FB8);
  static const purple700 = Color(0xFF5925DC);
  static const purple600 = Color(0xFF6938EF);
  static const purple500 = Color(0xFF7A5AF8);
  static const purple400 = Color(0xFF9B8AFB);
  static const purple300 = Color(0xFFBDB4FE);
  static const purple200 = Color(0xFFD9D6FE);
  static const purple100 = Color(0xFFEBE9FE);
  static const purple50 = Color(0xFFF4F3FF);
  static const purple25 = Color(0xFFFAFAFF);

  static const seaGreen900 = Color(0xFF00525B);
  static const seaGreen800 = Color(0xFF016D6E);
  static const seaGreen700 = Color(0xFF02897D);
  static const seaGreen600 = Color(0xFF02A486);
  static const seaGreen500 = Color(0xFF04BF8A);
  static const seaGreen400 = Color(0xFF39D89C);
  static const seaGreen300 = Color(0xFF61EBA9);
  static const seaGreen200 = Color(0xFF97F8C0);
  static const seaGreen100 = Color(0xFFCAFEDA);
  static const seaGreen50 = Color(0xFFDFFFE3);
  static const seaGreen25 = Color(0xFFEAFEED);

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
