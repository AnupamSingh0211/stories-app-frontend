import 'package:boopi_app/features/storytime/models/story_model.dart';
import 'package:boopi_app/features/storytime/models/story_page.dart';
import 'package:boopi_app/features/storytime/repositories/story_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const story = StoryModel(
    id: 'story-1',
    title: 'Cached Story',
    thumbnailUrl: 'https://example.supabase.co/cover.webp',
    category: 'Bedtime',
    durationMinutes: 4,
  );
  const pages = [
    StoryPage(
      pageNumber: 1,
      imageUrl: 'https://example.supabase.co/page-1.webp',
      audioUrl: 'https://example.supabase.co/page-1.mp3',
      text: 'Page one',
    ),
  ];

  test(
    'reuses supplied story and page data without a Supabase query',
    () async {
      const repository = StoryRepository();

      final fullStory = await repository.fetchStoryWithPages(
        story.id,
        knownStory: story,
        knownPages: pages,
      );

      expect(fullStory.story, same(story));
      expect(fullStory.pages, pages);
    },
  );

  test('rejects metadata belonging to a different story', () async {
    const repository = StoryRepository();

    expect(
      () => repository.fetchStoryWithPages('another-story', knownStory: story),
      throwsA(isA<StoryRepositoryException>()),
    );
  });

  test('rejects supplied pages with missing asset URLs', () {
    const repository = StoryRepository();
    const invalidPages = [
      StoryPage(
        pageNumber: 1,
        imageUrl: '',
        audioUrl: 'https://example.supabase.co/page-1.mp3',
        text: 'Page one',
      ),
    ];

    expect(
      () => repository.cacheStoryPages(story.id, invalidPages),
      throwsA(isA<StoryRepositoryException>()),
    );
  });
}
