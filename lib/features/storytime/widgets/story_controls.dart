import 'package:flutter/material.dart';

import 'speed_button.dart';

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
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox.square(
          dimension: 48,
          child: IconButton.filledTonal(
            onPressed: isEnabled ? onToggleFavorite : null,
            icon: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
            ),
            color: isFavorite ? const Color(0xFFFF7597) : colors.onSurface,
          ),
        ),
        const SizedBox(width: 22),
        SizedBox.square(
          dimension: 72,
          child: FilledButton(
            onPressed: isEnabled ? onTogglePlayback : null,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: const Color(0xFF091026),
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 42,
            ),
          ),
        ),
        const SizedBox(width: 22),
        SpeedButton(
          speed: playbackSpeed,
          selected: true,
          onTap: isEnabled ? onChangeSpeed : null,
        ),
      ],
    );
  }
}
