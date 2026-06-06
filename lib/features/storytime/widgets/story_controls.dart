import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';

class StoryControls extends StatelessWidget {
  const StoryControls({
    required this.isPlaying,
    required this.isFavorite,
    required this.playbackSpeed,
    required this.isEnabled,
    required this.onTogglePlayback,
    required this.onToggleFavorite,
    required this.onChangeSpeed,
    super.key,
  });

  final bool isPlaying;
  final bool isFavorite;
  final double playbackSpeed;
  final bool isEnabled;
  final VoidCallback onTogglePlayback;
  final VoidCallback onToggleFavorite;
  final VoidCallback onChangeSpeed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ControlCircle(
          size: 54,
          backgroundColor: AppColors.playerSurface,
          onPressed: isEnabled ? onToggleFavorite : null,
          child: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite
                ? AppColors.playerPrimary
                : AppColors.playerDisabled,
            size: 27,
          ),
        ),
        const SizedBox(width: 30),
        _ControlCircle(
          size: 82,
          backgroundColor: AppColors.playerPrimary,
          onPressed: isEnabled ? onTogglePlayback : null,
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: AppColors.textPrimary,
            size: 48,
          ),
        ),
        const SizedBox(width: 30),
        _ControlCircle(
          size: 54,
          backgroundColor: AppColors.playerSurface,
          onPressed: isEnabled ? onChangeSpeed : null,
          child: Text(
            _speedLabel(playbackSpeed),
            style: const TextStyle(
              color: AppColors.playerGreen,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  String _speedLabel(double speed) {
    return '${speed.toStringAsFixed(1)}x';
  }
}

class _ControlCircle extends StatefulWidget {
  const _ControlCircle({
    required this.size,
    required this.backgroundColor,
    required this.onPressed,
    required this.child,
  });

  final double size;
  final Color backgroundColor;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  State<_ControlCircle> createState() => _ControlCircleState();
}

class _ControlCircleState extends State<_ControlCircle> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    return AnimatedScale(
      scale: _isPressed ? 0.94 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: enabled
              ? widget.backgroundColor
              : widget.backgroundColor.withValues(alpha: 0.45),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.playerShadow.withValues(
                alpha: enabled ? 0.18 : 0.06,
              ),
              blurRadius: widget.size > 70 ? 22 : 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: AppColors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onHighlightChanged: enabled
                ? (pressed) => setState(() => _isPressed = pressed)
                : null,
            onTap: widget.onPressed,
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}
