import 'dart:collection';

import '../models/story_page.dart';

class StoryPageMemoryCache {
  StoryPageMemoryCache({
    this.cacheDuration = const Duration(hours: 1),
    this.maximumEntries = 30,
    DateTime Function()? clock,
  }) : assert(maximumEntries > 0),
       _clock = clock ?? DateTime.now;

  final Duration cacheDuration;
  final int maximumEntries;
  final DateTime Function() _clock;
  final LinkedHashMap<String, _StoryPageCacheEntry> _entries = LinkedHashMap();

  List<StoryPage>? get(String storyId) {
    final entry = _entries.remove(storyId);
    if (entry == null) {
      return null;
    }

    if (!entry.expiresAt.isAfter(_clock())) {
      return null;
    }

    // Reinsert cache hits so the least recently used story stays first.
    _entries[storyId] = entry;
    return entry.pages;
  }

  void put(String storyId, List<StoryPage> pages) {
    _removeExpiredEntries();
    _entries.remove(storyId);

    while (_entries.length >= maximumEntries) {
      _entries.remove(_entries.keys.first);
    }

    _entries[storyId] = _StoryPageCacheEntry(
      pages: List<StoryPage>.unmodifiable(pages),
      expiresAt: _clock().add(cacheDuration),
    );
  }

  void clear() {
    _entries.clear();
  }

  void _removeExpiredEntries() {
    final now = _clock();
    _entries.removeWhere((_, entry) => !entry.expiresAt.isAfter(now));
  }
}

class _StoryPageCacheEntry {
  const _StoryPageCacheEntry({required this.pages, required this.expiresAt});

  final List<StoryPage> pages;
  final DateTime expiresAt;
}
