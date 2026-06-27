import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_provider.dart';
import '../../auth/profile_notifier.dart';
import '../models/story_model.dart';

class StoryHistoryScope {
  const StoryHistoryScope({required this.userId, required this.childProfileId});

  final String userId;
  final String childProfileId;

  @override
  bool operator ==(Object other) {
    return other is StoryHistoryScope &&
        other.userId == userId &&
        other.childProfileId == childProfileId;
  }

  @override
  int get hashCode => Object.hash(userId, childProfileId);
}

class RecentStoryEntry {
  const RecentStoryEntry({required this.story, required this.lastPlayedAt});

  final StoryModel story;
  final DateTime lastPlayedAt;
}

class ContinueListeningEntry {
  const ContinueListeningEntry({
    required this.story,
    required this.currentPageIndex,
    required this.pageCount,
    this.audioPosition = Duration.zero,
    required this.updatedAt,
  });

  final StoryModel story;
  final int currentPageIndex;
  final int pageCount;
  final Duration audioPosition;
  final DateTime updatedAt;

  double get progress {
    if (pageCount <= 0) {
      return 0;
    }

    return ((currentPageIndex + 1) / pageCount).clamp(0, 1).toDouble();
  }
}

class StoryHistorySnapshot {
  const StoryHistorySnapshot({this.recents = const [], this.continueListening});

  final List<RecentStoryEntry> recents;
  final ContinueListeningEntry? continueListening;
}

abstract interface class StoryHistoryRepository {
  StoryHistorySnapshot read(StoryHistoryScope scope);

  void write(StoryHistoryScope scope, StoryHistorySnapshot snapshot);

  void clear();
}

class InMemoryStoryHistoryRepository implements StoryHistoryRepository {
  StoryHistorySnapshot _snapshot = const StoryHistorySnapshot();

  @override
  StoryHistorySnapshot read(StoryHistoryScope scope) => _snapshot;

  @override
  void write(StoryHistoryScope scope, StoryHistorySnapshot snapshot) {
    _snapshot = snapshot;
  }

  @override
  void clear() {
    _snapshot = const StoryHistorySnapshot();
  }
}

class SessionStoryHistoryState {
  const SessionStoryHistoryState({
    this.scope,
    this.recents = const [],
    this.continueListening,
    this.isLoading = false,
    this.errorMessage,
  });

  final StoryHistoryScope? scope;
  final List<RecentStoryEntry> recents;
  final ContinueListeningEntry? continueListening;
  final bool isLoading;
  final String? errorMessage;

  StoryHistorySnapshot get snapshot => StoryHistorySnapshot(
    recents: recents,
    continueListening: continueListening,
  );

