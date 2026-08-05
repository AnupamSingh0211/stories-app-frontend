import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dharma_app/features/auth/assets_provider.dart';
import 'package:dharma_app/features/auth/auth_provider.dart';
import 'package:dharma_app/features/auth/companion_model.dart';
import 'package:dharma_app/features/auth/companion_flow.dart';
import 'package:dharma_app/features/auth/companions_provider.dart';
import 'package:dharma_app/features/auth/choose_companion_screen.dart';
import 'package:dharma_app/features/auth/profile_notifier.dart';
import 'package:dharma_app/features/auth/profile_repository.dart';
import 'package:dharma_app/features/auth/profile_setup_screen.dart';
import 'package:dharma_app/features/auth/welcome_screen.dart';
import 'package:dharma_app/features/home/home_screen.dart';
import 'package:dharma_app/features/library/library_sections_screen.dart';
import 'package:dharma_app/features/profile/privacy_policy_screen.dart';
import 'package:dharma_app/features/profile/profile_screen.dart';
import 'package:dharma_app/features/storytime/models/story_model.dart';
import 'package:dharma_app/features/storytime/providers/continue_listening_provider.dart';
import 'package:dharma_app/features/storytime/providers/saved_library_provider.dart';
import 'package:dharma_app/features/storytime/providers/story_player_provider.dart';
import 'package:dharma_app/features/storytime/repositories/story_repository.dart';
import 'package:dharma_app/features/storytime/screens/episodes_screen.dart';
import 'package:dharma_app/features/storytime/screens/storytime_screen.dart';
import 'package:dharma_app/main.dart';
import 'package:dharma_app/shared/theme/app_theme.dart';

