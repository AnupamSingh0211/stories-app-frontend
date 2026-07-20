import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/story_model.dart';
import '../repositories/story_repository.dart';
import 'story_player_provider.dart';

class FavoriteStoriesNotifier extends StateNotifier<List<StoryModel>> {
  FavoriteStoriesNotifier(this._repository) : super(const []);

  final StoryRepository _repository;

  bool isFavorite(String storyId) {
    return state.any((story) => story.id == storyId);
  }

  Future<void> toggleStory(StoryModel story) async {
    if (isFavorite(story.id)) {
      await removeStory(story.id);
      return;
    }

    await addStory(story);
  }

  Future<void> addStory(StoryModel story) async {
    if (isFavorite(story.id)) return;

    state = [story, ...state];
    try {
      await _repository.addFavoriteStory(story.id);
    } catch (error) {
      debugPrint('FavoriteStoriesNotifier: backend add failed. $error');
    }
  }

  Future<void> removeStory(String storyId) async {
    final previous = state;
    state = [
      for (final story in state)
        if (story.id != storyId) story,
    ];
    try {
      await _repository.removeFavoriteStory(storyId);
    } catch (error) {
      debugPrint('FavoriteStoriesNotifier: backend remove failed. $error');
      state = previous;
    }
  }
}

final favoriteStoriesProvider =
    StateNotifierProvider<FavoriteStoriesNotifier, List<StoryModel>>((ref) {
      return FavoriteStoriesNotifier(ref.watch(storyRepositoryProvider));
    });
