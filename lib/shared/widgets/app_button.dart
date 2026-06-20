import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum AppButtonVariant { primary, secondary }

enum AppButtonSize { small, medium, large }

class AppButton extends StatefulWidget {
  const AppButton.primary({
    required this.label,
    required this.onPressed,
    super.key,
    this.size = AppButtonSize.medium,
    this.icon,
    this.width,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    required this.label,
    required this.onPressed,
    super.key,
    this.size = AppButtonSize.medium,
    this.icon,
    this.width,
  }) : variant = AppButtonVariant.secondary;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? icon;
  final double? width;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  var _pressed = false;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final metrics = _AppButtonMetrics.fromVariantAndSize(
      widget.variant,
      widget.size,
    );
    final style = _AppButtonStyle.fromState(
      variant: widget.variant,
      size: widget.size,
      pressed: _enabled && _pressed,
      disabled: !_enabled,
    );
    final radius = BorderRadius.circular(metrics.radius);

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: MouseRegion(
        cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => _setPressed(true) : null,
          onTapUp: _enabled ? (_) => _setPressed(false) : null,
          onTapCancel: _enabled ? () => _setPressed(false) : null,
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            curve: Curves.easeOut,
            width: widget.width ?? metrics.width,
            height: metrics.height,
            padding: metrics.padding,
            decoration: BoxDecoration(
              color: style.backgroundColor,
              gradient: style.gradient,
              borderRadius: radius,
              border: style.border,
              boxShadow: style.boxShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  SizedBox(
                    width: metrics.iconWidth,
                    height: metrics.iconHeight,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: IconTheme.merge(
                        data: IconThemeData(color: style.foregroundColor),
                        child: widget.icon!,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: metrics.textStyle.copyWith(
                      color: style.foregroundColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setPressed(bool pressed) {
    if (_pressed == pressed) {
      return;
    }
    setState(() => _pressed = pressed);
  }
}

class _AppButtonMetrics {
  const _AppButtonMetrics({
    required this.width,
    required this.height,
    required this.radius,
    required this.padding,
    required this.textStyle,
    required this.iconWidth,
    required this.iconHeight,
  });

  final double width;
  final double height;
  final double radius;
  final EdgeInsetsGeometry padding;
  final TextStyle textStyle;
  final double iconWidth;
  final double iconHeight;

  static _AppButtonMetrics fromVariantAndSize(
    AppButtonVariant variant,
    AppButtonSize size,
  ) {
    final secondary = variant == AppButtonVariant.secondary;

    return switch (size) {
      AppButtonSize.small => _AppButtonMetrics(
        width: 110,
        height: 36,
        radius: 9999,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: secondary
            ? _ButtonTextStyles.bodyLargeBold
            : _ButtonTextStyles.bodyMediumBold,
        iconWidth: secondary ? 21 : 11,
        iconHeight: secondary ? 20 : 14,
      ),
      AppButtonSize.medium => _AppButtonMetrics(
        width: 146,
        height: 44,
        radius: 9999,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: _ButtonTextStyles.bodyLargeBold,
        iconWidth: secondary ? 21 : 11,
        iconHeight: secondary ? 20 : 14,
      ),
      AppButtonSize.large => _AppButtonMetrics(
        width: secondary ? 342 : 350,
        height: 52,
        radius: 24,
        padding: const EdgeInsets.all(16),
        textStyle: _ButtonTextStyles.bodyLargeBold,
        iconWidth: secondary ? 21 : 11,
        iconHeight: secondary ? 20 : 14,
      ),
    };
  }
}

abstract final class _ButtonTextStyles {
  static final bodyMediumBold = AppTypography.bodyMediumBold.copyWith(
    height: 20 / 14,
  );

  static final bodyLargeBold = AppTypography.bodyLargeBold.copyWith(
    height: 20 / 16,
  );
}

class _AppButtonStyle {
  const _AppButtonStyle({
    required this.foregroundColor,
    this.backgroundColor,
    this.gradient,
    this.border,
    this.boxShadow,
  });

  final Color foregroundColor;
  final Color? backgroundColor;
  final Gradient? gradient;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  static _AppButtonStyle fromState({
    required AppButtonVariant variant,
    required AppButtonSize size,
    required bool pressed,
    required bool disabled,
  }) {
    return switch (variant) {
      AppButtonVariant.primary => _primary(
        size: size,
        pressed: pressed,
        disabled: disabled,
      ),
      AppButtonVariant.secondary => _secondary(
        size: size,
        pressed: pressed,
        disabled: disabled,
      ),
    };
  }

  static _AppButtonStyle _primary({
    required AppButtonSize size,
    required bool pressed,
    required bool disabled,
  }) {
    final large = size == AppButtonSize.large;

    if (disabled) {
      return _AppButtonStyle(
        backgroundColor: AppColors.gray400,
        foregroundColor: large ? AppColors.gray300 : AppColors.surfaceWhite,
        boxShadow: large
            ? const [
                BoxShadow(
                  color: AppColors.overlayBlack18,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      );
    }

    if (pressed) {
      return const _AppButtonStyle(
        backgroundColor: AppColors.blue400,
        foregroundColor: AppColors.surfaceWhite,
      );
    }

    if (large) {
      return const _AppButtonStyle(
        foregroundColor: AppColors.surfaceWhite,
        gradient: LinearGradient(
          colors: [AppColors.blue500, AppColors.blue400, AppColors.blue500],
          stops: [0, 0.51442, 1],
        ),
        border: Border.fromBorderSide(BorderSide(color: AppColors.blue600)),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue700,
            blurRadius: 2,
            offset: Offset(0, 2),
          ),
        ],
      );
    }

    return const _AppButtonStyle(
      backgroundColor: AppColors.blue500,
      foregroundColor: AppColors.surfaceWhite,
    );
  }

  static _AppButtonStyle _secondary({
    required AppButtonSize size,
    required bool pressed,
    required bool disabled,
  }) {
    final large = size == AppButtonSize.large;

    if (disabled) {
      return const _AppButtonStyle(
        foregroundColor: AppColors.gray400,
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.gray400, width: 2),
        ),
      );
    }

    if (pressed) {
      return _AppButtonStyle(
        backgroundColor: large ? AppColors.blue25 : AppColors.gray25,
        foregroundColor: AppColors.blue500,
        border: Border.fromBorderSide(
          BorderSide(
            color: large ? AppColors.blue500 : AppColors.blue400,
            width: 2,
          ),
        ),
      );
    }

    return const _AppButtonStyle(
      backgroundColor: AppColors.surfaceWhite,
      foregroundColor: AppColors.blue500,
      border: Border.fromBorderSide(
        BorderSide(color: AppColors.blue500, width: 2),
      ),
    );
  }
}
