import 'package:dharma_app/features/storytime/screens/episodes_screen.dart';
import 'package:dharma_app/features/storytime/widgets/story_image_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String assetUrl(String bucket, String path) {
    return 'https://example.test/$bucket/$path';
  }

  testWidgets('renders the Figma episode titles and seven story images', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 868);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: EpisodesScreen(assetUrlBuilder: assetUrl)),
    );

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

    final imageViews = tester.widgetList<StoryImageView>(
      find.byType(StoryImageView),
    );
    expect(imageViews, hasLength(8));
    expect(
      imageViews.map((view) => view.imageUrl),
      contains('https://example.test/app-assets/featured_banners/kanha ki sunheri subah.webp'),
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

  testWidgets('uses the full mobile width instead of a centered fixed canvas', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(720, 1600);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: EpisodesScreen(assetUrlBuilder: assetUrl)),
    );

    final heroRect = tester.getRect(
      find
          .ancestor(
            of: find.text('Shararati Krishna ke karname'),
            matching: find.byType(Stack),
          )
          .first,
    );
    expect(heroRect.left, lessThan(40));
    expect(heroRect.width, greaterThan(650));
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
                      builder: (context) =>
                          EpisodesScreen(assetUrlBuilder: assetUrl),
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
}
