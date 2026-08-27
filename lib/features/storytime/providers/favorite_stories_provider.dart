import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics_service.dart';
import '../../auth/profile_notifier.dart';
import '../models/story_model.dart';
import '../repositories/story_repository.dart';
import 'story_player_provider.dart';

class FavoriteStoriesNotifier extends StateNotifier<List<StoryModel>> {
  FavoriteStoriesNotifier(this._repository, {String? profileId})
    : _profileId = profileId,
      super(const []);

  final StoryRepository _repository;
  final String? _profileId;
  final Set<String> _pendingStoryIds = {};

  Future<void> loadStories() async {
    try {
      state = await _repository.fetchFavoriteStories(profileId: _profileId);
    } on StoryRepositoryException catch (error) {
      debugPrint('FavoriteStoriesNotifier: backend load failed. $error');
      state = const [];
    } catch (error) {
      debugPrint('FavoriteStoriesNotifier: backend load failed. $error');
      state = const [];
    }
  }

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
    if (isFavorite(story.id) || _pendingStoryIds.contains(story.id)) return;

    final previousState = state;
    _pendingStoryIds.add(story.id);
    state = [story, ...state];
    try {
      await _repository.addFavoriteStory(story.id, profileId: _profileId);
      await PostHogAnalytics.instance.capture(
        'story_favorited',
        properties: _favoriteAnalyticsProperties(story, source: source),
      );
    } on StoryRepositoryException catch (error) {
      state = previousState;
      debugPrint('FavoriteStoriesNotifier: backend add failed. $error');
      rethrow;
    } catch (error) {
      state = previousState;
      debugPrint('FavoriteStoriesNotifier: backend add failed. $error');
      throw const StoryRepositoryException(
        'Favorite could not be saved. Please try again.',
      );
    } finally {
      _pendingStoryIds.remove(story.id);
    }
  }

  Future<void> removeStory(String storyId) async {
    if (!isFavorite(storyId) || _pendingStoryIds.contains(storyId)) return;

    final previousState = state;
    _pendingStoryIds.add(storyId);
    state = [
      for (final story in state)
        if (story.id != storyId) story,
    ];
    try {
      await _repository.removeFavoriteStory(storyId, profileId: _profileId);
    } on StoryRepositoryException catch (error) {
      state = previousState;
      debugPrint('FavoriteStoriesNotifier: backend remove failed. $error');
      rethrow;
    } catch (error) {
      state = previousState;
      debugPrint('FavoriteStoriesNotifier: backend remove failed. $error');
      throw const StoryRepositoryException(
        'Favorite could not be removed. Please try again.',
      );
    } finally {
      _pendingStoryIds.remove(storyId);
    }
  }
}

class FavoriteStoryCardsNotifier extends StateNotifier<List<StoryCardModel>> {
  FavoriteStoryCardsNotifier(this._repository, {String? profileId})
    : _profileId = profileId,
      super(const []);

  final StoryRepository _repository;
  final String? _profileId;
  final Set<String> _pendingStoryCardIds = {};

  Future<void> loadStoryCards() async {
    try {
      state = await _repository.fetchFavoriteStoryCards(profileId: _profileId);
    } on StoryRepositoryException catch (error) {
      debugPrint('FavoriteStoryCardsNotifier: backend load failed. $error');
      state = const [];
    } catch (error) {
      debugPrint('FavoriteStoryCardsNotifier: backend load failed. $error');
      state = const [];
    }
  }

  bool isFavorite(String storyCardId) {
    return state.any((card) => card.id == storyCardId);
  }

  Future<void> toggleStoryCard(
    StoryCardModel storyCard, {
    String source = 'home_story_card',
  }) async {
    if (isFavorite(storyCard.id)) {
      await removeStoryCard(storyCard.id);
      return;
    }

    await addStoryCard(storyCard, source: source);
  }

  Future<void> addStoryCard(
    StoryCardModel storyCard, {
    String source = 'home_story_card',
  }) async {
    if (isFavorite(storyCard.id) ||
        _pendingStoryCardIds.contains(storyCard.id)) {
      return;
    }

    final previousState = state;
    _pendingStoryCardIds.add(storyCard.id);
    state = [storyCard, ...state];
    try {
      await _repository.addFavoriteStoryCard(
        storyCard.id,
        profileId: _profileId,
      );
      await PostHogAnalytics.instance.capture(
        'story_card_favorited',
        properties: _favoriteStoryCardAnalyticsProperties(
          storyCard,
          source: source,
        ),
      );
    } on StoryRepositoryException catch (error) {
      state = previousState;
      debugPrint('FavoriteStoryCardsNotifier: backend add failed. $error');
      rethrow;
    } catch (error) {
      state = previousState;
      debugPrint('FavoriteStoryCardsNotifier: backend add failed. $error');
      throw const StoryRepositoryException(
        'Favorite story card could not be saved. Please try again.',
      );
    } finally {
      _pendingStoryCardIds.remove(storyCard.id);
    }
  }

  Future<void> removeStoryCard(String storyCardId) async {
    if (!isFavorite(storyCardId) ||
        _pendingStoryCardIds.contains(storyCardId)) {
      return;
    }

    final previousState = state;
    _pendingStoryCardIds.add(storyCardId);
    state = [
      for (final card in state)
        if (card.id != storyCardId) card,
    ];
    try {
      await _repository.removeFavoriteStoryCard(
        storyCardId,
        profileId: _profileId,
      );
    } on StoryRepositoryException catch (error) {
      state = previousState;
      debugPrint('FavoriteStoryCardsNotifier: backend remove failed. $error');
      rethrow;
    } catch (error) {
      state = previousState;
      debugPrint('FavoriteStoryCardsNotifier: backend remove failed. $error');
      throw const StoryRepositoryException(
        'Favorite story card could not be removed. Please try again.',
      );
    } finally {
      _pendingStoryCardIds.remove(storyCardId);
    }
  }
}

final favoriteStoriesProvider =
    StateNotifierProvider<FavoriteStoriesNotifier, List<StoryModel>>((ref) {
      final profileId = ref.watch(
        profileNotifierProvider.select(
          (profiles) => profiles.valueOrNull?.selectedChild?.id,
        ),
      );
      final notifier = FavoriteStoriesNotifier(
        ref.watch(storyRepositoryProvider),
        profileId: profileId,
      );
      if (profileId != null) {
        unawaited(notifier.loadStories());
      }
      return notifier;
    });

final favoriteStoryCardsProvider =
    StateNotifierProvider<FavoriteStoryCardsNotifier, List<StoryCardModel>>((
      ref,
    ) {
      final profileId = ref.watch(
        profileNotifierProvider.select(
          (profiles) => profiles.valueOrNull?.selectedChild?.id,
        ),
      );
      final notifier = FavoriteStoryCardsNotifier(
        ref.watch(storyRepositoryProvider),
        profileId: profileId,
      );
      if (profileId != null) {
        unawaited(notifier.loadStoryCards());
      }
      return notifier;
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

Map<String, Object?> _favoriteStoryCardAnalyticsProperties(
  StoryCardModel storyCard, {
  required String source,
}) {
  return {
    'source': source,
    'story_card_id': storyCard.id,
    'story_card_title': storyCard.title,
    'story_card_category': storyCard.category,
  };
}
