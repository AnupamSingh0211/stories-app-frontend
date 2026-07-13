import 'package:flutter/material.dart';

/// Figma typography tokens for the app design system.
///
/// These tokens are intentionally separate from [ThemeData] until the design
/// system migration is ready to wire them into app-wide text themes.
abstract final class AppTypography {
  static const fontFamily = 'PlusJakartaSans';

  // ==========================================
  // Display Styles (Size: 36, Line Height: 40)
  // ==========================================
  static const displayRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    height: 40 / 36,
    letterSpacing: -0.5,
    fontWeight: FontWeight.w400,
  );
  static const displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    height: 40 / 36,
    letterSpacing: -0.5,
    fontWeight: FontWeight.w500,
  );
  static const displaySemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    height: 40 / 36,
    letterSpacing: -0.5,
    fontWeight: FontWeight.w600,
  );
  static const displayBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    height: 40 / 36,
    letterSpacing: -0.5,
    fontWeight: FontWeight.w700,
  );

  // ============================================
  // Heading 1 Styles (Size: 28, Line Height: 32)
  // ============================================
  static const heading1Regular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 32 / 28,
    letterSpacing: -0.5,
    fontWeight: FontWeight.w400,
  );
  static const heading1Medium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 32 / 28,
    letterSpacing: -0.5,
    fontWeight: FontWeight.w500,
  );
  static const heading1SemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 32 / 28,
    letterSpacing: -0.5,
    fontWeight: FontWeight.w600,
  );
  static const heading1Bold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 32 / 28,
    letterSpacing: -0.5,
    fontWeight: FontWeight.w700,
  );

  // ============================================
  // Heading 2 Styles (Size: 24, Line Height: 28)
  // ============================================
  static const heading2Regular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 28 / 24,
    letterSpacing: -0.25,
    fontWeight: FontWeight.w400,
  );
  static const heading2Medium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 28 / 24,
    letterSpacing: -0.25,
    fontWeight: FontWeight.w500,
  );
  static const heading2SemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 28 / 24,
    letterSpacing: -0.25,
    fontWeight: FontWeight.w600,
  );
  static const heading2Bold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 28 / 24,
    letterSpacing: -0.25,
    fontWeight: FontWeight.w700,
  );

  // ============================================
  // Heading 3 Styles (Size: 20, Line Height: 24)
  // ============================================
  static const heading3Regular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 24 / 20,
    letterSpacing: -0.25,
    fontWeight: FontWeight.w400,
  );
  static const heading3Medium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 24 / 20,
    letterSpacing: -0.25,
    fontWeight: FontWeight.w500,
  );
  static const heading3SemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 24 / 20,
    letterSpacing: -0.25,
    fontWeight: FontWeight.w600,
  );
  static const heading3Bold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 24 / 20,
    letterSpacing: -0.25,
    fontWeight: FontWeight.w700,
  );

  // =======================================
  // Title Styles (Size: 18, Line Height: 20 or 24)
  // =======================================
  static const titleRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 20 / 18,
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
  );
  static const titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 20 / 18,
    letterSpacing: 0,
    fontWeight: FontWeight.w500,
  );
  static const titleSemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 24 / 18, // Title/SB has line-height 24 in Figma dev node specs
    letterSpacing: 0,
    fontWeight: FontWeight.w600,
  );
  static const titleBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 20 / 18,
    letterSpacing: 0,
    fontWeight: FontWeight.w700,
  );

  // ============================================
  // Body Large Styles (Size: 16, Line Height: 20)
  // ============================================
  static const bodyLargeRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 20 / 16,
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
  );
  static const bodyLargeMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 20 / 16,
    letterSpacing: 0,
    fontWeight: FontWeight.w500,
  );
  static const bodyLargeSemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 20 / 16,
    letterSpacing: 0,
    fontWeight: FontWeight.w600,
  );
  static const bodyLargeBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 20 / 16,
    letterSpacing: 0,
    fontWeight: FontWeight.w700,
  );

  // ============================================
  // Body Medium Styles (Size: 14, Line Height: 20)
  // ============================================
  static const bodyMediumRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
  );
  static const bodyMediumMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0,
    fontWeight: FontWeight.w500,
  );
  static const bodyMediumSemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0,
    fontWeight: FontWeight.w600,
  );
  static const bodyMediumBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0,
    fontWeight: FontWeight.w700,
  );

  // ============================================
  // Body Small Styles (Size: 12, Line Height: 16)
  // ============================================
  static const bodySmallRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
  );
  static const bodySmallMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0,
    fontWeight: FontWeight.w500,
  );
  static const bodySmallSemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0,
    fontWeight: FontWeight.w600,
  );
  static const bodySmallBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0.5, // Body/Small/B has letterSpacing 0.5
    fontWeight: FontWeight.w700,
  );

  // =======================================
  // Label Styles (Size: 14, Line Height: 16)
  // =======================================
  static const labelRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 16 / 14,
    letterSpacing: 0.2,
    fontWeight: FontWeight.w400,
  );
  static const labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 16 / 14,
    letterSpacing: 0.2,
    fontWeight: FontWeight.w500,
  );
  static const labelSemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 16 / 14,
    letterSpacing: 0.2,
    fontWeight:
        FontWeight.w500, // Label/SB has weight 500 in Figma dev node specs
  );
  static const labelBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 16 / 14,
    letterSpacing: 0.2,
    fontWeight: FontWeight.w700,
  );

  // =========================================
  // Caption Styles (Size: 10, Line Height: 12)
  // =========================================
  static const captionRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    height: 12 / 10,
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
  );
  static const captionMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    height: 12 / 10,
    letterSpacing: 1, // Caption/M has letterSpacing 1
    fontWeight: FontWeight.w500,
  );
  static const captionSemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    height: 12 / 10,
    letterSpacing: 0,
    fontWeight: FontWeight.w600,
  );
  static const captionBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    height: 12 / 10,
    letterSpacing: 1, // Caption/B has letterSpacing 1
    fontWeight: FontWeight.w700,
  );

  // ==========================
  // Button Styles
  // ==========================
  static const buttonLargeRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 20 / 16,
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
  );
  static const buttonLargeMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 20 / 16,
    letterSpacing: 0,
    fontWeight: FontWeight.w500,
  );
  static const buttonLargeSemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 20 / 16,
    letterSpacing: 0,
    fontWeight: FontWeight.w600,
  );
  static const buttonLargeBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 20 / 16,
    letterSpacing: 0,
    fontWeight: FontWeight.w700,
  );

  static const buttonMediumRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
  );
  static const buttonMediumMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0,
    fontWeight: FontWeight.w500,
  );
  static const buttonMediumSemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0,
    fontWeight: FontWeight.w600,
  );
  static const buttonMediumBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0,
    fontWeight: FontWeight.w700,
  );

  static const buttonSmallRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w400,
  );
  static const buttonSmallMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w500,
  );
  static const buttonSmallSemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w600,
  );
  static const buttonSmallBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w700,
  );
}
