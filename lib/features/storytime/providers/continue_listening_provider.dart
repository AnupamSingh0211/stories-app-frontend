import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/story_model.dart';

class ContinueListeningEntry {
  const ContinueListeningEntry({
    required this.story,
    required this.currentPageIndex,
    required this.pageCount,
    required this.updatedAt,
  });

  final StoryModel story;
  final int currentPageIndex;
  final int pageCount;
  final DateTime updatedAt;

  double get progress {
    if (pageCount <= 0) {
      return 0;
    }

    return (currentPageIndex / pageCount).clamp(0, 1).toDouble();
  }
}

class ContinueListeningNotifier extends StateNotifier<ContinueListeningEntry?> {
  ContinueListeningNotifier() : super(null);

  void saveProgress({
    required StoryModel story,
    required int currentPageIndex,
    required int pageCount,
    DateTime? updatedAt,
  }) {
    if (pageCount <= 0) {
      return;
    }

    final clampedIndex = currentPageIndex.clamp(0, pageCount - 1).toInt();
    state = ContinueListeningEntry(
      story: story,
      currentPageIndex: clampedIndex,
      pageCount: pageCount,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  void clearStory(String storyId) {
    if (state?.story.id == storyId) {
      state = null;
    }
  }
}

final continueListeningProvider =
    StateNotifierProvider<ContinueListeningNotifier, ContinueListeningEntry?>(
      (ref) => ContinueListeningNotifier(),
    );