void main() {
  setUpAll(() async {
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-anon-key',
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        pkceAsyncStorage: _EmptyAsyncStorage(),
      ),
    );
  });

  testWidgets('shows welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith((ref) => Stream.value(null)),
          appAssetsProvider.overrideWithValue({
            'welcome_bg(1)': 'https://example.com/welcome_bg.webp',
            'welcome_cover': 'https://example.com/welcome_cover.png',
            'profile_setup_bg': 'https://example.com/profile_setup_bg.webp',
          }),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Boopi'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
  });

  testWidgets('signed-out app does not render stale child profiles', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith((ref) => Stream.value(null)),
          profileNotifierProvider.overrideWith(_TestProfileNotifier.new),
          appAssetsProvider.overrideWithValue({
            'welcome_bg(1)': 'https://example.com/welcome_bg.webp',
            'welcome_cover': 'https://example.com/welcome_cover.png',
          }),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Aarav'), findsNothing);
    expect(find.text('Meera'), findsNothing);
  });

  testWidgets('returning authenticated parent resumes with their child', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) => Stream.value(
              const AppSessionIdentity(userId: 'parent-1', isAnonymous: false),
            ),
          ),
          profileNotifierProvider.overrideWith(_TestProfileNotifier.new),
          appAssetsProvider.overrideWithValue(const {}),
          companionsProvider.overrideWith((ref) async => const []),
          storytimeContentProvider.overrideWith(
            (ref) async => StorytimeContent.empty(),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.textContaining('Aarav'), findsWidgets);
    expect(find.byType(WelcomeScreen), findsNothing);
  });

  testWidgets('pending companion selection opens chooser instead of home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) => Stream.value(
              const AppSessionIdentity(userId: 'parent-1', isAnonymous: false),
            ),
          ),
          companionSelectionPendingProvider.overrideWith((ref) => true),
          profileNotifierProvider.overrideWith(_TestProfileNotifier.new),
          appAssetsProvider.overrideWithValue(const {}),
          companionsProvider.overrideWith((ref) async => const []),
          storytimeContentProvider.overrideWith(
            (ref) async => StorytimeContent.empty(),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ChooseCompanionScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('profile navigation exposes and reaches all four tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileNotifierProvider.overrideWith(_TestProfileNotifier.new),
          companionsProvider.overrideWith((ref) async => const []),
          appAssetsProvider.overrideWithValue({
            'mascot_character_favorite':
                'https://example.com/mascot_character_favorite.png',
          }),
          storytimeContentProvider.overrideWith(
            (ref) async => StorytimeContent.empty(),
          ),
          savedLibraryProvider.overrideWith(
            (ref) => _TestSavedLibraryNotifier(),
          ),
        ],
        child: MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: AppTheme.darkTheme,
          home: const ProfileScreen(
            fallbackChildName: 'Aarav',
            fallbackChildAge: 2,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aarav'), findsWidgets);
    expect(find.text('Meera'), findsOneWidget);
    await tester.tap(find.text('Meera'));
    await tester.pump();
    expect(find.text('5'), findsOneWidget);

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Stories'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Profile'), findsNWidgets(2));
    final profileHeading = tester
        .widgetList<Text>(find.text('Profile'))
        .firstWhere((widget) => widget.style?.fontSize == 20);
    expect(profileHeading.style?.fontFamily, 'PlusJakartaSans');
    expect(profileHeading.style?.fontWeight, FontWeight.w600);
    expect(profileHeading.style?.height, 1.20);
    expect(profileHeading.style?.letterSpacing, -0.25);

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.byType(StorytimeScreen), findsOneWidget);
    expect(find.text('Dreamy Tales'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Email not set'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Meera'), findsWidgets);
  });

  testWidgets('two children blocks child creation with the limit message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileNotifierProvider.overrideWith(_TestProfileNotifier.new),
          companionsProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: AppTheme.darkTheme,
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Child'));
    await tester.pump();

    expect(find.text(childProfileLimitMessage), findsOneWidget);
    expect(find.byType(ProfileSetupScreen), findsNothing);
  });

  testWidgets('stories header profile icon opens the profile page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileNotifierProvider.overrideWith(_TestProfileNotifier.new),
          companionsProvider.overrideWith((ref) async => const []),
          storytimeContentProvider.overrideWith(
            (ref) async => StorytimeContent.empty(),
          ),
        ],
        child: MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: AppTheme.darkTheme,
          home: const StorytimeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Open profile'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Aarav'), findsWidgets);
  });

  testWidgets('stories header favorites icon opens library sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileNotifierProvider.overrideWith(_TestProfileNotifier.new),
          companionsProvider.overrideWith((ref) async => const []),
          storytimeContentProvider.overrideWith(
            (ref) async => StorytimeContent.empty(),
          ),
        ],
        child: MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: AppTheme.darkTheme,
          home: const StorytimeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Open favorites'));
    await tester.pumpAndSettle();

    expect(find.byType(LibrarySectionsScreen), findsOneWidget);
    expect(find.text('No Favourites Yet'), findsOneWidget);
    expect(find.text('Explore Stories'), findsOneWidget);
  });

  testWidgets('profile favourites opens the library stories page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileNotifierProvider.overrideWith(_TestProfileNotifier.new),
          companionsProvider.overrideWith((ref) async => const []),
          appAssetsProvider.overrideWithValue({
            'mascot_character_favorite':
                'https://example.com/mascot_character_favorite.png',
          }),
          storytimeContentProvider.overrideWith(
            (ref) async => StorytimeContent.empty(),
          ),
          savedLibraryProvider.overrideWith(
            (ref) => _TestSavedLibraryNotifier(),
          ),
        ],
        child: MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: AppTheme.darkTheme,
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Favourites'));
    await tester.tap(find.text('Favourites'));
    await tester.pumpAndSettle();

    expect(find.byType(LibrarySectionsScreen), findsOneWidget);
    expect(find.text('No Favourites Yet'), findsOneWidget);

    await tester.tap(find.text('Explore Stories'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('profile privacy policy opens the privacy policy screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileNotifierProvider.overrideWith(_TestProfileNotifier.new),
          companionsProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: AppTheme.darkTheme,
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Privacy Policy'));
    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();

    expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
    expect(
      find.textContaining('Last updated: 15 July 2026', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('support@boopi.app', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('home story favourite appears in favourites screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileNotifierProvider.overrideWith(_TestProfileNotifier.new),
          storytimeContentProvider.overrideWith(
            (ref) async => StorytimeContent.empty(),
          ),
        ],
        child: MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: AppTheme.darkTheme,
          home: const HomeScreen(childName: 'Aarav', childAge: 3),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Add to favorites').first);
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Open favorites'));
    await tester.pumpAndSettle();

    expect(find.byType(LibrarySectionsScreen), findsOneWidget);
    expect(find.text('Shararati Krishna ke karname'), findsWidgets);
    expect(find.bySemanticsLabel('Remove from favorites'), findsWidgets);
    expect(find.text('No Favourites Yet'), findsNothing);
  });

  testWidgets('home search does not keep focus after opening favourites', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileNotifierProvider.overrideWith(_TestProfileNotifier.new),
          appAssetsProvider.overrideWithValue(const {}),
          storytimeContentProvider.overrideWith(
            (ref) async => StorytimeContent.empty(),
          ),
        ],
        child: MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: AppTheme.darkTheme,
          home: const HomeScreen(childName: 'Aarav', childAge: 3),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField));
    await tester.pump();
    final focusedSearchField = tester.widget<TextField>(
      find.byType(TextField),
    );
    expect(focusedSearchField.focusNode?.hasFocus, isTrue);

    await tester.tap(find.bySemanticsLabel('Open favorites'));
    await tester.pumpAndSettle();

    final offstageSearchField = tester.widget<TextField>(
      find.byType(TextField, skipOffstage: false),
    );
    expect(offstageSearchField.focusNode?.hasFocus, isFalse);

    await tester.pageBack();
    await tester.pumpAndSettle();

    final returnedSearchField = tester.widget<TextField>(
      find.byType(TextField),
    );
    expect(returnedSearchField.focusNode?.hasFocus, isFalse);
  });

  testWidgets('home story card opens the episodes screen', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 868);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileNotifierProvider.overrideWith(_TestProfileNotifier.new),
          storytimeContentProvider.overrideWith(
            (ref) async => StorytimeContent.empty(),
          ),
        ],
        child: MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: AppTheme.darkTheme,
          home: const HomeScreen(childName: 'Aarav', childAge: 3),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    final heroRect = tester.getRect(
      find.byKey(const ValueKey('homeHeroBanner')),
    );
    expect(heroRect.size, const Size(359, 202));
    expect(
      tester.getTopLeft(find.text('Top Picks for You')).dy,
      greaterThan(heroRect.bottom),
    );

    final thumbnailSize = tester.getSize(
      find.byKey(const ValueKey('story-card-thumbnail')).first,
    );
    expect(thumbnailSize, const Size(147, 184));

    await tester.tap(find.text('Shararati Krishna ke karname').first);
    await tester.pumpAndSettle();

    expect(find.byType(EpisodesScreen), findsOneWidget);
    expect(find.text('Makhan Ki Talaash'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('episode-stage-completed-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('episode-stage-continuing-2')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('episode-stage-left-3')), findsOneWidget);
  });

  testWidgets('home and stories stay stable on compact scaled Android layout', (
    WidgetTester tester,
  ) async {
    final view = tester.view;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
      view.platformDispatcher.clearTextScaleFactorTestValue();
      view.padding = FakeViewPadding.zero;
    });

    view.devicePixelRatio = 2.75;
    view.physicalSize = const Size(990, 1980);
    view.platformDispatcher.textScaleFactorTestValue = 1.25;
    view.padding = const FakeViewPadding(bottom: 72);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileNotifierProvider.overrideWith(_TestProfileNotifier.new),
          companionsProvider.overrideWith((ref) async => const []),
          appAssetsProvider.overrideWithValue(const {}),
          storytimeContentProvider.overrideWith((ref) async => _storyContent),
        ],
        child: MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: AppTheme.darkTheme,
          home: const HomeScreen(childName: 'svayudh', childAge: 3),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Stories'), findsOneWidget);

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Dreamy Tales'), findsWidgets);
    expect(find.text('For You'), findsOneWidget);
  });

  testWidgets('home continue listening shows saved unfinished story', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileNotifierProvider.overrideWith(_TestProfileNotifier.new),
          companionsProvider.overrideWith((ref) async => const []),
          appAssetsProvider.overrideWithValue(const {}),
          storytimeContentProvider.overrideWith((ref) async => _storyContent),
          continueListeningProvider.overrideWith(
            (ref) => _SeededContinueListeningNotifier(
              ContinueListeningEntry(
                story: _storyTwo,
                currentPageIndex: 1,
                pageCount: 4,
                updatedAt: _testUpdatedAt,
              ),
            ),
          ),
        ],
        child: MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: AppTheme.darkTheme,
          home: const HomeScreen(childName: 'Aarav', childAge: 3),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Continue Listening'), findsOneWidget);
    expect(find.text('Kanha Ke Aane Ki Khabar'), findsOneWidget);
    expect(find.text('4 min'), findsOneWidget);
  });

  test('continue listening saves progress and clears completed story', () {
    final notifier = ContinueListeningNotifier();

    notifier.saveProgress(
      story: _storyOne,
      currentPageIndex: 2,
      pageCount: 5,
      updatedAt: _testUpdatedAt,
    );

    expect(notifier.state?.story.id, _storyOne.id);
    expect(notifier.state?.currentPageIndex, 2);
    expect(notifier.state?.pageCount, 5);

    notifier.clearStory(_storyTwo.id);
    expect(notifier.state?.story.id, _storyOne.id);

    notifier.clearStory(_storyOne.id);
    expect(notifier.state, isNull);
  });

  testWidgets('profile setup default UI renders Figma form', (
    WidgetTester tester,
  ) async {
    await _pumpProfileSetup(
      tester,
      notifier: _OnboardingProfileNotifier(
        savedChild: _child(name: 'A', age: 2),
      ),
    );

    expect(find.text('Tell us about your little one'), findsOneWidget);
    expect(find.text('We personalise every story to fit.'), findsOneWidget);
    expect(find.text('Child\'s Name'), findsOneWidget);
    expect(find.text('Enter here'), findsOneWidget);
    expect(find.text('Child\'s Gender'), findsOneWidget);
    expect(find.text('Child\'s Age'), findsOneWidget);
    expect(find.text('Story Language'), findsOneWidget);
    expect(find.text('Start Storytime'), findsOneWidget);
  });

  testWidgets('entering child name changes the field state', (
    WidgetTester tester,
  ) async {
    await _pumpProfileSetup(
      tester,
      notifier: _OnboardingProfileNotifier(
        savedChild: _child(name: 'A', age: 2),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('childNameField')),
      'Svayudh',
    );
    await tester.pump();

    expect(find.text('Svayudh'), findsOneWidget);
  });

  testWidgets('profile setup selections update selected state', (
    WidgetTester tester,
  ) async {
    await _pumpProfileSetup(
      tester,
      notifier: _OnboardingProfileNotifier(
        savedChild: _child(name: 'A', age: 2),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('choiceboyUnselected')));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('choiceen-INUnselected')),
    );
    await tester.tap(find.byKey(const ValueKey('choiceen-INUnselected')));
    await tester.pump();

    expect(find.byKey(const ValueKey('choiceboySelected')), findsOneWidget);
    expect(find.byKey(const ValueKey('ageChip3Selected')), findsOneWidget);
    expect(find.byKey(const ValueKey('choiceen-INSelected')), findsOneWidget);

    final selectedAgeChip = find.byKey(const ValueKey('ageChip3Selected'));
    expect(tester.getSize(selectedAgeChip), const Size(52, 52));

    final chipSurface = tester.widget<AnimatedContainer>(selectedAgeChip);
    final decoration = chipSurface.decoration! as BoxDecoration;
    expect(decoration.shape, BoxShape.circle);
    expect(chipSurface.padding, const EdgeInsets.all(12));
  });

  testWidgets('profile setup age row hints more ages with trailing peek', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpProfileSetup(
      tester,
      notifier: _OnboardingProfileNotifier(
        savedChild: _child(name: 'A', age: 2),
      ),
    );

    final ageOneRect = tester.getRect(find.byKey(const ValueKey('ageChip1')));
    final ageFiveRect = tester.getRect(find.byKey(const ValueKey('ageChip5')));
    final ageSixRect = tester.getRect(find.byKey(const ValueKey('ageChip6')));

    expect(ageOneRect.size, const Size(52, 52));
    expect(ageFiveRect.right, lessThanOrEqualTo(390));
    expect(ageSixRect.left, lessThan(390));
    expect(ageSixRect.right, greaterThan(390));
  });

  testWidgets('start storytime is ignored until the form is complete', (
    WidgetTester tester,
  ) async {
    final notifier = _OnboardingProfileNotifier(
      savedChild: _child(name: 'A', age: 2),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileNotifierProvider.overrideWith(() => notifier)],
        child: MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: AppTheme.darkTheme,
          home: const _ProfileSetupLauncher(),
        ),
      ),
    );

    await tester.tap(find.text('Open setup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Storytime'));
    await tester.pumpAndSettle();

    expect(notifier.addChildCalls, 0);
    expect(find.byType(ProfileSetupScreen), findsOneWidget);
  });

  testWidgets('onboarding saves a child and opens home', (
    WidgetTester tester,
  ) async {
    final notifier = _OnboardingProfileNotifier(
      savedChild: _child(name: 'Saved Aarav', age: 4),
    );

    await _pumpProfileSetup(tester, notifier: notifier);
    await _completeProfileSetupForm(tester);
    await tester.pumpAndSettle();

    expect(notifier.addChildCalls, 1);
    expect(find.byType(ProfileSetupScreen), findsNothing);
    expect(find.byType(ChooseCompanionScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.textContaining('Saved Aarav'), findsWidgets);
  });

  testWidgets('failed child creation stays on profile setup', (
    WidgetTester tester,
  ) async {
    final notifier = _OnboardingProfileNotifier(
      error: StateError('Could not start a guest session'),
    );

    await _pumpProfileSetup(tester, notifier: notifier);
    await _completeProfileSetupForm(tester, name: 'Aarav');
    await tester.pumpAndSettle();

    expect(notifier.addChildCalls, 1);
    expect(find.byType(ProfileSetupScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.textContaining('Could not save profile'), findsOneWidget);
    final field = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(field.controller?.text, 'Aarav');
  });

  testWidgets('repeated Start Storytime taps create only one child', (
    WidgetTester tester,
  ) async {
    final notifier = _OnboardingProfileNotifier(
      savedChild: _child(name: 'Saved Aarav', age: 4),
    );

    await _pumpProfileSetup(tester, notifier: notifier);
    await _fillProfileSetupForm(tester);
    await tester.ensureVisible(find.text('Start Storytime'));

    await tester.tap(find.text('Start Storytime'));
    await tester.tap(find.text('Start Storytime'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(notifier.addChildCalls, 1);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('popOnSave returns the created child', (
    WidgetTester tester,
  ) async {
    final savedChild = _child(name: 'Meera', age: 3);
    final notifier = _OnboardingProfileNotifier(savedChild: savedChild);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileNotifierProvider.overrideWith(() => notifier),
          appAssetsProvider.overrideWithValue(_testAssets),
        ],
        child: MaterialApp(
          themeMode: ThemeMode.dark,
          darkTheme: AppTheme.darkTheme,
          home: const _ProfileSetupLauncher(),
        ),
      ),
    );

    await tester.tap(find.text('Open setup'));
    await tester.pumpAndSettle();
    await _completeProfileSetupForm(tester, name: 'Meera');
    await tester.pumpAndSettle();

    expect(find.byType(ProfileSetupScreen), findsNothing);
    expect(find.text('Created Meera (3)'), findsOneWidget);
  });
}

const _testAssets = {
  'profile_setup_bg': 'https://example.com/profile_setup_bg.webp',
};

const _storyOne = StoryModel(
  id: 'story-one',
  title: 'Kanha Ki Sunheri Subah',
  thumbnailUrl: 'https://example.com/story-one.webp',
  category: 'Krishna Stories',
  durationMinutes: 3,
);

const _storyTwo = StoryModel(
  id: 'story-two',
  title: 'Kanha Ke Aane Ki Khabar',
  thumbnailUrl: 'https://example.com/story-two.webp',
  category: 'Krishna Stories',
  durationMinutes: 4,
);

const _storyContent = StorytimeContent(
  featuredBanners: [
    FeaturedBannerModel(
      id: 'banner-one',
      imageUrl: 'https://example.com/banner-one.webp',
      title: 'Krishna playing with flute',
      subtitle: 'Dreamy Tales',
    ),
  ],
  sections: [
    StorySectionModel(
      id: 'for-you',
      title: 'For You',
      stories: [_storyOne, _storyTwo],
    ),
  ],
  forYouStories: [_storyOne, _storyTwo],
  popularStories: [],
  categories: [],
);

final _testUpdatedAt = DateTime.utc(2026, 6, 17);

Future<void> _pumpProfileSetup(
  WidgetTester tester, {
  required _OnboardingProfileNotifier notifier,
  List<CompanionModel> companions = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileNotifierProvider.overrideWith(() => notifier),
        appAssetsProvider.overrideWithValue(_testAssets),
        companionsProvider.overrideWith((ref) async => companions),
        storytimeContentProvider.overrideWith(
          (ref) async => StorytimeContent.empty(),
        ),
      ],
      child: MaterialApp(
        themeMode: ThemeMode.dark,
        darkTheme: AppTheme.darkTheme,
        home: const _TestOnboardingGate(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _completeProfileSetupForm(
  WidgetTester tester, {
  String name = 'Typed Aarav',
}) async {
  await _fillProfileSetupForm(tester, name: name);
  await tester.ensureVisible(find.text('Start Storytime'));
  await tester.tap(find.text('Start Storytime'));
}

Future<void> _fillProfileSetupForm(
  WidgetTester tester, {
  String name = 'Typed Aarav',
}) async {
  await tester.enterText(find.byType(TextFormField), name);
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('choiceboyUnselected')));
  await tester.pump();
  await tester.tap(find.text('3'));
  await tester.pump();
  await tester.ensureVisible(
    find.byKey(const ValueKey('choiceen-INUnselected')),
  );
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('choiceen-INUnselected')));
  await tester.pump();
}

class _TestOnboardingGate extends ConsumerWidget {
  const _TestOnboardingGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profileNotifierProvider);
    return profiles.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => const ProfileSetupScreen(),
      data: (state) {
        if (state.children.isEmpty) {
          return const ProfileSetupScreen();
        }
        if (ref.watch(companionSelectionPendingProvider)) {
          return ChooseCompanionScreen(
            onComplete: (context) {
              ref.read(companionSelectionPendingProvider.notifier).state =
                  false;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          );
        }

        final child = state.selectedChild;
        return HomeScreen(childName: child?.childName, childAge: child?.age);
      },
    );
  }
}

