import 'package:flutter_test/flutter_test.dart';

import 'package:boopi_app/features/storytime/audio/background_music_resolver.dart';

void main() {
  test('returns common background music for CMS stories', () {
    final asset = backgroundMusicAssetForStory(
      storyId: 'cms-story-1',
      locale: 'en-IN',
    );

    expect(asset, commonStoryBackgroundMusicAsset);
  });

  test('unsupported locale still resolves safely', () {
    final asset = backgroundMusicAssetForStory(
      storyId: 'cms-story-1',
      locale: 'fr-FR',
    );

    expect(asset, commonStoryBackgroundMusicAsset);
  });

  test('blank story has no background music asset', () {
    final asset = backgroundMusicAssetForStory(storyId: '', locale: 'en-IN');

    expect(asset, isNull);
  });
}
