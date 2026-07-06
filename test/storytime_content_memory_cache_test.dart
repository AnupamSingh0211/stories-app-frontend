import 'package:dharma_app/features/storytime/models/story_model.dart';
import 'package:dharma_app/features/storytime/repositories/storytime_content_memory_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final content = StorytimeContent.empty();

  test('reuses assembled Storytime content for fifteen minutes', () {
    var now = DateTime.utc(2026, 7, 6, 10);
    final cache = StorytimeContentMemoryCache(clock: () => now);

    cache.put(content);
    now = now.add(const Duration(minutes: 14, seconds: 59));

    expect(cache.get(), same(content));
  });

  test('expires assembled Storytime content at fifteen minutes', () {
    var now = DateTime.utc(2026, 7, 6, 10);
    final cache = StorytimeContentMemoryCache(clock: () => now);

    cache.put(content);
    now = now.add(const Duration(minutes: 15));

    expect(cache.get(), isNull);
  });

  test('supports explicit invalidation for a user refresh', () {
    final cache = StorytimeContentMemoryCache();

    cache.put(content);
    cache.clear();

    expect(cache.get(), isNull);
  });
}
