import 'package:just_audio/just_audio.dart';

abstract interface class StoryAudioPreloader {
  Future<void> preload(String audioUrl);

  Future<void> clear();

  Future<void> dispose();
}

class JustAudioStoryAudioPreloader implements StoryAudioPreloader {
  JustAudioStoryAudioPreloader({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  String? _preloadedUrl;
  int _loadGeneration = 0;
  bool _disposed = false;

  @override
  Future<void> preload(String audioUrl) async {
    if (_disposed || audioUrl.isEmpty || audioUrl == _preloadedUrl) {
      return;
    }

    final generation = ++_loadGeneration;
    try {
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(audioUrl)),
        preload: true,
      );
      if (!_disposed && generation == _loadGeneration) {
        _preloadedUrl = audioUrl;
      }
    } catch (_) {
      // Preloading is opportunistic and must never interrupt story playback.
    }
  }

  @override
  Future<void> clear() async {
    if (_disposed) {
      return;
    }

    ++_loadGeneration;
    _preloadedUrl = null;
    try {
      await _player.stop();
    } catch (_) {
      // Releasing a speculative preload should not affect active playback.
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    _disposed = true;
    ++_loadGeneration;
    await _player.dispose();
  }
}
