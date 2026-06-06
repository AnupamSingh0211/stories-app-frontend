import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppShadows {
  static const elevation1 = BoxShadow(
    color: AppColors.overlayBlack18,
    blurRadius: 12,
    offset: Offset(0, 6),
  );

  static const elevation2 = BoxShadow(
    color: AppColors.overlayBlack22,
    blurRadius: 20,
    offset: Offset(0, 10),
  );

  static const elevation3 = BoxShadow(
    color: AppColors.overlayBlack28,
    blurRadius: 28,
    offset: Offset(0, 16),
  );

  static const playerElevation = BoxShadow(
    color: AppColors.playerShadowSoft,
    blurRadius: 24,
    offset: Offset(0, 12),
  );

  static List<BoxShadow> glow(
    Color color, {
    double opacity = 0.2,
    double blurRadius = 24,
    double spreadRadius = 0,
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
      ),
    ];
  }
}
