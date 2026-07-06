import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/performance/story_performance_metrics.dart';
import '../../../shared/theme/app_gradients.dart';
import 'story_image_cache_policy.dart';

class StoryImageView extends StatefulWidget {
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
  State<StoryImageView> createState() => _StoryImageViewState();
}

class _StoryImageViewState extends State<StoryImageView> {
  Stopwatch _renderStopwatch = Stopwatch();
  bool _hasRecordedRender = false;

  @override
  void initState() {
    super.initState();
    _restartRenderTimer();
  }

  @override
  void didUpdateWidget(StoryImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _restartRenderTimer();
    }
  }

  void _restartRenderTimer() {
    _hasRecordedRender = false;
    _renderStopwatch = Stopwatch();
    if (widget.imageUrl.isNotEmpty) {
      _renderStopwatch.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.isEmpty) {
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
        final cacheWidth = StoryImageCachePolicy.widthFor(
          logicalWidth: logicalWidth,
          devicePixelRatio: devicePixelRatio,
        );
        final alternateImageUrl = _alternateImageUrl(widget.imageUrl);

        return CachedNetworkImage(
          imageUrl: widget.imageUrl,
          imageBuilder: (context, imageProvider) =>
              _renderedImage(imageProvider, cacheWidth),
          fit: widget.fit,
          alignment: widget.alignment,
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
              imageBuilder: (context, imageProvider) =>
                  _renderedImage(imageProvider, cacheWidth),
              fit: widget.fit,
              alignment: widget.alignment,
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

  Widget _renderedImage(ImageProvider<Object> provider, int cacheWidth) {
    if (!_hasRecordedRender) {
      _hasRecordedRender = true;
      _renderStopwatch.stop();
      final metrics = StoryPerformanceMetrics.instance;
      metrics.recordDuration(
        metric: 'image_render',
        duration: _renderStopwatch.elapsed,
        attributes: {
          'cache_width': cacheWidth,
          'source_format': _imageExtension(widget.imageUrl),
        },
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        metrics.recordImageCacheSnapshot(reason: 'image_rendered');
      });
    }

    return Image(
      image: provider,
      fit: widget.fit,
      alignment: widget.alignment,
      width: double.infinity,
      height: double.infinity,
      filterQuality: FilterQuality.medium,
    );
  }

  String _imageExtension(String value) {
    final path = Uri.tryParse(value)?.path ?? value;
    final extensionIndex = path.lastIndexOf('.');
    return extensionIndex == -1
        ? 'unknown'
        : path.substring(extensionIndex + 1).toLowerCase();
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
