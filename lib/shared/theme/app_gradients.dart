import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppGradients {
  static const screenBackgroundBegin = Alignment(-0.7, -1.0023);
  static const screenBackgroundEnd = Alignment(2.319, -0.1336);
  static const screenBackgroundStops = [0.0618, 0.4562, 0.9382];
  static const screenBackgroundColors = [
    AppColors.backgroundGradientStart,
    AppColors.backgroundGradientMiddle,
    AppColors.backgroundGradientEnd,
  ];

  static const screenBackground = LinearGradient(
    begin: screenBackgroundBegin,
    end: screenBackgroundEnd,
    stops: screenBackgroundStops,
    colors: screenBackgroundColors,
  );

  static const background = LinearGradient(
    begin: screenBackgroundBegin,
    end: screenBackgroundEnd,
    stops: screenBackgroundStops,
    colors: screenBackgroundColors,
  );

  static const storytimeBackground = LinearGradient(
    begin: screenBackgroundBegin,
    end: screenBackgroundEnd,
    stops: screenBackgroundStops,
    colors: screenBackgroundColors,
  );

  static const authBackground = LinearGradient(
    begin: screenBackgroundBegin,
    end: screenBackgroundEnd,
    stops: screenBackgroundStops,
    colors: screenBackgroundColors,
  );

  static const authPurpleBackground = LinearGradient(
    begin: screenBackgroundBegin,
    end: screenBackgroundEnd,
    stops: screenBackgroundStops,
    colors: screenBackgroundColors,
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