ChildProfileModel _child({required String name, required int age}) {
  return ChildProfileModel(
    id: 'saved-child',
    parentId: 'parent-1',
    childName: name,
    age: age,
    gender: 'boy',
    createdAt: DateTime.utc(2026, 6, 9),
  );
}

class _TestProfileNotifier extends ProfileNotifier {
  @override
  Future<ChildProfilesState> build() async {
    return ChildProfilesState(
      selectedChildId: 'profile-1',
      children: [
        ChildProfileModel(
          id: 'profile-1',
          parentId: 'parent-1',
          childName: 'Aarav',
          age: 2,
          gender: 'boy',
          createdAt: DateTime.utc(2026, 6, 9),
        ),
        ChildProfileModel(
          id: 'profile-2',
          parentId: 'parent-1',
          childName: 'Meera',
          age: 5,
          gender: 'girl',
          createdAt: DateTime.utc(2026, 6, 8),
        ),
      ],
    );
  }
}

class _OnboardingProfileNotifier extends ProfileNotifier {
  _OnboardingProfileNotifier({this.savedChild, this.error});

  final ChildProfileModel? savedChild;
  final Object? error;
  int addChildCalls = 0;
  String? updatedCompanionId;

  @override
  Future<ChildProfilesState> build() async => const ChildProfilesState();

