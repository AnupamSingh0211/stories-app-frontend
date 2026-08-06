import 'package:flutter_test/flutter_test.dart';

import 'package:dharma_app/features/storytime/models/story_model.dart';
import 'package:dharma_app/features/storytime/providers/continue_listening_provider.dart';

void main() {
  const firstScope = StoryHistoryScope(
    userId: 'user-1',
    childProfileId: 'child-1',
  );
  const secondScope = StoryHistoryScope(
    userId: 'user-1',
    childProfileId: 'child-2',
  );
  const storyA = StoryModel(
    id: 'story-a',
    title: 'Story A',
    thumbnailUrl: 'https://example.com/a.webp',
    category: 'Bedtime',
    durationMinutes: 5,
  );
  const storyB = StoryModel(
    id: 'story-b',
    title: 'Story B',
    thumbnailUrl: 'https://example.com/b.webp',
    category: 'Wisdom',
    durationMinutes: 7,
  );

  late SessionStoryHistoryNotifier notifier;

  setUp(() {
    notifier = SessionStoryHistoryNotifier(InMemoryStoryHistoryRepository())
      ..activateScope(firstScope);
  });

  tearDown(() {
    notifier.dispose();
  });

  test('orders recent stories newest first and removes duplicates', () {
    notifier.recordStory(storyA, playedAt: DateTime.utc(2026, 6, 27, 10));
    notifier.recordStory(storyB, playedAt: DateTime.utc(2026, 6, 27, 11));
    notifier.recordStory(storyA, playedAt: DateTime.utc(2026, 6, 27, 12));

    expect(notifier.state.recents.map((entry) => entry.story.id), [
      'story-a',
      'story-b',
    ]);
    expect(
      notifier.state.recents.first.lastPlayedAt,
      DateTime.utc(2026, 6, 27, 12),
    );
  });

  test('latest unfinished story becomes the Continue entry', () {
    notifier.saveProgress(
      story: storyA,
      currentPageIndex: 1,
      pageCount: 5,
      audioPosition: const Duration(seconds: 14),
    );
    notifier.saveProgress(
      story: storyB,
      currentPageIndex: 2,
      pageCount: 6,
      audioPosition: const Duration(seconds: 9),
    );

    final entry = notifier.state.continueListening;
    expect(entry?.story.id, 'story-b');
    expect(entry?.currentPageIndex, 2);
    expect(entry?.audioPosition, const Duration(seconds: 9));
    expect(entry?.progress, closeTo(0.5, 0.001));
  });

  test('completion removes Continue but preserves Recents', () {
    notifier.saveProgress(story: storyA, currentPageIndex: 3, pageCount: 5);

    notifier.completeStory(storyA.id);

    expect(notifier.state.continueListening, isNull);
    expect(notifier.state.progressForStory(storyA.id), isNull);
    expect(notifier.state.isStoryCompleted(storyA.id), isTrue);
    expect(notifier.state.recents.single.story.id, storyA.id);
  });

  test('tracks unfinished progress per story', () {
    notifier.saveProgress(
      story: storyA,
      currentPageIndex: 0,
      pageCount: 1,
      audioPosition: const Duration(seconds: 15),
      audioDuration: const Duration(seconds: 60),
    );
    notifier.saveProgress(story: storyB, currentPageIndex: 1, pageCount: 4);

    expect(
      notifier.state.progressForStory(storyA.id)?.progress,
      closeTo(0.25, 0.001),
    );
    expect(
      notifier.state.progressForStory(storyB.id)?.progress,
      closeTo(0.5, 0.001),
    );
  });

  test('switching child profile clears session history', () {
    notifier.saveProgress(story: storyA, currentPageIndex: 1, pageCount: 5);

    notifier.activateScope(secondScope);

    expect(notifier.state.scope, secondScope);
    expect(notifier.state.recents, isEmpty);
    expect(notifier.state.continueListening, isNull);
  });

  test('reactivating the same scope does not clear ordinary state updates', () {
    notifier.recordStory(storyA);

    notifier.activateScope(firstScope);

    expect(notifier.state.recents.single.story.id, storyA.id);
  });

  test('a fresh in-memory repository starts with empty history', () {
    final freshNotifier = SessionStoryHistoryNotifier(
      InMemoryStoryHistoryRepository(),
    )..activateScope(firstScope);
    addTearDown(freshNotifier.dispose);

    expect(freshNotifier.state.recents, isEmpty);
    expect(freshNotifier.state.continueListening, isNull);
  });
}
