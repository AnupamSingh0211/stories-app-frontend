import 'package:dharma_app/features/storytime/models/story_model.dart';
import 'package:dharma_app/features/storytime/providers/continue_listening_provider.dart';
import 'package:dharma_app/features/storytime/providers/story_player_provider.dart';
import 'package:dharma_app/features/storytime/screens/episodes_screen.dart';
import 'package:dharma_app/features/storytime/widgets/story_image_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget episodesApp({
    List<StoryModel> cmsStories = const [],
    StoryCardModel? storyCard = _storyCard,
    SessionStoryHistoryNotifier? historyNotifier,
  }) {
    return ProviderScope(
      overrides: [
        storyHistoryRepositoryProvider.overrideWithValue(
          InMemoryStoryHistoryRepository(),
        ),
        if (storyCard != null)
          storyCardStoriesProvider.overrideWith(
            (ref, storyCardId) async => cmsStories,
          ),
        if (historyNotifier != null)
          sessionStoryHistoryProvider.overrideWith((ref) => historyNotifier),
      ],
      child: MaterialApp(home: EpisodesScreen(storyCard: storyCard)),
    );
  }

  testWidgets('renders empty state without hardcoded episodes', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 868);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(episodesApp(cmsStories: const []));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('CMS Story Card'), findsOneWidget);
    expect(find.text('0 Episodes'), findsOneWidget);
    expect(find.text('No episodes available yet.'), findsOneWidget);
    expect(find.text('Makhan Ki Talaash'), findsNothing);
    expect(find.text('Makhan Chor Kanha'), findsNothing);
  });

  testWidgets('uses responsive hero and content width on wide screens', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(720, 1600);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(episodesApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final heroRect = tester.getRect(
      find.byKey(const ValueKey('episodesHeroBanner')),
    );
    final scale = 720 / 390;
    expect(heroRect.width, closeTo(359 * scale, 0.01));
    expect(heroRect.height, closeTo(202 * scale, 0.01));
    expect(heroRect.left, closeTo((720 - 359 * scale) / 2, 0.01));
    expect(
      tester.getTopLeft(find.text('Episodes')).dy,
      greaterThan(heroRect.bottom),
    );
  });

  testWidgets('places the back button below the status bar and pops', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 868);
    tester.view.padding = const FakeViewPadding(top: 36);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => tester.view.padding = FakeViewPadding.zero);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => ProviderScope(
                        overrides: [
                          storyHistoryRepositoryProvider.overrideWithValue(
                            InMemoryStoryHistoryRepository(),
                          ),
                          storyCardStoriesProvider.overrideWith(
                            (ref, storyCardId) async => const [],
                          ),
                        ],
                        child: const EpisodesScreen(storyCard: _storyCard),
                      ),
                    ),
                  );
                },
                child: const Text('Open episodes'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open episodes'));
    await tester.pumpAndSettle();

    final backRect = tester.getRect(find.bySemanticsLabel('Back'));
    expect(backRect.top, greaterThanOrEqualTo(36));

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Open episodes'), findsOneWidget);
    expect(find.byType(EpisodesScreen), findsNothing);
  });

  testWidgets('renders scoped CMS stories only', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 868);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      episodesApp(cmsStories: const [_cmsStory, _secondCmsStory]),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 Episodes'), findsOneWidget);
    expect(find.text('CMS Episode One'), findsOneWidget);
    expect(find.text('CMS Episode Two'), findsOneWidget);
    expect(find.text('Makhan Ki Talaash'), findsNothing);
    expect(find.byKey(const ValueKey('episode-stage-left-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('episode-stage-left-2')), findsOneWidget);

    final imageViews = tester.widgetList<StoryImageView>(
      find.byType(StoryImageView),
    );
    expect(
      imageViews.map((view) => view.imageUrl),
      contains(_cmsStory.thumbnailUrl),
    );
  });

  testWidgets('renders progress and completion on scoped CMS story', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 868);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const scope = StoryHistoryScope(userId: 'user-1', childProfileId: 'kid-1');
    final historyNotifier = _SeededHistoryNotifier(
      SessionStoryHistoryState(
        scope: scope,
        progressByStoryId: {
          _cmsStory.id: ContinueListeningEntry(
            story: _cmsStory,
            currentPageIndex: 0,
            pageCount: 1,
            audioPosition: const Duration(seconds: 20),
            audioDuration: const Duration(seconds: 60),
            updatedAt: DateTime.utc(2026, 8, 19),
          ),
        },
      ),
    );

    await tester.pumpWidget(
      episodesApp(
        cmsStories: const [_cmsStory],
        historyNotifier: historyNotifier,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('episode-stage-continuing-1')),
      findsOneWidget,
    );
    expect(find.text('CMS Episode One'), findsOneWidget);
    expect(find.text('1 min left'), findsOneWidget);

    historyNotifier.completeStory(_cmsStory.id);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('episode-stage-completed-1')),
      findsOneWidget,
    );
    expect(find.text('Watched'), findsOneWidget);
  });
}

const _storyCard = StoryCardModel(
  id: 'cms-card-1',
  title: 'CMS Story Card',
  thumbnailUrl: 'https://example.test/story-assets/cms-card.jpg',
  heroBannerUrl: 'https://example.test/story-assets/cms-card-hero.jpg',
  category: 'Story',
  sortOrder: 1,
);

const _cmsStory = StoryModel(
  id: 'cms-story-1',
  title: 'CMS Episode One',
  thumbnailUrl: 'https://example.test/story-assets/cms-story-1.jpg',
  category: 'Story',
  durationMinutes: 1,
  coverUrl: 'https://example.test/story-assets/cms-story-1-cover.jpg',
);

const _secondCmsStory = StoryModel(
  id: 'cms-story-2',
  title: 'CMS Episode Two',
  thumbnailUrl: 'https://example.test/story-assets/cms-story-2.jpg',
  category: 'Story',
  durationMinutes: 2,
  coverUrl: 'https://example.test/story-assets/cms-story-2-cover.jpg',
);

class _SeededHistoryNotifier extends SessionStoryHistoryNotifier {
  _SeededHistoryNotifier(SessionStoryHistoryState seededState)
    : super(InMemoryStoryHistoryRepository()) {
    state = seededState;
  }
}
