import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend_api_client.dart';
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
    this.audioDuration = Duration.zero,
    required this.updatedAt,
  });

  final StoryModel story;
  final int currentPageIndex;
  final int pageCount;
  final Duration audioPosition;
  final Duration audioDuration;
  final DateTime updatedAt;

  double get progress {
    if (pageCount <= 0) {
      return 0;
    }

    final rawPageProgress = audioDuration > Duration.zero
        ? audioPosition.inMilliseconds / audioDuration.inMilliseconds
        : 1.0;
    final pageProgress = rawPageProgress.clamp(0.0, 1.0).toDouble();
    return ((currentPageIndex + pageProgress) / pageCount)
        .clamp(0, 1)
        .toDouble();
  }
}

class StoryHistorySnapshot {
  const StoryHistorySnapshot({
    this.recents = const [],
    this.continueListening,
    this.progressByStoryId = const {},
    this.completedStoryIds = const {},
  });

  final List<RecentStoryEntry> recents;
  final ContinueListeningEntry? continueListening;
  final Map<String, ContinueListeningEntry> progressByStoryId;
  final Set<String> completedStoryIds;
}

abstract interface class StoryHistoryRepository {
  Future<StoryHistorySnapshot> read(StoryHistoryScope scope);

  Future<void> write(StoryHistoryScope scope, StoryHistorySnapshot snapshot);

  void clear();
}

class InMemoryStoryHistoryRepository implements StoryHistoryRepository {
  StoryHistorySnapshot _snapshot = const StoryHistorySnapshot();

  @override
  Future<StoryHistorySnapshot> read(StoryHistoryScope scope) async => _snapshot;

  @override
  Future<void> write(
    StoryHistoryScope scope,
    StoryHistorySnapshot snapshot,
  ) async {
    _snapshot = snapshot;
  }

  @override
  void clear() {
    _snapshot = const StoryHistorySnapshot();
  }
}

class BackendStoryHistoryRepository implements StoryHistoryRepository {
  BackendStoryHistoryRepository({required BackendApiClient apiClient})
    : _apiClient = apiClient;

  final BackendApiClient _apiClient;

  @override
  Future<StoryHistorySnapshot> read(StoryHistoryScope scope) async {
    final data = await _apiClient.getObject(
      '/api/v1/history',
      authenticated: true,
      queryParameters: {'profile_id': scope.childProfileId},
    );

    return _snapshotFromBackendMap(data);
  }

  @override
  Future<void> write(
    StoryHistoryScope scope,
    StoryHistorySnapshot snapshot,
  ) async {
    await _apiClient.postObject(
      '/api/v1/history/sync',
      authenticated: true,
      body: {
        'profile_id': scope.childProfileId,
        'recents': [
          for (final entry in snapshot.recents)
            {
              'story_id': entry.story.id,
              'last_played_at': entry.lastPlayedAt.toUtc().toIso8601String(),
            },
        ],
        'progress': [
          for (final entry in snapshot.progressByStoryId.values)
            {
              'story_id': entry.story.id,
              'current_page': entry.currentPageIndex + 1,
              'progress_seconds': entry.audioPosition.inSeconds,
              'completed_percentage': entry.progress * 100,
              'is_completed': false,
              'last_played_at': entry.updatedAt.toUtc().toIso8601String(),
            },
          for (final storyId in snapshot.completedStoryIds)
            {
              'story_id': storyId,
              'current_page': 1,
              'progress_seconds': 0,
              'completed_percentage': 100,
              'is_completed': true,
              'last_played_at': DateTime.now().toUtc().toIso8601String(),
            },
        ],
      },
    );
  }

  @override
  void clear() {}

  StoryHistorySnapshot _snapshotFromBackendMap(Map<String, dynamic> data) {
    final recents = _listOfMaps(
      data['recents'],
    ).map(_recentFromMap).whereType<RecentStoryEntry>().toList(growable: false);
    final progressEntries =
        _listOfMaps(
              data['progressByStoryId'] is Map
                  ? (data['progressByStoryId'] as Map).values.toList()
                  : const [],
            )
            .map(_continueFromMap)
            .whereType<ContinueListeningEntry>()
            .toList(growable: false);
    final continueEntry = data['continueListening'] is Map
        ? _continueFromMap(_stringKeyedMap(data['continueListening'] as Map))
        : null;
    final completedStoryIds = data['completedStoryIds'] is List
        ? (data['completedStoryIds'] as List)
              .map((value) => value.toString())
              .where((value) => value.isNotEmpty)
              .toSet()
        : <String>{};

    return StoryHistorySnapshot(
      recents: recents,
      continueListening: continueEntry,
      progressByStoryId: {
        for (final entry in progressEntries) entry.story.id: entry,
      },
      completedStoryIds: completedStoryIds,
    );
  }

  RecentStoryEntry? _recentFromMap(Map<String, dynamic> row) {
    final story = row['story'] is Map
        ? _storyFromMap(_stringKeyedMap(row['story'] as Map))
        : null;
    if (story == null) return null;

    return RecentStoryEntry(
      story: story,
      lastPlayedAt: _dateTimeValue(row['lastPlayedAt']) ?? DateTime.now(),
    );
  }

  ContinueListeningEntry? _continueFromMap(Map<String, dynamic> row) {
    final story = row['story'] is Map
        ? _storyFromMap(_stringKeyedMap(row['story'] as Map))
        : null;
    if (story == null) return null;

    return ContinueListeningEntry(
      story: story,
      currentPageIndex: _intValue(row['currentPageIndex']),
      pageCount: _intValue(row['pageCount']).clamp(1, 9999).toInt(),
      audioPosition: Duration(seconds: _intValue(row['audioPositionSeconds'])),
      audioDuration: Duration(seconds: _intValue(row['audioDurationSeconds'])),
      updatedAt: _dateTimeValue(row['updatedAt']) ?? DateTime.now(),
    );
  }

