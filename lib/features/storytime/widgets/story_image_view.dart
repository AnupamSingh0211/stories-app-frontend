import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class StoryImageView extends StatelessWidget {
  const StoryImageView({required this.imageUrl, super.key});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return const _StoryImagePlaceholder(
        icon: Icons.image_not_supported_rounded,
      );
    }

    final mediaQuery = MediaQuery.of(context);
    final cacheWidth = (mediaQuery.size.width * mediaQuery.devicePixelRatio)
        .round();

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      memCacheWidth: cacheWidth,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (context, url) =>
          const _StoryImagePlaceholder(icon: Icons.nightlight_round),
      errorWidget: (context, url, error) =>
          const _StoryImagePlaceholder(icon: Icons.broken_image_rounded),
    );
  }
}

class _StoryImagePlaceholder extends StatelessWidget {
  const _StoryImagePlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF202A5F), Color(0xFF111832)],
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          color: colors.primary.withValues(alpha: 0.72),
          size: 42,
        ),
      ),
    );
  }
}
