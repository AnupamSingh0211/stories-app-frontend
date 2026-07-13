import 'package:flutter/material.dart';

/// Semantic color tokens sourced from the Figma Dev Mode palette.
///
/// Legacy token names are kept where the app already consumes them, but their
/// values are aliases to colors present in the linked Figma node.
abstract final class AppColors {
  // Figma primitive palette: Blue 50-950.
  static const blue950 = Color(0xFF0A1F42);
  static const blue900 = Color(0xFF102F63);
  static const blue800 = Color(0xFF123F87);
  static const blue700 = Color(0xFF1554B0);
  static const blue600 = Color(0xFF1D6BD6);
  static const blue500 = Color(0xFF2D86EA);
  static const blue400 = Color(0xFF47A4F2);
  static const blue300 = Color(0xFF74C0F8);
  static const blue200 = Color(0xFFA8D8FB);
  static const blue100 = Color(0xFFD2EAFD);
  static const blue50 = Color(0xFFEAF5FE);
  static const blue25 = surfacePrimary;

  // Figma primitive palette: Neutral 0-950.
  static const neutral950 = Color(0xFF0B121A);
  static const neutral900 = Color(0xFF16202C);
  static const neutral800 = Color(0xFF232F3E);
  static const neutral700 = Color(0xFF374559);
  static const neutral600 = Color(0xFF4B5A6B);
  static const neutral500 = Color(0xFF6B7C8F);
  static const neutral400 = Color(0xFF9AAAB9);
  static const neutral300 = Color(0xFFCBD5E1);
  static const neutral200 = Color(0xFFE1E7EF);
  static const neutral100 = Color(0xFFEEF2F7);
  static const neutral50 = Color(0xFFF7F9FC);
  static const neutral0 = Color(0xFFFFFFFF);

  static const gray900 = neutral900;
  static const gray800 = neutral800;
  static const gray700 = neutral700;
  static const gray600 = neutral600;
  static const gray500 = neutral500;
  static const gray400 = neutral400;
  static const gray300 = neutral300;
  static const gray200 = neutral200;
  static const gray100 = neutral100;
  static const gray50 = neutral50;
  static const gray25 = surfacePrimary;

  // Figma semantic palette: Background.
  static const backgroundPrimary = Color(0xFF2D86EA);
  static const backgroundSecondary = Color(0xFF1D6BD6);
  static const backgroundElevated = Color(0xFF47A4F2);
  static const backgroundGlass = Color(0x2EFFFFFF);
  static const backgroundOverlay = Color(0x8C061428);
  static const backgroundHero = Color(0xFF3E8EF0);

  // Figma semantic palette: Text.
  static const textPrimary = Color(0xFF16202C);
  static const textSecondary = Color(0xFF3E4E60);
  static const textTertiary = Color(0xFF64748A);
  static const textPlaceholder = Color(0xFF8296AC);
  static const textDisabled = Color(0xFFA9BED6);
  static const textInverse = Color(0xFFFFFFFF);
  static const textOnPrimary = Color(0xFFFFFFFF);
  static const textOnGlass = Color(0xFF16202C);
  static const textOnAccent = textOnPrimary;
  static const textOnAccentSoft = textOnGlass;

  // Figma semantic palette: Surface.
  static const surfacePrimary = Color(0xFFF5FAFF);
  static const surfaceSecondary = Color(0xFFE8F2FC);
  static const surfaceElevated = Color(0xFFFBFEFF);
  static const surfaceCardBackground = Color(0xA6FFFFFF);
  static const surfaceSheetBackground = Color(0xD9FFFFFF);
  static const surfaceModalBackground = Color(0xFFFFFFFF);
  static const surfaceNavigationBackground = Color(0x8CFFFFFF);

  // Figma semantic palette: Glass.
  static const glassBackground = Color(0x38FFFFFF);
  static const glassSurface = Color(0x59FFFFFF);
  static const glassBorder = Color(0x8CFFFFFF);
  static const glassHighlight = Color(0xD9FFFFFF);
  static const glassReflection = Color(0xF2FFFFFF);
  static const glassShadow = Color(0x47081E3C);

