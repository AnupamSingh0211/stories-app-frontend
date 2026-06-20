import 'package:flutter/material.dart';

/// Figma typography tokens for the app design system.
///
/// These tokens are intentionally separate from [ThemeData] until the design
/// system migration is ready to wire them into app-wide text themes.
abstract final class AppTypography {
  static const fontFamily = 'PlusJakartaSans';

  static const displayRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    height: 1.2,
    letterSpacing: -0.8,
    fontWeight: FontWeight.w400,
  );
  static const displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    height: 1.2,
    letterSpacing: -0.8,
    fontWeight: FontWeight.w500,
  );
  static const displaySemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    height: 1.2,
    letterSpacing: -0.8,
    fontWeight: FontWeight.w600,
  );
  static const displayBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    height: 1.2,
    letterSpacing: -0.8,
    fontWeight: FontWeight.w700,
  );

  static const heading1Regular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    height: 1.25,
    letterSpacing: -0.64,
    fontWeight: FontWeight.w400,
  );
  static const heading1Medium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    height: 1.25,
    letterSpacing: -0.64,
    fontWeight: FontWeight.w500,
  );
  static const heading1SemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    height: 1.25,
    letterSpacing: -0.64,
    fontWeight: FontWeight.w600,
  );
  static const heading1Bold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    height: 1.25,
    letterSpacing: -0.64,
    fontWeight: FontWeight.w700,
  );

  static const heading2Regular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 1.2142857143,
    letterSpacing: -0.28,
    fontWeight: FontWeight.w400,
  );
  static const heading2Medium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 1.2142857143,
    letterSpacing: -0.28,
    fontWeight: FontWeight.w500,
  );
  static const heading2SemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 1.2142857143,
    letterSpacing: -0.28,
    fontWeight: FontWeight.w600,
  );
  static const heading2Bold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 1.2142857143,
    letterSpacing: -0.28,
    fontWeight: FontWeight.w700,
  );

  static const heading3Regular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 1.3333333333,
    letterSpacing: -0.24,
    fontWeight: FontWeight.w400,
  );
  static const heading3Medium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 1.3333333333,
    letterSpacing: -0.24,
    fontWeight: FontWeight.w500,
  );
  static const heading3SemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 1.3333333333,
    letterSpacing: -0.24,
    fontWeight: FontWeight.w600,
  );
  static const heading3Bold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 1.3333333333,
    letterSpacing: -0.24,
    fontWeight: FontWeight.w700,
  );

  static const titleRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );
  static const titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 1.5,
    fontWeight: FontWeight.w500,
  );
  static const titleSemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 1.5,
    fontWeight: FontWeight.w600,
  );
  static const titleBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 1.5,
    fontWeight: FontWeight.w700,
  );

  static const bodyLargeRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.625,
    fontWeight: FontWeight.w400,
  );
  static const bodyLargeMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.625,
    fontWeight: FontWeight.w500,
  );
  static const bodyLargeSemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.625,
    fontWeight: FontWeight.w600,
  );
  static const bodyLargeBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.625,
    fontWeight: FontWeight.w700,
  );

  static const bodyMediumRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.5714285714,
    fontWeight: FontWeight.w400,
  );
  static const bodyMediumMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.5714285714,
    fontWeight: FontWeight.w500,
  );
  static const bodyMediumSemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.5714285714,
    fontWeight: FontWeight.w600,
  );
  static const bodyMediumBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.5714285714,
    fontWeight: FontWeight.w700,
  );

  static const bodySmallRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );
  static const bodySmallMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.5,
    fontWeight: FontWeight.w500,
  );
  static const bodySmallSemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.5,
    fontWeight: FontWeight.w600,
  );
  static const bodySmallBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.5,
    fontWeight: FontWeight.w700,
  );

  static const labelRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.3333333333,
    fontWeight: FontWeight.w400,
  );
  static const labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.3333333333,
    fontWeight: FontWeight.w500,
  );
  static const labelSemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.3333333333,
    fontWeight: FontWeight.w600,
  );
  static const labelBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.3333333333,
    fontWeight: FontWeight.w700,
  );

  static const captionRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );
  static const captionMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );
  static const captionSemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    height: 1.4,
    fontWeight: FontWeight.w600,
  );
  static const captionBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    height: 1.4,
    fontWeight: FontWeight.w700,
  );

  static const buttonLargeRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );
  static const buttonLargeMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w500,
  );
  static const buttonLargeSemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w600,
  );
  static const buttonLargeBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w700,
  );

  static const buttonMediumRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.4285714286,
    fontWeight: FontWeight.w400,
  );
  static const buttonMediumMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.4285714286,
    fontWeight: FontWeight.w500,
  );
  static const buttonMediumSemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.4285714286,
    fontWeight: FontWeight.w600,
  );
  static const buttonMediumBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.4285714286,
    fontWeight: FontWeight.w700,
  );

  static const buttonSmallRegular = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.3333333333,
    fontWeight: FontWeight.w400,
  );
  static const buttonSmallMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.3333333333,
    fontWeight: FontWeight.w500,
  );
  static const buttonSmallSemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.3333333333,
    fontWeight: FontWeight.w600,
  );
  static const buttonSmallBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.3333333333,
    fontWeight: FontWeight.w700,
  );
}
