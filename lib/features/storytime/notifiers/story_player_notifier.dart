import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../repositories/story_repository.dart';
import 'story_player_state.dart';

class StoryPlayerNotifier extends StateNotifier<StoryPlayerState> {
  StoryPlayerNotifier(
    this._repository, {
    required String storyId,
    int initialPageIndex = 0,
    Duration initialAudioPosition = Duration.zero,
  }) : _storyId = storyId,
       _initialPageIndex = initialPageIndex,
       _initialAudioPosition = initialAudioPosition,
       super(StoryPlayerState.initial()) {
    _playerStateSubscription = _audioPlayer.playerStateStream.listen(
      _handlePlayerState,
      onError: (Object error) {
        _setError('Audio playback failed. Please try again.');
      },
    );
    _positionSubscription = _audioPlayer.positionStream.listen(_handlePosition);
    _durationSubscription = _audioPlayer.durationStream.listen(_handleDuration);
  }

  final StoryRepository _repository;
  final String _storyId;
  final int _initialPageIndex;
  final Duration _initialAudioPosition;
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  bool _disposed = false;
  bool _isPreparingPageAudio = false;
  int _audioLoadGeneration = 0;

  static const List<double> allowedSpeeds = [1, 1.25, 1.5, 1.75, 2];

  Future<void> loadStory() async {
    state = state.copyWith(
      isLoading: true,
      isPlaying: false,
      isComplete: false,
      clearError: true,
    );

    try {
      final pagesFuture = _repository.fetchStoryPages(_storyId);
      await _configureAudioSession();
      final pages = await pagesFuture;

      if (_disposed) {
        return;
      }

      final initialPageIndex = pages.isEmpty
          ? 0
          : _initialPageIndex.clamp(0, pages.length - 1).toInt();

      state = state.copyWith(
        pages: pages,
        currentPageIndex: initialPageIndex,
        playbackSpeed: 1,
        isLoading: true,
        isComplete: false,
        clearError: true,
      );

      await _audioPlayer.setSpeed(state.playbackSpeed);
      unawaited(_loadFavorite());
      await _loadPageAudio(
        initialPageIndex,
        autoPlay: false,
        initialPosition: _initialAudioPosition,
      );
      if (!_disposed) {
        state = state.copyWith(isLoading: false);
      }
    } catch (error) {
      _setError(_friendlyError(error));
    }
  }

  Future<void> play() async {
    if (state.isComplete) {
      await _loadPageAudio(0);
      return;
    }

    if (state.currentAudioUrl.isEmpty) {
      _setError('This page does not have audio yet.');
      return;
    }

    try {
      _startPlayback();
      state = state.copyWith(isPlaying: true, isComplete: false);
    } catch (error) {
      _setError('Audio could not start. Please try again.');
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      state = state.copyWith(isPlaying: false);
    } catch (error) {
      _setError('Audio could not pause. Please try again.');
    }
  }

  Future<void> nextPage() async {
    if (!state.hasNextPage) {
      await _finishStory();
      return;
    }

    await _seekToPage(state.currentPageIndex + 1);
  }

  Future<void> previousPage() async {
    if (!state.hasPreviousPage) {
      return;
    }

    await _seekToPage(state.currentPageIndex - 1);
  }

  Future<void> activatePage(
    int storyPageIndex, {
    required bool autoPlay,
  }) async {
    if (storyPageIndex < 0 || storyPageIndex >= state.pages.length) {
      return;
    }

    if (storyPageIndex == state.currentPageIndex && !_isPreparingPageAudio) {
      if (autoPlay && !state.isPlaying) {
        await play();
      } else if (!autoPlay && state.isPlaying) {
        await pause();
      }
      return;
    }

    if (storyPageIndex == state.currentPageIndex && _isPreparingPageAudio) {
      return;
    }

    await _loadPageAudio(storyPageIndex, autoPlay: autoPlay);
  }

  Future<void> toggleFavorite() async {
    final wasFavorite = state.isFavorite;
    state = state.copyWith(isFavorite: !wasFavorite, clearError: true);

    try {
      if (wasFavorite) {
        await _repository.removeFavoriteStory(_storyId);
      } else {
        await _repository.addFavoriteStory(_storyId);
      }
    } catch (error) {
      state = state.copyWith(
        isFavorite: wasFavorite,
        errorMessage: _friendlyError(error),
      );
    }
  }

  Future<void> changeSpeed() async {
    final currentIndex = allowedSpeeds.indexOf(state.playbackSpeed);
    final nextIndex = currentIndex == -1
        ? 0
        : (currentIndex + 1) % allowedSpeeds.length;
    final speed = allowedSpeeds[nextIndex];

    try {
      await _audioPlayer.setSpeed(speed);
      state = state.copyWith(playbackSpeed: speed);
    } catch (error) {
      _setError('Playback speed could not be changed.');
    }
  }

