import 'package:flutter/material.dart';

class StoryTextCard extends StatelessWidget {
  const StoryTextCard({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF121936).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          text.isEmpty ? 'Story text will appear here.' : text,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.86),
            height: 1.58,
          ),
        ),
      ),
    );
  }
}
