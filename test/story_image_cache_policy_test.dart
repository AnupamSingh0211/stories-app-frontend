import 'package:dharma_app/features/storytime/widgets/story_image_cache_policy.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses physical pixels and stable width buckets', () {
    expect(
      StoryImageCachePolicy.widthFor(logicalWidth: 390, devicePixelRatio: 3),
      1280,
    );
    expect(
      StoryImageCachePolicy.widthFor(logicalWidth: 400, devicePixelRatio: 3),
      1280,
    );
  });

  test('caps large Chrome viewports to control decoded image memory', () {
    expect(
      StoryImageCachePolicy.widthFor(logicalWidth: 1920, devicePixelRatio: 2),
      StoryImageCachePolicy.maximumDecodeWidth,
    );
  });

  test('provides a safe fallback for invalid constraints', () {
    expect(
      StoryImageCachePolicy.widthFor(
        logicalWidth: double.infinity,
        devicePixelRatio: 1,
      ),
      128,
    );
  });

  test('preload provider uses the same bounded decode width', () {
    final provider = StoryImageCachePolicy.provider(
      imageUrl: 'https://example.supabase.co/page.webp',
      cacheWidth: 1024,
    );

    expect(provider, isA<ResizeImage>());
    expect((provider as ResizeImage).width, 1024);
    expect(provider.allowUpscaling, isFalse);
  });
}
