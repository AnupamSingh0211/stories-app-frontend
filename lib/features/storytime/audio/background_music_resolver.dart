import '../../auth/profile_repository.dart';
import '../repositories/story_repository.dart';

const storyBackgroundMusicVolume = 0.18;

const commonStoryBackgroundMusicAsset =
    'assets/audio/background/common_story_bg_track.mp3';

String? backgroundMusicAssetForStory({
  required String storyId,
  required String locale,
}) {
  final normalizedLocale = normalizeProfileLocale(locale);

  return switch ((storyId, normalizedLocale)) {
    (StoryRepository.morningWhispersStoryId, _) =>
      commonStoryBackgroundMusicAsset,
    (StoryRepository.arrivalNewsStoryId, _) => commonStoryBackgroundMusicAsset,
    _ => null,
  };
}