  @override
  Future<ChildProfileModel> addChild({
    required String name,
    required String gender,
    required int age,
    required String? companionId,
    String locale = defaultProfileLocale,
  }) async {
    addChildCalls++;
    if (error case final error?) {
      state = AsyncError(error, StackTrace.current);
      throw error;
    }

    final child =
        savedChild ??
        ChildProfileModel(
          id: 'saved-child',
          parentId: 'parent-1',
          childName: name,
          age: age,
          gender: gender,
          companionId: companionId,
          locale: locale,
          createdAt: DateTime.utc(2026, 6, 9),
        );
    state = AsyncData(
      ChildProfilesState(children: [child], selectedChildId: child.id),
    );
    return child;
  }

  @override
  Future<ChildProfileModel> updateSelectedChildCompanion(
    String companionId,
  ) async {
    updatedCompanionId = companionId;
    final current = state.valueOrNull ?? const ChildProfilesState();
    final child = current.selectedChild;
    if (child == null) {
      throw StateError('No child profile selected');
    }

    final updated = child.copyWith(companionId: companionId);
    state = AsyncData(
      current.copyWith(children: [updated], selectedChildId: updated.id),
    );
    return updated;
  }
}

class _ProfileSetupLauncher extends StatefulWidget {
  const _ProfileSetupLauncher();

