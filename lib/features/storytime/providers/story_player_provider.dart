import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/story_model.dart';
import '../notifiers/story_player_notifier.dart';
import '../notifiers/story_player_state.dart';
import '../repositories/story_repository.dart';
import 'continue_listening_provider.dart';

final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return const StoryRepository();
});

final storytimeContentProvider = FutureProvider<StorytimeContent>((ref) {
  return ref.watch(storyRepositoryProvider).fetchStorytimeContent();
});

final storyPlayerProvider = StateNotifierProvider.autoDispose
    .family<StoryPlayerNotifier, StoryPlayerState, String>((ref, storyId) {
      final continueEntry = ref.read(continueListeningProvider);
      final initialPageIndex = continueEntry?.story.id == storyId
          ? continueEntry!.currentPageIndex
          : 0;
      final notifier = StoryPlayerNotifier(
        ref.watch(storyRepositoryProvider),
        storyId: storyId,
        initialPageIndex: initialPageIndex,
      );
      notifier.loadStory();
      return notifier;
    });
