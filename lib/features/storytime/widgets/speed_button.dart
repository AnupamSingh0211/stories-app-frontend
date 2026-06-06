import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';

class SpeedButton extends StatelessWidget {
  const SpeedButton({
    required this.speed,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final double speed;
  final bool selected;
  final VoidCallback? onTap;

  String get _label {
    final rounded = speed.roundToDouble();
    return speed == rounded ? '${rounded.toInt()}x' : '${speed}x';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: selected ? AppColors.textOnAccent : colors.primary,
          backgroundColor: selected ? colors.primary : AppColors.transparent,
          side: BorderSide(
            color: selected
                ? colors.primary
                : colors.onSurface.withValues(alpha: 0.16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Text(_label),
      ),
    );
  }
}
