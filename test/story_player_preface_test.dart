import 'package:dharma_app/features/storytime/models/story_model.dart';
import 'package:dharma_app/features/storytime/models/story_page.dart';
import 'package:dharma_app/features/storytime/audio/story_audio_preloader.dart';
import 'package:dharma_app/features/storytime/notifiers/story_player_notifier.dart';
import 'package:dharma_app/features/storytime/notifiers/story_player_state.dart';
import 'package:dharma_app/features/storytime/providers/story_player_provider.dart';
import 'package:dharma_app/features/storytime/repositories/story_repository.dart';
import 'package:dharma_app/features/storytime/screens/story_player_screen.dart';
import 'package:dharma_app/features/storytime/widgets/story_image_view.dart';
import 'package:dharma_app/features/storytime/widgets/story_player_content.dart';
import 'package:dharma_app/shared/widgets/app_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const story = StoryModel(
    id: '',
    title: 'Test Story',
    thumbnailUrl: '',
    category: 'Story',
    durationMinutes: 4,
  );

  late _TestStoryPlayerNotifier notifier;

  setUp(() {
    notifier = _TestStoryPlayerNotifier();
  });

  Future<void> pumpStory(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storyPlayerProvider.overrideWith((ref, storyId) => notifier),
        ],
        child: const MaterialApp(
          home: StoryPlayerScreen(
            storyId: '',
            title: 'Test Story',
            story: story,
          ),
        ),
      ),
    );
  }

  testWidgets('preface is feed index zero and Stories tab stays visible', (
    tester,
  ) async {
    await pumpStory(tester);

    expect(find.byKey(const ValueKey('story-vertical-feed')), findsOneWidget);
    expect(find.byKey(const ValueKey('story-detail-preface')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('story-detail-preface')),
        matching: find.text('Test Story'),
      ),
      findsOneWidget,
    );
    expect(find.text('4 min'), findsOneWidget);
    expect(find.text('Play Now'), findsOneWidget);
    expect(find.byType(AppPrimaryBottomNavigation), findsOneWidget);
    expect(notifier.state.isPlaying, isFalse);
  });

  testWidgets('direct episode player matches fixed Figma layout', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(453, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storyPlayerProvider.overrideWith((ref, storyId) => notifier),
        ],
        child: const MaterialApp(
          home: StoryPlayerScreen(
            storyId: '',
            title: 'Test Story',
            story: story,
            openDirectly: true,
            playerImageUrl:
                'https://example.test/story-assets/stories/kanha aur makhan/images/story_player_img.webp',
          ),
        ),
      ),
    );
    await tester.pump();

    final imageView = tester.widget<StoryImageView>(
      find.byType(StoryImageView),
    );
    expect(
      imageView.imageUrl,
      'https://example.test/story-assets/stories/kanha aur makhan/images/story_player_img.webp',
    );

    final imageRect = tester.getRect(find.byType(StoryImageView));
    final progressRect = tester.getRect(
      find.bySemanticsLabel('Story progress'),
    );
    final backRect = tester.getRect(find.bySemanticsLabel('Back'));
    expect(imageRect.size, const Size(421, 636));
    expect(imageRect.left, 16);
    expect(453 - imageRect.right, 16);
    expect(progressRect.top - imageRect.bottom, 22);
    expect(backRect.left, imageRect.left + 16);
    expect(backRect.bottom, lessThanOrEqualTo(imageRect.top));
    expect(find.text('Test Story'), findsNothing);
    expect(find.text('Text'), findsNothing);
    expect(find.byType(AppPrimaryBottomNavigation), findsNothing);
  });

  testWidgets('Play Now vertically activates the first story page', (
    tester,
  ) async {
    await pumpStory(tester);

    await tester.tap(find.text('Play Now'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('story-page-0')), findsOneWidget);
    expect(notifier.activations, [0]);
    expect(notifier.state.isPlaying, isTrue);
  });

  testWidgets('upward preface swipe performs the Play Now transition', (
    tester,
  ) async {
    await pumpStory(tester);

    await tester.drag(
      find.byKey(const ValueKey('story-detail-preface')),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('story-page-0')), findsOneWidget);
    expect(notifier.activations, [0]);
  });

  testWidgets('horizontal dragging does not change the feed page', (
    tester,
  ) async {
    await pumpStory(tester);

    await tester.drag(
      find.byKey(const ValueKey('story-detail-preface')),
      const Offset(-240, 0),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(notifier.activations, isEmpty);
    expect(find.text('Play Now'), findsOneWidget);
  });

  testWidgets('story pages flip horizontally forward and backward', (
    tester,
  ) async {
    await pumpStory(tester);
    await tester.tap(find.text('Play Now'));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('story-page-flip')),
      const Offset(-260, 0),
    );
    await tester.pumpAndSettle();
    expect(notifier.activations.last, 1);
    expect(find.text('Page two'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('story-page-flip')),
      const Offset(260, 0),
    );
    await tester.pumpAndSettle();
    expect(notifier.activations.last, 0);
    expect(find.text('Page one'), findsOneWidget);
  });

  testWidgets(
    'continue listening still opens preface then resumes saved page',
    (tester) async {
      notifier = _TestStoryPlayerNotifier(initialPageIndex: 1);
      await pumpStory(tester);

      expect(find.text('Play Now'), findsOneWidget);
      expect(notifier.state.isPlaying, isFalse);

      await tester.tap(find.text('Play Now'));
      await tester.pumpAndSettle();

      expect(find.text('Page two'), findsOneWidget);
      expect(notifier.activations, [1]);
    },
  );

  testWidgets('audio-driven page changes synchronize the page flip once', (
    tester,
  ) async {
    await pumpStory(tester);
    await tester.tap(find.text('Play Now'));
    await tester.pumpAndSettle();

    notifier.simulateAudioAdvance(1);
    await tester.pumpAndSettle();

    expect(find.text('Page two'), findsOneWidget);
    expect(notifier.activations, [0]);
  });

  testWidgets('audio position only rebuilds the active timeline', (
    tester,
  ) async {
    await pumpStory(tester);
    await tester.tap(find.text('Play Now'));
    await tester.pumpAndSettle();

    final firstPage = find.byKey(const ValueKey('story-page-0'));
    final imageFinder = find.descendant(
      of: firstPage,
      matching: find.byType(StoryImageView),
    );
    final imageBefore = tester.widget<StoryImageView>(imageFinder.first);

    notifier.simulateAudioPosition(const Duration(seconds: 5));
    await tester.pump();

    final imageAfter = tester.widget<StoryImageView>(imageFinder.first);
    expect(imageAfter, same(imageBefore));
    expect(find.text('0:05 / 1:00'), findsOneWidget);
  });

  testWidgets('restored page keeps playback controls interactive', (
    tester,
  ) async {
    notifier = _TestStoryPlayerNotifier(initialPageIndex: 1);
    await pumpStory(tester);
    await tester.tap(find.text('Play Now'));
    await tester.pumpAndSettle();

    expect(notifier.state.isPlaying, isTrue);
    await tester.tap(find.bySemanticsLabel('Pause story'));
    await tester.pump();

    expect(notifier.state.isPlaying, isFalse);
  });

  testWidgets('rapid audio changes settle on the authoritative page', (
    tester,
  ) async {
    notifier = _TestStoryPlayerNotifier(
      pages: const [
        StoryPage(
          pageNumber: 1,
          imageUrl: '',
          audioUrl: 'page-1.mp3',
          text: 'Page one',
        ),
        StoryPage(
          pageNumber: 2,
          imageUrl: '',
          audioUrl: 'page-2.mp3',
          text: 'Page two',
        ),
        StoryPage(
          pageNumber: 3,
          imageUrl: '',
          audioUrl: 'page-3.mp3',
          text: 'Page three',
        ),
      ],
    );
    await pumpStory(tester);
    await tester.tap(find.text('Play Now'));
    await tester.pumpAndSettle();

    notifier.simulateAudioAdvance(1);
    await tester.pump(const Duration(milliseconds: 50));
    notifier.simulateAudioAdvance(2);
    await tester.pumpAndSettle();

    expect(find.text('Page three'), findsOneWidget);
    expect(notifier.activations, [0]);
  });

  testWidgets('page flip mounts only the current and adjacent heavy pages', (
    tester,
  ) async {
    notifier = _TestStoryPlayerNotifier(
      pages: List<StoryPage>.generate(
        8,
        (index) => StoryPage(
          pageNumber: index + 1,
          imageUrl: '',
          audioUrl: 'page-${index + 1}.mp3',
          text: 'Page ${index + 1}',
        ),
      ),
    );
    await pumpStory(tester);
    await tester.tap(find.text('Play Now'));
    await tester.pumpAndSettle();

    expect(find.byType(StoryPlayerContent), findsNWidgets(2));

    notifier.simulateAudioAdvance(7);
    await tester.pumpAndSettle();

    expect(find.byType(StoryPlayerContent), findsOneWidget);
  });

  testWidgets('changed story data rebuilds the package page set', (
    tester,
  ) async {
    await pumpStory(tester);
    await tester.tap(find.text('Play Now'));
    await tester.pumpAndSettle();

    notifier.replacePages(const [
      StoryPage(
        pageNumber: 1,
        imageUrl: '',
        audioUrl: 'updated-page-1.mp3',
        text: 'Updated page one',
      ),
      StoryPage(
        pageNumber: 2,
        imageUrl: '',
        audioUrl: 'updated-page-2.mp3',
        text: 'Updated page two',
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Updated page one'), findsOneWidget);
    expect(find.text('Page one'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty story remains on the preface without errors', (
    tester,
  ) async {
    notifier = _TestStoryPlayerNotifier(pages: const []);
    await pumpStory(tester);

    await tester.tap(find.text('Play Now'));
    await tester.pump();

    expect(find.text('Play Now'), findsOneWidget);
    expect(find.byKey(const ValueKey('story-page-flip')), findsNothing);
    expect(notifier.activations, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('single-page story cannot flip beyond its bounds', (
    tester,
  ) async {
    notifier = _TestStoryPlayerNotifier(
      pages: const [
        StoryPage(
          pageNumber: 1,
          imageUrl: '',
          audioUrl: 'page-1.mp3',
          text: 'Only page',
        ),
      ],
    );
    await pumpStory(tester);
    await tester.tap(find.text('Play Now'));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('story-page-flip')),
      const Offset(-260, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Only page'), findsOneWidget);
    expect(notifier.activations, [0]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('final-page completion preserves the existing save prompt', (
    tester,
  ) async {
    notifier = _TestStoryPlayerNotifier(
      pages: const [
        StoryPage(
          pageNumber: 1,
          imageUrl: '',
          audioUrl: 'page-1.mp3',
          text: 'Only page',
        ),
      ],
    );
    await pumpStory(tester);
    await tester.tap(find.text('Play Now'));
    await tester.pumpAndSettle();

    notifier.simulateCompletion();
    await tester.pumpAndSettle();

    expect(find.text('Story finished'), findsOneWidget);
    expect(find.text('Keep this bedtime tale?'), findsOneWidget);
    expect(find.text('Only page'), findsOneWidget);
  });

  testWidgets('vertical feed does not overflow on a compact Android viewport', (
    tester,
  ) async {
    await pumpStory(tester, size: const Size(360, 740));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Play Now'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('story-page-0')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('preloads only the audio belonging to the next story page', () async {
    final preloader = _TestStoryAudioPreloader();
    final testNotifier = _TestStoryPlayerNotifier(audioPreloader: preloader);
    addTearDown(testNotifier.dispose);

    await testNotifier.preloadNextPageAudio();

    expect(preloader.preloadedUrls, ['page-2.mp3']);

    testNotifier.simulateAudioAdvance(1);
    await testNotifier.preloadNextPageAudio();

    expect(preloader.clearCount, 1);
  });
}

class _TestStoryPlayerNotifier extends StoryPlayerNotifier {
  _TestStoryPlayerNotifier({
    int initialPageIndex = 0,
    StoryAudioPreloader? audioPreloader,
    List<StoryPage> pages = const [
      StoryPage(
        pageNumber: 1,
        imageUrl: '',
        audioUrl: 'page-1.mp3',
        text: 'Page one',
      ),
      StoryPage(
        pageNumber: 2,
        imageUrl: '',
        audioUrl: 'page-2.mp3',
        text: 'Page two',
      ),
    ],
  }) : super(
         const StoryRepository(),
         storyId: 'test-story',
         audioPreloader: audioPreloader,
       ) {
    state = StoryPlayerState(
      pages: pages,
      currentPageIndex: pages.isEmpty
          ? 0
          : initialPageIndex.clamp(0, pages.length - 1),
      audioDuration: const Duration(minutes: 1),
    );
  }

  final List<int> activations = [];

  @override
  Future<void> activatePage(
    int storyPageIndex, {
    required bool autoPlay,
  }) async {
    activations.add(storyPageIndex);
    state = state.copyWith(
      currentPageIndex: storyPageIndex,
      isPlaying: autoPlay,
    );
  }

  @override
  Future<void> pause() async {
    state = state.copyWith(isPlaying: false);
  }

  void simulateAudioAdvance(int storyPageIndex) {
    state = state.copyWith(currentPageIndex: storyPageIndex, isPlaying: true);
  }

  void simulateAudioPosition(Duration position) {
    state = state.copyWith(audioPosition: position);
  }

  void replacePages(List<StoryPage> pages) {
    state = state.copyWith(
      pages: pages,
      currentPageIndex: pages.isEmpty
          ? 0
          : state.currentPageIndex.clamp(0, pages.length - 1),
    );
  }

  void simulateCompletion() {
    state = state.copyWith(isPlaying: false, isComplete: true);
  }
}

class _TestStoryAudioPreloader implements StoryAudioPreloader {
  final List<String> preloadedUrls = [];
  int clearCount = 0;

  @override
  Future<void> preload(String audioUrl) async {
    preloadedUrls.add(audioUrl);
  }

  @override
  Future<void> clear() async {
    clearCount++;
  }

  @override
  Future<void> dispose() async {}
}