  StoryModel? _storyFromMap(Map<String, dynamic> row) {
    final id = row['id']?.toString() ?? '';
    if (id.isEmpty) return null;

    return StoryModel(
      id: id,
      title: _firstString(row, ['title'], fallback: 'Story'),
      thumbnailUrl: _firstString(row, [
        'thumbnailUrl',
        'thumbnail_url',
        'imageUrl',
        'image_url',
      ]),
      category: _firstString(row, ['category'], fallback: 'Story'),
      durationMinutes: _intValue(row['durationMinutes']),
      imageUrl: _nullableString(row['imageUrl'] ?? row['image_url']),
      coverUrl: _nullableString(row['coverUrl'] ?? row['cover_url']),
    );
  }

  List<Map<String, dynamic>> _listOfMaps(Object? rows) {
    if (rows is! List) return const [];

    return rows.whereType<Map>().map(_stringKeyedMap).toList(growable: false);
  }

  Map<String, dynamic> _stringKeyedMap(Map row) {
    return row.map((key, value) => MapEntry(key.toString(), value));
  }

  String _firstString(
    Map<String, dynamic> row,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = row[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }

    return fallback;
  }

  String? _nullableString(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value;
    return null;
  }

  int _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _dateTimeValue(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
  }
}

class SessionStoryHistoryState {
  const SessionStoryHistoryState({
    this.scope,
    this.recents = const [],
    this.continueListening,
    this.progressByStoryId = const {},
    this.completedStoryIds = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  final StoryHistoryScope? scope;
  final List<RecentStoryEntry> recents;
  final ContinueListeningEntry? continueListening;
  final Map<String, ContinueListeningEntry> progressByStoryId;
  final Set<String> completedStoryIds;
  final bool isLoading;
  final String? errorMessage;

  StoryHistorySnapshot get snapshot => StoryHistorySnapshot(
    recents: recents,
    continueListening: continueListening,
    progressByStoryId: progressByStoryId,
    completedStoryIds: completedStoryIds,
  );

  SessionStoryHistoryState copyWith({
    StoryHistoryScope? scope,
    List<RecentStoryEntry>? recents,
    ContinueListeningEntry? continueListening,
    Map<String, ContinueListeningEntry>? progressByStoryId,
    Set<String>? completedStoryIds,
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
      progressByStoryId: progressByStoryId ?? this.progressByStoryId,
      completedStoryIds: completedStoryIds ?? this.completedStoryIds,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  ContinueListeningEntry? progressForStory(String storyId) {
    return progressByStoryId[storyId];
  }

  bool isStoryCompleted(String storyId) {
    return completedStoryIds.contains(storyId);
  }
}

class SessionStoryHistoryNotifier
    extends StateNotifier<SessionStoryHistoryState> {
  SessionStoryHistoryNotifier(this._repository)
    : super(const SessionStoryHistoryState());

  final StoryHistoryRepository _repository;

  void activateScope(StoryHistoryScope? scope) {
    unawaited(_activateScope(scope));
  }

  Future<void> _activateScope(StoryHistoryScope? scope) async {
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
      _repository.clear();
      final snapshot = await _repository.read(scope);
      state = SessionStoryHistoryState(
        scope: scope,
        recents: List.unmodifiable(snapshot.recents),
        continueListening: snapshot.continueListening,
        progressByStoryId: Map.unmodifiable(snapshot.progressByStoryId),
        completedStoryIds: Set.unmodifiable(snapshot.completedStoryIds),
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
    Duration audioDuration = Duration.zero,
    DateTime? updatedAt,
  }) {
    if (state.scope == null || pageCount <= 0) {
      return;
    }

    final timestamp = updatedAt ?? DateTime.now();
    recordStory(story, playedAt: timestamp);
    final clampedIndex = currentPageIndex.clamp(0, pageCount - 1).toInt();
    final entry = ContinueListeningEntry(
      story: story,
      currentPageIndex: clampedIndex,
      pageCount: pageCount,
      audioPosition: audioPosition.isNegative ? Duration.zero : audioPosition,
      audioDuration: audioDuration.isNegative ? Duration.zero : audioDuration,
      updatedAt: timestamp,
    );
    final progressByStoryId = {...state.progressByStoryId, story.id: entry};
    final completedStoryIds = {...state.completedStoryIds}..remove(story.id);
    _commit(
      state.copyWith(
        continueListening: entry,
        progressByStoryId: Map.unmodifiable(progressByStoryId),
        completedStoryIds: Set.unmodifiable(completedStoryIds),
      ),
    );
  }

  void completeStory(String storyId) {
    final progressByStoryId = {...state.progressByStoryId}..remove(storyId);
    final completedStoryIds = {...state.completedStoryIds, storyId};
    _commit(
      state.copyWith(
        clearContinueListening: state.continueListening?.story.id == storyId,
        progressByStoryId: Map.unmodifiable(progressByStoryId),
        completedStoryIds: Set.unmodifiable(completedStoryIds),
      ),
    );
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
      state = next.copyWith(clearError: true);
      unawaited(
        _repository.write(scope, next.snapshot).catchError((_) {
          if (mounted) {
            state = state.copyWith(
              errorMessage: 'Your listening history could not be updated.',
            );
          }
        }),
      );
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
    Duration audioDuration = Duration.zero,
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
      audioDuration: audioDuration,
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
  (ref) => BackendStoryHistoryRepository(
    apiClient: ref.watch(backendApiClientProvider),
  ),
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
