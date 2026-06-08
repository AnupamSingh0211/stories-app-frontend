import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/story_model.dart';
import '../repositories/story_repository.dart';
import 'story_player_provider.dart';

enum SaveStoryResult { saved, alreadySaved, full }

class SavedLibraryState {
  const SavedLibraryState({
    this.stories = const [],
    this.savedCount = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<StoryModel> stories;
  final int savedCount;
  final bool isLoading;
  final String? errorMessage;

  SavedLibraryState copyWith({
    List<StoryModel>? stories,
    int? savedCount,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SavedLibraryState(
      stories: stories ?? this.stories,
      savedCount: savedCount ?? this.savedCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class SavedLibraryNotifier extends StateNotifier<SavedLibraryState> {
  SavedLibraryNotifier(this._repository) : super(const SavedLibraryState());

  final StoryRepository _repository;

  Future<void> loadLibrary() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final stories = await _repository.fetchSavedStories();
      state = state.copyWith(
        stories: stories,
        savedCount: stories.length,
        isLoading: false,
        clearError: true,
      );
    } on StoryRepositoryException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Saved stories could not be loaded.',
      );
    }
  }

  Future<SaveStoryResult> saveStory(String storyId) async {
    try {
      if (await _repository.isStorySaved(storyId)) {
        await loadLibrary();
        return SaveStoryResult.alreadySaved;
      }

      await _repository.saveStoryToLibrary(storyId);
      await loadLibrary();
      return SaveStoryResult.saved;
    } on StoryLibraryFullException {
      await loadLibrary();
      return SaveStoryResult.full;
    } on StoryRepositoryException catch (error) {
      state = state.copyWith(errorMessage: error.message);
      rethrow;
    }
  }

  Future<void> removeStory(String storyId) async {
    try {
      await _repository.removeSavedStory(storyId);
      await loadLibrary();
    } on StoryRepositoryException catch (error) {
      state = state.copyWith(errorMessage: error.message);
    }
  }
}

final savedLibraryProvider =
    StateNotifierProvider<SavedLibraryNotifier, SavedLibraryState>((ref) {
      return SavedLibraryNotifier(ref.watch(storyRepositoryProvider));
    });
