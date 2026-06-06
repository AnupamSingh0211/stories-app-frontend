import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../shared/theme/app_gradients.dart';

class StoryImageView extends StatelessWidget {
  const StoryImageView({
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    super.key,
  });

  final String imageUrl;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return const _StoryImagePlaceholder(
        icon: Icons.image_not_supported_rounded,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
        final logicalWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final cacheWidth = (logicalWidth * devicePixelRatio).round();
        final alternateImageUrl = _alternateImageUrl(imageUrl);

        return CachedNetworkImage(
          imageUrl: imageUrl,
          fit: fit,
          alignment: alignment,
          width: double.infinity,
          height: double.infinity,
          memCacheWidth: cacheWidth,
          maxWidthDiskCache: cacheWidth,
          filterQuality: FilterQuality.medium,
          useOldImageOnUrlChange: true,
          fadeInDuration: const Duration(milliseconds: 180),
          fadeOutDuration: const Duration(milliseconds: 80),
          placeholder: (context, url) =>
              const _StoryImagePlaceholder(icon: Icons.nightlight_round),
          errorWidget: (context, url, error) {
            if (alternateImageUrl == null) {
              return const _StoryImagePlaceholder(
                icon: Icons.broken_image_rounded,
              );
            }

            return CachedNetworkImage(
              imageUrl: alternateImageUrl,
              fit: fit,
              alignment: alignment,
              width: double.infinity,
              height: double.infinity,
              memCacheWidth: cacheWidth,
              maxWidthDiskCache: cacheWidth,
              filterQuality: FilterQuality.medium,
              fadeInDuration: const Duration(milliseconds: 180),
              errorWidget: (context, url, error) =>
                  const _StoryImagePlaceholder(
                    icon: Icons.broken_image_rounded,
                  ),
            );
          },
        );
      },
    );
  }

  String? _alternateImageUrl(String value) {
    final webpPattern = RegExp(r'\.webp(?=($|[?#]))', caseSensitive: false);
    if (webpPattern.hasMatch(value)) {
      return value.replaceFirst(webpPattern, '.png');
    }

    final pngPattern = RegExp(r'\.png(?=($|[?#]))', caseSensitive: false);
    if (pngPattern.hasMatch(value)) {
      return value.replaceFirst(pngPattern, '.webp');
    }

    return null;
  }
}

class _StoryImagePlaceholder extends StatelessWidget {
  const _StoryImagePlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.imageFallback),
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