  // Figma semantic palette: Border.
  static const borderLight = Color(0x59FFFFFF);
  static const borderDefault = Color(0xFFC7DEF5);
  static const borderStrong = Color(0xFF8FB8E6);
  static const borderGlass = Color(0x8CFFFFFF);
  static const borderFocus = Color(0x8C123F87);
  static const borderMedium = borderDefault;
  static const borderDark = borderFocus;

  // Figma semantic palette: Interactive.
  static const interactivePrimary = Color(0xFF1D6BD6);
  static const interactivePrimaryPressed = Color(0xFF123F87);
  static const interactiveSecondary = Color(0x8CFFFFFF);
  static const interactiveSecondaryPressed = Color(0xD9FFFFFF);
  static const interactiveHighlight = Color(0xFF123F87);
  static const interactiveFocusRing = Color(0x99FFFFFF);
  static const interactiveSelection = Color(0x402D86EA);

  // Figma status palettes.
  static const success900 = Color(0xFF0C3D2B);
  static const success800 = Color(0xFF105038);
  static const success700 = Color(0xFF146747);
  static const success600 = Color(0xFF1A8259);
  static const success500 = Color(0xFF22A06F);
  static const success400 = Color(0xFF3FB88C);
  static const success300 = Color(0xFF6ED2AC);
  static const success200 = Color(0xFFA6E8CB);
  static const success100 = Color(0xFFD2F5E5);
  static const success50 = Color(0xFFEAFBF3);
  static const success25 = success50;

  static const warning900 = Color(0xFF5C330C);
  static const warning800 = Color(0xFF79430F);
  static const warning700 = Color(0xFF9C5713);
  static const warning600 = Color(0xFFC36E17);
  static const warning500 = Color(0xFFE58A1F);
  static const warning400 = Color(0xFFF1A431);
  static const warning300 = Color(0xFFF9BE52);
  static const warning200 = Color(0xFFFCD988);
  static const warning100 = Color(0xFFFEECC4);
  static const warning50 = Color(0xFFFFF7E8);
  static const warning25 = warning50;

  static const error900 = Color(0xFF501A10);
  static const error800 = Color(0xFF6B2114);
  static const error700 = Color(0xFF8C2B19);
  static const error600 = Color(0xFFB0361F);
  static const error500 = Color(0xFFD14735);
  static const error400 = Color(0xFFE06456);
  static const error300 = Color(0xFFEC8B80);
  static const error200 = Color(0xFFF5B7B0);
  static const error100 = Color(0xFFFBDEDB);
  static const error50 = Color(0xFFFDF0EF);
  static const error25 = error50;

  static const info900 = Color(0xFF0B384F);
  static const info800 = Color(0xFF0E4A68);
  static const info700 = Color(0xFF125F86);
  static const info600 = Color(0xFF1678A8);
  static const info500 = Color(0xFF1D96CE);
  static const info400 = Color(0xFF38B2E4);
  static const info300 = Color(0xFF67CBF0);
  static const info200 = Color(0xFF9FE1F8);
  static const info100 = Color(0xFFCFF1FC);
  static const info50 = Color(0xFFEAF9FE);

  // Legacy family aliases used by existing screens.
  static const fuchsia900 = error900;
  static const fuchsia800 = error800;
  static const fuchsia700 = error700;
  static const fuchsia600 = error600;
  static const fuchsia500 = error500;
  static const fuchsia400 = error400;
  static const fuchsia300 = error300;
  static const fuchsia200 = error200;
  static const fuchsia100 = error100;
  static const fuchsia50 = error50;
  static const fuchsia25 = error25;

  static const orange900 = warning900;
  static const orange800 = warning800;
  static const orange700 = warning700;
  static const orange600 = warning600;
  static const orange500 = warning500;
  static const orange400 = warning400;
  static const orange300 = warning300;
  static const orange200 = warning200;
  static const orange100 = warning100;
  static const orange50 = warning50;
  static const orange25 = warning25;