  SessionStoryHistoryState copyWith({
    StoryHistoryScope? scope,
    List<RecentStoryEntry>? recents,
    ContinueListeningEntry? continueListening,
    bool clearContinueListening = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SessionStoryHistoryState(
      scope: scope ?? this.scope,
      recents: recents ?? this.recents,
      continueListening: clearContinueListening
          ? null
          : continueListening ?? this.continueListening,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class SessionStoryHistoryNotifier
    extends StateNotifier<SessionStoryHistoryState> {
  SessionStoryHistoryNotifier(this._repository)
    : super(const SessionStoryHistoryState());

  final StoryHistoryRepository _repository;

  void activateScope(StoryHistoryScope? scope) {
    if (state.scope == scope) {
      return;
    }

    if (scope == null) {
      _repository.clear();
      state = const SessionStoryHistoryState();
      return;
    }

    state = SessionStoryHistoryState(scope: scope, isLoading: true);
    try {
      // Session history deliberately starts empty for every user/profile change.
      _repository.clear();
      final snapshot = _repository.read(scope);
      state = SessionStoryHistoryState(
        scope: scope,
        recents: List.unmodifiable(snapshot.recents),
        continueListening: snapshot.continueListening,
      );
    } catch (_) {
      state = SessionStoryHistoryState(
        scope: scope,
        errorMessage: 'Your listening history could not be loaded.',
      );
    }
  }

  void recordStory(StoryModel story, {DateTime? playedAt}) {
    if (state.scope == null) {
      return;
    }

    final entry = RecentStoryEntry(
      story: story,
      lastPlayedAt: playedAt ?? DateTime.now(),
    );
    final recents = [
      entry,
      ...state.recents.where((item) => item.story.id != story.id),
    ];
    _commit(state.copyWith(recents: List.unmodifiable(recents)));
  }

  void saveProgress({
    required StoryModel story,
    required int currentPageIndex,
    required int pageCount,
    Duration audioPosition = Duration.zero,
    DateTime? updatedAt,
  }) {
    if (state.scope == null || pageCount <= 0) {
      return;
    }

    final timestamp = updatedAt ?? DateTime.now();
    recordStory(story, playedAt: timestamp);
    final clampedIndex = currentPageIndex.clamp(0, pageCount - 1).toInt();
    _commit(
      state.copyWith(
        continueListening: ContinueListeningEntry(
          story: story,
          currentPageIndex: clampedIndex,
          pageCount: pageCount,
          audioPosition: audioPosition.isNegative
              ? Duration.zero
              : audioPosition,
          updatedAt: timestamp,
        ),
      ),
    );
  }

  void completeStory(String storyId) {
    if (state.continueListening?.story.id != storyId) {
      return;
    }

    _commit(state.copyWith(clearContinueListening: true));
  }

  void clearSession() {
    _repository.clear();
    state = SessionStoryHistoryState(scope: state.scope);
  }

  void _commit(SessionStoryHistoryState next) {
    final scope = next.scope;
    if (scope == null) {
      return;
    }

    try {
      _repository.write(scope, next.snapshot);
      state = next.copyWith(clearError: true);
    } catch (_) {
      state = next.copyWith(
        errorMessage: 'Your listening history could not be updated.',
      );
    }
  }
}

/// Compatibility view for consumers that only need the current Continue item.
///
/// New writes should go through [SessionStoryHistoryNotifier], which owns both
/// Recents and Continue state as one replaceable repository boundary.
class ContinueListeningNotifier extends StateNotifier<ContinueListeningEntry?> {
  ContinueListeningNotifier() : super(null);

  void saveProgress({
    required StoryModel story,
    required int currentPageIndex,
    required int pageCount,
    Duration audioPosition = Duration.zero,
    DateTime? updatedAt,
  }) {
    if (pageCount <= 0) {
      return;
    }

    state = ContinueListeningEntry(
      story: story,
      currentPageIndex: currentPageIndex.clamp(0, pageCount - 1).toInt(),
      pageCount: pageCount,
      audioPosition: audioPosition,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  void clearStory(String storyId) {
    if (state?.story.id == storyId) {
      state = null;
    }
  }

  void syncFromHistory(ContinueListeningEntry? entry) {
    state = entry;
  }
}

final storyHistoryRepositoryProvider = Provider<StoryHistoryRepository>(
  (ref) => InMemoryStoryHistoryRepository(),
);

final storyHistoryScopeProvider = Provider<StoryHistoryScope?>((ref) {
  final userId = ref.watch(activeSessionProvider)?.userId;
  final childProfileId = ref
      .watch(profileNotifierProvider)
      .valueOrNull
      ?.selectedChild
      ?.id;
  if (userId == null || childProfileId == null) {
    return null;
  }

  return StoryHistoryScope(userId: userId, childProfileId: childProfileId);
});

final sessionStoryHistoryProvider =
    StateNotifierProvider<
      SessionStoryHistoryNotifier,
      SessionStoryHistoryState
    >((ref) {
      final notifier = SessionStoryHistoryNotifier(
        ref.watch(storyHistoryRepositoryProvider),
      );
      ref.listen<StoryHistoryScope?>(
        storyHistoryScopeProvider,
        (previous, next) => notifier.activateScope(next),
        fireImmediately: true,
      );
      return notifier;
    });

final continueListeningProvider =
    StateNotifierProvider<ContinueListeningNotifier, ContinueListeningEntry?>((
      ref,
    ) {
      final notifier = ContinueListeningNotifier();
      ref.listen<ContinueListeningEntry?>(
        sessionStoryHistoryProvider.select(
          (history) => history.continueListening,
        ),
        (previous, next) => notifier.syncFromHistory(next),
        fireImmediately: true,
      );
      return notifier;
    });
