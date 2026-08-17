import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics_service.dart';
import '../models/story_model.dart';
import '../repositories/story_repository.dart';
import 'story_player_provider.dart';

class FavoriteStoriesNotifier extends StateNotifier<List<StoryModel>> {
  FavoriteStoriesNotifier(this._repository) : super(const []);

  final StoryRepository _repository;

  bool isFavorite(String storyId) {
    return state.any((story) => story.id == storyId);
  }

  Future<void> toggleStory(
    StoryModel story, {
    String source = 'story_card',
  }) async {
    if (isFavorite(story.id)) {
      await removeStory(story.id);
      return;
    }

    await addStory(story, source: source);
  }

  Future<void> addStory(
    StoryModel story, {
    String source = 'story_card',
  }) async {
    if (isFavorite(story.id)) return;

    state = [story, ...state];
    try {
      await _repository.addFavoriteStory(story.id);
    } catch (error) {
      debugPrint('FavoriteStoriesNotifier: backend add failed. $error');
    }
    await PostHogAnalytics.instance.capture(
      'story_favorited',
      properties: _favoriteAnalyticsProperties(story, source: source),
    );
  }

  Future<void> removeStory(String storyId) async {
    state = [
      for (final story in state)
        if (story.id != storyId) story,
    ];
    try {
      await _repository.removeFavoriteStory(storyId);
    } catch (error) {
      debugPrint('FavoriteStoriesNotifier: backend remove failed. $error');
    }
  }
}

final favoriteStoriesProvider =
    StateNotifierProvider<FavoriteStoriesNotifier, List<StoryModel>>((ref) {
      return FavoriteStoriesNotifier(ref.watch(storyRepositoryProvider));
    });

class FavoriteEpisodesNotifier extends StateNotifier<List<StoryModel>> {
  FavoriteEpisodesNotifier() : super(const []);

  bool isFavorite(String storyId) {
    return state.any((story) => story.id == storyId);
  }

  void toggleEpisode(StoryModel episode, {String source = 'episode_player'}) {
    if (isFavorite(episode.id)) {
      removeEpisode(episode.id);
      return;
    }

    addEpisode(episode, source: source);
  }

  void addEpisode(StoryModel episode, {String source = 'episode_player'}) {
    if (isFavorite(episode.id)) return;
    state = [episode, ...state];
    unawaited(
      PostHogAnalytics.instance.capture(
        'story_favorited',
        properties: _favoriteAnalyticsProperties(episode, source: source),
      ),
    );
  }

  void removeEpisode(String storyId) {
    state = [
      for (final story in state)
        if (story.id != storyId) story,
    ];
  }
}

final favoriteEpisodesProvider =
    StateNotifierProvider<FavoriteEpisodesNotifier, List<StoryModel>>((ref) {
      return FavoriteEpisodesNotifier();
    });

Map<String, Object?> _favoriteAnalyticsProperties(
  StoryModel story, {
  required String source,
}) {
  return {
    'source': source,
    'story_id': story.id,
    'story_title': story.title,
    'story_category': story.category,
    'duration_minutes': story.durationMinutes,
  };
}
