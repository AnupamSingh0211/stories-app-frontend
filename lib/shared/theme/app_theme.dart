import 'package:flutter/material.dart';

import 'app_border_radius.dart';
import 'app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static const _fontFamily = AppTypography.fontFamily;

  static final ThemeData darkTheme = _theme(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accentPrimaryLight,
      onPrimary: AppColors.textOnAccent,
      primaryContainer: AppColors.accentPrimary,
      onPrimaryContainer: AppColors.textPrimary,
      secondary: AppColors.accentSecondary,
      onSecondary: AppColors.textOnAccent,
      secondaryContainer: AppColors.surfaceElevated,
      onSecondaryContainer: AppColors.textPrimary,
      tertiary: AppColors.emotionalWarmth,
      onTertiary: AppColors.textOnAccent,
      error: AppColors.attentionRed,
      onError: AppColors.textPrimary,
      surface: AppColors.surfaceCard,
      onSurface: AppColors.textPrimary,
      outline: AppColors.textTertiary,
      outlineVariant: AppColors.borderMedium,
      shadow: AppColors.surfaceBlack,
      scrim: AppColors.overlayBlack62,
    ),
    scaffoldBackground: AppColors.surfaceBase,
  );

  static final ThemeData lightTheme = _theme(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.accentPrimary,
      onPrimary: AppColors.textPrimary,
      primaryContainer: AppColors.accentPrimaryLight,
      onPrimaryContainer: AppColors.lightTextPrimary,
      secondary: AppColors.accentSecondary,
      onSecondary: AppColors.lightTextPrimary,
      secondaryContainer: AppColors.lightSurfaceCard,
      onSecondaryContainer: AppColors.lightTextPrimary,
      tertiary: AppColors.emotionalWarmth,
      onTertiary: AppColors.lightTextPrimary,
      error: AppColors.attentionRed,
      onError: AppColors.textPrimary,
      surface: AppColors.lightSurfaceElevated,
      onSurface: AppColors.lightTextPrimary,
      outline: AppColors.lightTextTertiary,
      outlineVariant: AppColors.lightSurfaceCard,
      shadow: AppColors.surfaceBlack,
      scrim: AppColors.overlayBlack46,
    ),
    scaffoldBackground: AppColors.lightSurfaceBase,
  );

  static ThemeData _theme({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: _fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
    );

    final textTheme = base.textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
      fontFamily: _fontFamily,
    );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      canvasColor: scaffoldBackground,
      cardColor: colorScheme.surface,
      dividerColor: colorScheme.outlineVariant,
      disabledColor: colorScheme.onSurface.withValues(alpha: 0.38),
      splashColor: colorScheme.primary.withValues(alpha: 0.12),
      highlightColor: colorScheme.primary.withValues(alpha: 0.08),
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: AppColors.transparent,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppBorderRadius.card),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: AppColors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: AppBorderRadius.modal,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        modalBackgroundColor: colorScheme.surface,
        surfaceTintColor: AppColors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppBorderRadius.radiusPanel),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.54),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.card,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.card,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppBorderRadius.card,
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size.fromHeight(50),
          shape: const RoundedRectangleBorder(
            borderRadius: AppBorderRadius.button,
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outlineVariant),
          minimumSize: const Size.fromHeight(50),
          shape: const RoundedRectangleBorder(
            borderRadius: AppBorderRadius.button,
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.54),
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? colorScheme.onSurface
                : colorScheme.onSurface.withValues(alpha: 0.54),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.outlineVariant,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surface,
        surfaceTintColor: AppColors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: AppBorderRadius.panel,
        ),
        textStyle: TextStyle(color: colorScheme.onSurface),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surface,
        contentTextStyle: TextStyle(color: colorScheme.onSurface),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(AppBorderRadius.radiusSm),
          ),
        ),
      ),
    );
  }
}
