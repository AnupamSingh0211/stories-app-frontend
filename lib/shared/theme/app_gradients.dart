import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppGradients {
  static const background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.surfaceOverlay,
      AppColors.surfaceBase,
      AppColors.surfaceDark,
    ],
  );

  static const storytimeBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.surfaceCardDeep,
      AppColors.surfaceBase,
      AppColors.surfaceDeep,
    ],
  );

  static const authBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.authSurface,
      AppColors.surfaceBase,
      AppColors.authSurfaceDark,
    ],
  );

  static const authPurpleBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.authSurfacePurple,
      AppColors.surfaceBase,
      AppColors.authSurfaceDark,
    ],
  );

  static const heroCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.surfaceElevated,
      AppColors.surfaceCardDeep,
      AppColors.surfaceDark,
    ],
  );

  static const primaryButton = LinearGradient(
    colors: [AppColors.accentPrimarySoft, AppColors.accentPrimaryLight],
  );

  static const companion = LinearGradient(
    colors: [AppColors.emotionalWarmthLight, AppColors.accentLavender],
  );

  static const storyCoverFallback = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accentSecondaryDeep, AppColors.surfaceCardDeep],
  );

  static const imageFallback = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.surfaceImageFallback,
      AppColors.surfaceImageFallbackDark,
    ],
  );

  static const shimmer = LinearGradient(
    colors: [
      AppColors.surfaceWhite05,
      AppColors.surfaceWhite12,
      AppColors.surfaceWhite05,
    ],
  );

  static const featuredImageOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.transparent,
      AppColors.featuredOverlaySoft,
      AppColors.featuredOverlayStrong,
    ],
  );
}
