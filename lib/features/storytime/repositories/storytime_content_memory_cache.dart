import '../models/story_model.dart';

class StorytimeContentMemoryCache {
  StorytimeContentMemoryCache({
    this.cacheDuration = const Duration(minutes: 15),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Duration cacheDuration;
  final DateTime Function() _clock;
  StorytimeContent? _content;
  DateTime? _expiresAt;

  StorytimeContent? get() {
    final expiresAt = _expiresAt;
    if (_content == null || expiresAt == null || !expiresAt.isAfter(_clock())) {
      clear();
      return null;
    }

    return _content;
  }

  void put(StorytimeContent content) {
    _content = content;
    _expiresAt = _clock().add(cacheDuration);
  }

  void clear() {
    _content = null;
    _expiresAt = null;
  }
}
