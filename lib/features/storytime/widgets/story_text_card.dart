import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../shared/theme/app_border_radius.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_shadows.dart';

class StoryTextCard extends StatelessWidget {
  const StoryTextCard({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppBorderRadius.panel,
        boxShadow: const [AppShadows.playerElevation],
      ),
      child: ClipRRect(
        borderRadius: AppBorderRadius.panel,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            constraints: const BoxConstraints(minHeight: 104, maxHeight: 184),
            decoration: BoxDecoration(
              color: AppColors.playerSurface.withValues(alpha: 0.85),
              borderRadius: AppBorderRadius.panel,
              border: Border.all(
                color: AppColors.playerSurface.withValues(alpha: 0.78),
              ),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Text(
                text.isEmpty ? 'कहानी का पाठ यहाँ दिखाई देगा।' : text,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.playerText,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
