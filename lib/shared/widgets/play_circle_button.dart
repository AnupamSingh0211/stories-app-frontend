import 'package:flutter/material.dart';
import 'dart:ui';

class PlayCircleButton extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;

  const PlayCircleButton({super.key, this.size = 64.0, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2), // Translucent overlay
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Container(
                width: size * 0.4,
                height: size * 0.4,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: const Color(0xFF3D6A83),
                  size: size * 0.32,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
