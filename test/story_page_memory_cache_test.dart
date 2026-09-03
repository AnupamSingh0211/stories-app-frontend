import 'package:boopi_app/features/storytime/models/story_page.dart';
import 'package:boopi_app/features/storytime/repositories/story_page_memory_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const page = StoryPage(
    pageNumber: 1,
    imageUrl: 'https://example.supabase.co/story/page-1.webp',
    audioUrl: 'https://example.supabase.co/story/page-1.mp3',
    text: 'Page one',
  );

  test('keeps story metadata and asset URLs for the full cache duration', () {
    var now = DateTime.utc(2026, 7, 6, 10);
    final cache = StoryPageMemoryCache(clock: () => now);

    cache.put('story-1', const [page]);
    now = now.add(const Duration(minutes: 59));

    final cachedPages = cache.get('story-1');

    expect(cachedPages, const [page]);
    expect(cachedPages!.single.imageUrl, page.imageUrl);
    expect(cachedPages.single.audioUrl, page.audioUrl);
  });

  test('expires story page metadata after one hour', () {
    var now = DateTime.utc(2026, 7, 6, 10);
    final cache = StoryPageMemoryCache(clock: () => now);

    cache.put('story-1', const [page]);
    now = now.add(const Duration(hours: 1));

    expect(cache.get('story-1'), isNull);
  });

  test('evicts the least recently used story when capacity is reached', () {
    final cache = StoryPageMemoryCache(maximumEntries: 2);

    cache.put('story-1', const [page]);
    cache.put('story-2', const [page]);
    expect(cache.get('story-1'), isNotNull);

    cache.put('story-3', const [page]);

    expect(cache.get('story-1'), isNotNull);
    expect(cache.get('story-2'), isNull);
    expect(cache.get('story-3'), isNotNull);
  });

  test('stores an immutable page list', () {
    final cache = StoryPageMemoryCache();
    final pages = <StoryPage>[page];

    cache.put('story-1', pages);
    pages.clear();

    final cachedPages = cache.get('story-1');
    expect(cachedPages, const [page]);
    expect(() => cachedPages!.add(page), throwsUnsupportedError);
  });
}