  static const purple900 = blue900;
  static const purple800 = blue800;
  static const purple700 = blue700;
  static const purple600 = blue600;
  static const purple500 = blue500;
  static const purple400 = blue400;
  static const purple300 = blue300;
  static const purple200 = blue200;
  static const purple100 = blue100;
  static const purple50 = blue50;
  static const purple25 = blue25;

  static const seaGreen900 = success900;
  static const seaGreen800 = success800;
  static const seaGreen700 = success700;
  static const seaGreen600 = success600;
  static const seaGreen500 = success500;
  static const seaGreen400 = success400;
  static const seaGreen300 = success300;
  static const seaGreen200 = success200;
  static const seaGreen100 = success100;
  static const seaGreen50 = success50;
  static const seaGreen25 = success25;

  // Existing semantic aliases.
  static const surfaceBase = surfacePrimary;
  static const surfaceDark = backgroundSecondary;
  static const surfaceDeep = blue950;
  static const surfaceCard = surfaceCardBackground;
  static const surfaceCardDeep = backgroundPrimary;
  static const surfaceOverlay = backgroundOverlay;
  static const surfaceNavigation = surfaceNavigationBackground;
  static const surfaceImageFallback = backgroundHero;
  static const surfaceImageFallbackDark = blue800;
  static const surfaceInk = neutral950;
  static const surfaceBlack = neutral950;
  static const surfaceWhite = neutral0;
  static const transparent = Color(0x00000000);

  static const accentPrimary = interactivePrimary;
  static const accentPrimaryLight = blue400;
  static const accentPrimarySoft = blue100;
  static const accentPrimaryDim = interactivePrimaryPressed;
  static const accentSecondary = backgroundHero;
  static const accentSecondaryDeep = blue800;
  static const accentLavender = blue300;

  static const emotionalWarmth = warning300;
  static const emotionalWarmthBright = warning200;
  static const emotionalWarmthLight = warning100;
  static const emotionalWarmthSoft = warning50;
  static const successGreen = success500;
  static const warningOrange = warning500;
  static const attentionRed = error500;

  static const playerBackground = surfacePrimary;
  static const playerSurface = surfaceModalBackground;
  static const playerPrimary = error400;
  static const playerWarmGold = warning300;
  static const playerWarmGoldLight = warning200;
  static const playerPurple = blue800;
  static const playerPurpleMuted = blue600;
  static const playerPurpleDeep = blue950;
  static const playerText = textPrimary;
  static const playerTextSecondary = textSecondary;
  static const playerGreen = success500;
  static const playerDisabled = textDisabled;
  static const playerBorder = borderDefault;
  static const playerShadow = glassShadow;

  static const authSurface = backgroundPrimary;
  static const authSurfacePurple = backgroundSecondary;
  static const authSurfaceDark = blue950;
  static const companionBadgeSurface = backgroundOverlay;
  static const companionGold = warning300;
  static const companionGoldLight = warning100;

  static const lightSurfaceBase = surfacePrimary;
  static const lightSurfaceElevated = surfaceElevated;
  static const lightSurfaceCard = surfaceSecondary;
  static const lightTextPrimary = textPrimary;
  static const lightTextSecondary = textSecondary;
  static const lightTextTertiary = textTertiary;

  static const textHighEmphasis = textInverse;
  static const textMediumEmphasis = Color(0xA6FFFFFF);
  static const textLowEmphasis = Color(0x8CFFFFFF);
  static const surfaceWhite05 = backgroundGlass;
  static const surfaceWhite08 = backgroundGlass;
  static const surfaceWhite12 = backgroundGlass;
  static const surfaceWhite16 = backgroundGlass;
  static const surfaceWhite18 = backgroundGlass;
  static const overlayBlack18 = glassShadow;
  static const overlayBlack22 = glassShadow;
  static const overlayBlack24 = glassShadow;
  static const overlayBlack28 = glassShadow;
  static const overlayBlack46 = backgroundOverlay;
  static const overlayBlack62 = backgroundOverlay;
  static const featuredOverlaySoft = Color(0x47081E3C);
  static const featuredOverlayStrong = backgroundOverlay;
  static const playerShadowSoft = glassShadow;

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
