import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../models/story_page.dart';
import '../repositories/story_repository.dart';
import 'story_player_state.dart';

class StoryPlayerNotifier extends StateNotifier<StoryPlayerState> {
  StoryPlayerNotifier(this._repository, {required String storyId})
    : _storyId = storyId,
      super(StoryPlayerState.initial()) {
    _playerStateSubscription = _audioPlayer.playerStateStream.listen(
      _handlePlayerState,
      onError: (Object error) {
        _setError('Audio playback failed. Please try again.');
      },
    );
  }

  final StoryRepository _repository;
  final String _storyId;
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSubscription;
  bool _disposed = false;
  bool _isAdvancing = false;

  static const List<double> allowedSpeeds = [1, 1.25, 1.5, 1.75, 2];

  Future<void> loadStory() async {
    state = state.copyWith(
      isLoading: true,
      isPlaying: false,
      isComplete: false,
      clearError: true,
    );

    try {
      await _configureAudioSession();
      final results = await Future.wait<Object>([
        _repository.fetchStoryPagesFromStorage(),
        _repository.isFavoriteStory(_storyId),
      ]);
      final pages = results[0] as List<StoryPage>;
      final isFavorite = results[1] as bool;

      if (_disposed) {
        return;
      }

      state = state.copyWith(
        pages: pages,
        currentPageIndex: 0,
        isFavorite: isFavorite,
        playbackSpeed: 1,
        isLoading: false,
        isComplete: false,
        clearError: true,
      );

      await _audioPlayer.setSpeed(state.playbackSpeed);
      await _loadCurrentAudioAndPlay();
    } catch (error) {
      _setError(_friendlyError(error));
    }
  }

  Future<void> play() async {
    if (state.currentAudioUrl.isEmpty) {
      _setError('This page does not have audio yet.');
      return;
    }

    try {
      await _audioPlayer.play();
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

    state = state.copyWith(
      currentPageIndex: state.currentPageIndex + 1,
      isComplete: false,
      clearError: true,
    );
    await _loadCurrentAudioAndPlay();
  }

  Future<void> previousPage() async {
    if (!state.hasPreviousPage) {
      return;
    }

    state = state.copyWith(
      currentPageIndex: state.currentPageIndex - 1,
      isComplete: false,
      clearError: true,
    );
    await _loadCurrentAudioAndPlay();
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

  Future<void> disposePlayer() async {
    _disposed = true;
    await _playerStateSubscription?.cancel();
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

  Future<void> _loadCurrentAudioAndPlay() async {
    final audioUrl = state.currentAudioUrl;
    if (audioUrl.isEmpty) {
      _setError('This story page is missing audio.');
      return;
    }

    try {
      await _audioPlayer.stop();
      await _audioPlayer.setUrl(audioUrl);
      await _audioPlayer.setSpeed(state.playbackSpeed);
      await _audioPlayer.play();
      state = state.copyWith(isPlaying: true, clearError: true);
    } catch (error) {
      _setError('This story page could not be played. Please try again.');
    }
  }

  Future<void> _handlePlayerState(PlayerState playerState) async {
    if (_disposed) {
      return;
    }

    if (playerState.processingState == ProcessingState.completed) {
      if (_isAdvancing) {
        return;
      }

      _isAdvancing = true;
      await nextPage();
      _isAdvancing = false;
      return;
    }

    if (playerState.processingState == ProcessingState.ready) {
      state = state.copyWith(isPlaying: playerState.playing);
    }
  }

  Future<void> _finishStory() async {
    await _audioPlayer.stop();
    state = state.copyWith(isPlaying: false, isComplete: true);
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
