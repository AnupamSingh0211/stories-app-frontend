import 'package:flutter_test/flutter_test.dart';

import 'package:dharma_app/features/storytime/audio/background_music_resolver.dart';
import 'package:dharma_app/features/storytime/repositories/story_repository.dart';

void main() {
  test('returns story one background music for Kanha Ki Sunheri Subah', () {
    final asset = backgroundMusicAssetForStory(
      storyId: StoryRepository.morningWhispersStoryId,
      locale: 'en-IN',
    );

    expect(asset, commonStoryBackgroundMusicAsset);
  });

  test('returns story two background music for Kanha Ke Aane Ki Khabar', () {
    final asset = backgroundMusicAssetForStory(
      storyId: StoryRepository.arrivalNewsStoryId,
      locale: 'hi-IN',
    );

    expect(asset, commonStoryBackgroundMusicAsset);
  });

  test('unsupported locale still resolves known story safely', () {
    final asset = backgroundMusicAssetForStory(
      storyId: StoryRepository.morningWhispersStoryId,
      locale: 'fr-FR',
    );

    expect(asset, commonStoryBackgroundMusicAsset);
  });

  test('unknown story has no background music asset', () {
    final asset = backgroundMusicAssetForStory(
      storyId: 'unknown-story',
      locale: 'en-IN',
    );

    expect(asset, isNull);
  });
}