  @override
  State<_ProfileSetupLauncher> createState() => _ProfileSetupLauncherState();
}

class _ProfileSetupLauncherState extends State<_ProfileSetupLauncher> {
  ChildProfileModel? _createdChild;

  Future<void> _openSetup() async {
    final child = await Navigator.push<ChildProfileModel>(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileSetupScreen(popOnSave: true),
      ),
    );
    if (mounted) {
      setState(() => _createdChild = child);
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = _createdChild;
    return Scaffold(
      body: Center(
        child: child == null
            ? TextButton(onPressed: _openSetup, child: const Text('Open setup'))
            : Text('Created ${child.childName} (${child.age})'),
      ),
    );
  }
}

class _TestSavedLibraryNotifier extends SavedLibraryNotifier {
  _TestSavedLibraryNotifier() : super(const StoryRepository());

  @override
  Future<void> loadLibrary() async {}
}

class _SeededContinueListeningNotifier extends ContinueListeningNotifier {
  _SeededContinueListeningNotifier(ContinueListeningEntry entry) {
    state = entry;
  }
}

class _EmptyAsyncStorage extends GotrueAsyncStorage {
  const _EmptyAsyncStorage();

  @override
  Future<String?> getItem({required String key}) async => null;

  @override
  Future<void> removeItem({required String key}) async {}

  @override
  Future<void> setItem({required String key, required String value}) async {}
}