  Future<void> seekBy(Duration offset) async {
    final duration = state.audioDuration;
    final rawTarget = state.audioPosition + offset;
    final maxPosition = duration > Duration.zero ? duration : rawTarget;
    final target = rawTarget < Duration.zero
        ? Duration.zero
        : rawTarget > maxPosition
        ? maxPosition
        : rawTarget;

    try {
      await _audioPlayer.seek(target);
      state = state.copyWith(audioPosition: target);
    } catch (error) {
      _setError('The story could not seek to that position.');
    }
  }

  Future<void> seekTo(Duration position) async {
    final duration = state.audioDuration;
    final target = duration > Duration.zero && position > duration
        ? duration
        : position < Duration.zero
        ? Duration.zero
        : position;

    try {
      await _audioPlayer.seek(target);
      state = state.copyWith(audioPosition: target);
    } catch (error) {
      _setError('The story could not seek to that position.');
    }
  }

  Future<void> disposePlayer() async {
    _disposed = true;
    _audioLoadGeneration++;
    await _playerStateSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _audioPlayer.dispose();
  }

  @override
  void dispose() {
    unawaited(disposePlayer());
    super.dispose();
  }

  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    await session.setActive(true);
  }

  Future<void> _loadPageAudio(
    int pageIndex, {
    bool autoPlay = true,
    Duration initialPosition = Duration.zero,
  }) async {
    if (state.pages.isEmpty) {
      _setError('This story does not have any pages yet.');
      return;
    }
    if (pageIndex < 0 || pageIndex >= state.pages.length) {
      _setError('This story page is unavailable.');
      return;
    }

    final page = state.pages[pageIndex];
    if (page.audioUrl.isEmpty) {
      _setError('This story page is missing audio.');
      return;
    }

    final loadGeneration = ++_audioLoadGeneration;
    _isPreparingPageAudio = true;
    state = state.copyWith(
      currentPageIndex: pageIndex,
      audioPosition: Duration.zero,
      audioDuration: Duration.zero,
      isPlaying: false,
      isComplete: false,
      clearError: true,
    );

    try {
      await _audioPlayer.setAudioSource(
        AudioSource.uri(Uri.parse(page.audioUrl)),
      );

      if (_disposed || loadGeneration != _audioLoadGeneration) {
        return;
      }

      await _audioPlayer.setSpeed(state.playbackSpeed);
      if (initialPosition > Duration.zero) {
        final duration = _audioPlayer.duration;
        final safePosition = duration == null || initialPosition < duration
            ? initialPosition
            : Duration.zero;
        await _audioPlayer.seek(safePosition);
        state = state.copyWith(audioPosition: safePosition);
      }

      if (autoPlay) {
        _startPlayback();
      }
      state = state.copyWith(isPlaying: autoPlay, clearError: true);
    } catch (error) {
      if (_disposed || loadGeneration != _audioLoadGeneration) {
        return;
      }
      _setError('This story page could not be played. Please try again.');
    } finally {
      if (loadGeneration == _audioLoadGeneration) {
        _isPreparingPageAudio = false;
      }
    }
  }

  Future<void> _handlePlayerState(PlayerState playerState) async {
    if (_disposed) {
      return;
    }

    if (playerState.processingState == ProcessingState.completed &&
        !_isPreparingPageAudio) {
      if (state.hasNextPage) {
        await _loadPageAudio(state.currentPageIndex + 1);
      } else {
        await _finishStory();
      }
      return;
    }

    if (playerState.processingState == ProcessingState.ready) {
      state = state.copyWith(isPlaying: playerState.playing);
    }
  }

  void _handlePosition(Duration position) {
    if (_disposed || position == state.audioPosition) {
      return;
    }
    state = state.copyWith(audioPosition: position);
  }

  void _handleDuration(Duration? duration) {
    if (_disposed) {
      return;
    }
    state = state.copyWith(audioDuration: duration ?? Duration.zero);
  }

  Future<void> _seekToPage(int index) async {
    await _loadPageAudio(index);
  }

  void _startPlayback() {
    unawaited(
      _audioPlayer.play().catchError((Object error) {
        _setError('Audio could not start. Please try again.');
      }),
    );
  }

  Future<void> _loadFavorite() async {
    try {
      final isFavorite = await _repository.isFavoriteStory(_storyId);
      if (!_disposed) {
        state = state.copyWith(isFavorite: isFavorite);
      }
    } catch (error) {
      // Favorite status should not prevent story playback.
    }
  }

  Future<void> _finishStory() async {
    try {
      await _audioPlayer.pause();
      await _audioPlayer.seek(Duration.zero);
      state = state.copyWith(
        isPlaying: false,
        isComplete: true,
        clearError: true,
      );
    } catch (error) {
      _setError('The story could not return to the beginning.');
    }
  }

  void _setError(String message) {
    if (_disposed) {
      return;
    }

    state = state.copyWith(
      isLoading: false,
      isPlaying: false,
      errorMessage: message,
    );
  }

  String _friendlyError(Object error) {
    if (error is StoryRepositoryException) {
      return error.message;
    }

    return 'Story playback is unavailable right now. Please try again.';
  }
}
