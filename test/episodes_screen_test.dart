import 'package:dharma_app/features/storytime/models/story_model.dart';
import 'package:dharma_app/features/storytime/providers/story_player_provider.dart';
import 'package:dharma_app/features/storytime/screens/episodes_screen.dart';
import 'package:dharma_app/features/storytime/widgets/story_image_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String assetUrl(String bucket, String path) {
    return 'https://example.test/$bucket/$path';
  }

  Widget episodesApp({List<StoryModel> cmsStories = const []}) {
    return ProviderScope(
      overrides: [
        cmsEpisodeStoriesProvider.overrideWith((ref) async => cmsStories),
      ],
      child: MaterialApp(home: EpisodesScreen(assetUrlBuilder: assetUrl)),
    );
  }

  testWidgets('renders the Figma episode titles and seven story images', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 868);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(episodesApp());
    await tester.pump();

    expect(tester.takeException(), isNull);

    expect(find.text('Shararati Krishna ke karname'), findsOneWidget);
    expect(find.text('7 Episodes'), findsOneWidget);
    expect(find.text('Makhan Ki Talaash'), findsOneWidget);
    expect(find.text('Makhan Chor Kanha'), findsOneWidget);
    expect(find.text('Meri Pyari Bachhiya'), findsOneWidget);
    expect(find.text('Bansuri Ki Dhun'), findsOneWidget);
    expect(find.text('Titliyon Ke Peeche'), findsOneWidget);
    expect(find.text('Barish Wali Masti'), findsOneWidget);
    expect(find.text('Vrindavan Ke Dost'), findsOneWidget);
    expect(find.text('Watched'), findsOneWidget);
    expect(find.text('1 min left'), findsOneWidget);

    final heroRect = tester.getRect(
      find.byKey(const ValueKey('episodesHeroBanner')),
    );
    expect(heroRect.size, const Size(359, 202));
    expect(
      tester.getTopLeft(find.text('Episodes')).dy,
      greaterThan(heroRect.bottom),
    );

    final imageViews = tester.widgetList<StoryImageView>(
      find.byType(StoryImageView),
    );
    expect(imageViews, hasLength(8));
    expect(
      imageViews.map((view) => view.imageUrl),
      contains(
        'https://example.test/app-assets/featured_banners/kanha ki sunheri subah.webp',
      ),
    );
    expect(
      imageViews.map((view) => view.imageUrl),
      containsAll(
        List.generate(
          7,
          (index) =>
              'https://example.test/story-assets/stories/kanha ki sunheri subah/images/page-${(index + 1).toString().padLeft(3, '0')}.webp',
        ),
      ),
    );
  });

  testWidgets('uses responsive hero and content width on wide screens', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(720, 1600);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(episodesApp());
    await tester.pump();

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
                          cmsEpisodeStoriesProvider.overrideWith(
                            (ref) async => const [],
                          ),
                        ],
                        child: EpisodesScreen(assetUrlBuilder: assetUrl),
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

  testWidgets('appends CMS stories from Supabase after legacy episodes', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 868);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const vasudevStory = StoryModel(
      id: 'c6c27045-8376-48ec-be6a-022470532a57',
      title: 'Vasudev ka vachan',
      thumbnailUrl: 'https://example.test/story-assets/vasudev.jpg',
      category: 'Story',
      durationMinutes: 1,
      coverUrl: 'https://example.test/story-assets/vasudev-cover.jpg',
    );

    await tester.pumpWidget(episodesApp(cmsStories: const [vasudevStory]));
    await tester.pump();

    expect(find.text('8 Episodes'), findsOneWidget);
    expect(find.text('Vasudev ka vachan'), findsOneWidget);
    expect(find.text('Vrindavan Ke Dost'), findsOneWidget);

    final imageViews = tester.widgetList<StoryImageView>(
      find.byType(StoryImageView),
    );
    expect(
      imageViews.map((view) => view.imageUrl),
      contains(vasudevStory.thumbnailUrl),
    );
  });
}
