import 'package:dharma_app/features/storytime/models/story_model.dart';
import 'package:dharma_app/features/storytime/models/story_page.dart';
import 'package:dharma_app/features/storytime/notifiers/story_player_notifier.dart';
import 'package:dharma_app/features/storytime/notifiers/story_player_state.dart';
import 'package:dharma_app/features/storytime/providers/story_player_provider.dart';
import 'package:dharma_app/features/storytime/repositories/story_repository.dart';
import 'package:dharma_app/features/storytime/screens/story_player_screen.dart';
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

  testWidgets('story pages move vertically forward and backward', (
    tester,
  ) async {
    await pumpStory(tester);
    await tester.tap(find.text('Play Now'));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('story-vertical-feed')),
      const Offset(0, -520),
    );
    await tester.pumpAndSettle();
    expect(notifier.activations.last, 1);

    await tester.drag(
      find.byKey(const ValueKey('story-vertical-feed')),
      const Offset(0, 520),
    );
    await tester.pumpAndSettle();
    expect(notifier.activations.last, 0);
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

      expect(find.byKey(const ValueKey('story-page-1')), findsOneWidget);
      expect(notifier.activations, [1]);
    },
  );

  testWidgets('audio-driven page changes synchronize the vertical feed', (
    tester,
  ) async {
    await pumpStory(tester);
    await tester.tap(find.text('Play Now'));
    await tester.pumpAndSettle();

    notifier.simulateAudioAdvance(1);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('story-page-1')), findsOneWidget);
    expect(notifier.activations, [0]);
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
}

class _TestStoryPlayerNotifier extends StoryPlayerNotifier {
  _TestStoryPlayerNotifier({int initialPageIndex = 0})
    : super(const StoryRepository(), storyId: 'test-story') {
    state = StoryPlayerState(
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
      ],
      currentPageIndex: initialPageIndex,
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
}
