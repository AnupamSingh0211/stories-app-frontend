import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

class StoryImageCachePolicy {
  const StoryImageCachePolicy._();

  static const int maximumDecodeWidth = 2048;
  static const int _widthBucket = 128;

  static int widthFor({
    required double logicalWidth,
    required double devicePixelRatio,
  }) {
    if (!logicalWidth.isFinite ||
        logicalWidth <= 0 ||
        !devicePixelRatio.isFinite ||
        devicePixelRatio <= 0) {
      return _widthBucket;
    }

    final physicalWidth = (logicalWidth * devicePixelRatio).ceil();
    final bucketedWidth =
        ((physicalWidth + _widthBucket - 1) ~/ _widthBucket) * _widthBucket;
    return bucketedWidth.clamp(_widthBucket, maximumDecodeWidth);
  }

  static ImageProvider<Object> provider({
    required String imageUrl,
    required int cacheWidth,
  }) {
    final networkProvider = CachedNetworkImageProvider(
      imageUrl,
      maxWidth: cacheWidth,
    );
    return ResizeImage(
      networkProvider,
      width: cacheWidth,
      allowUpscaling: false,
    );
  }
}
