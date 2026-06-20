import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AppIconActionSize { small, medium }

class AppIconAction extends StatelessWidget {
  const AppIconAction({
    required this.icon,
    required this.onPressed,
    super.key,
    this.size = AppIconActionSize.small,
    this.selected = false,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final AppIconActionSize size;
  final bool selected;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final metrics = _AppIconActionMetrics.fromSize(size);
    final button = IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: metrics.iconSize,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(
        width: metrics.dimension,
        height: metrics.dimension,
      ),
      style: ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (!selected) {
            return AppColors.transparent;
          }
          if (states.contains(WidgetState.disabled)) {
            return AppColors.gray200;
          }
          if (states.contains(WidgetState.pressed)) {
            return AppColors.blue100;
          }
          return AppColors.blue50;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.gray400;
          }
          if (states.contains(WidgetState.pressed)) {
            return AppColors.blue400;
          }
          return selected ? AppColors.blue500 : AppColors.gray500;
        }),
        overlayColor: WidgetStateProperty.all(AppColors.transparent),
        shape: WidgetStateProperty.all(const CircleBorder()),
      ),
      icon: Icon(icon),
    );

    if (tooltip == null) {
      return button;
    }

    return Semantics(button: true, label: tooltip, child: button);
  }
}

class _AppIconActionMetrics {
  const _AppIconActionMetrics({
    required this.dimension,
    required this.iconSize,
  });

  final double dimension;
  final double iconSize;

  static _AppIconActionMetrics fromSize(AppIconActionSize size) {
    return switch (size) {
      AppIconActionSize.small => const _AppIconActionMetrics(
        dimension: 32,
        iconSize: 18,
      ),
      AppIconActionSize.medium => const _AppIconActionMetrics(
        dimension: 40,
        iconSize: 22,
      ),
    };
  }
}
