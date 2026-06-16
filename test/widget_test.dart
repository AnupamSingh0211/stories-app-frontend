import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dharma_app/features/auth/assets_provider.dart';
import 'package:dharma_app/features/auth/auth_provider.dart';
import 'package:dharma_app/features/auth/companions_provider.dart';
import 'package:dharma_app/features/auth/profile_notifier.dart';
import 'package:dharma_app/features/auth/profile_repository.dart';
import 'package:dharma_app/features/auth/profile_setup_screen.dart';
import 'package:dharma_app/features/auth/welcome_screen.dart';
import 'package:dharma_app/features/home/home_screen.dart';
import 'package:dharma_app/features/library/library_screen.dart';
import 'package:dharma_app/features/profile/profile_screen.dart';
import 'package:dharma_app/features/storytime/models/story_model.dart';
import 'package:dharma_app/features/storytime/providers/saved_library_provider.dart';
import 'package:dharma_app/features/storytime/providers/story_player_provider.dart';
import 'package:dharma_app/features/storytime/repositories/story_repository.dart';
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
            'welcome_bg': 'https://example.com/welcome_bg.webp',
            'profile_setup_bg': 'https://example.com/profile_setup_bg.webp',
          }),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to\nBedtime Stories'), findsOneWidget);
    expect(find.text('Browse as Guest →'), findsOneWidget);
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
            'welcome_bg': 'https://example.com/welcome_bg.webp',
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

  testWidgets('profile navigation exposes and reaches all four tabs', (
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

    await tester.tap(find.text('Stories'));
    await tester.pumpAndSettle();
    expect(find.text('Dreamy Tales'), findsOneWidget);

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(
      find.text('Replay the stories your child loves most.'),
      findsOneWidget,
    );

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

  testWidgets('profile favourites opens the library page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileNotifierProvider.overrideWith(_TestProfileNotifier.new),
          companionsProvider.overrideWith((ref) async => const []),
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

    expect(find.byType(LibraryScreen), findsOneWidget);
    expect(
      find.text('Replay the stories your child loves most.'),
      findsOneWidget,
    );
  });

  testWidgets('onboarding saves a child and replaces setup with home', (
    WidgetTester tester,
  ) async {
    final notifier = _OnboardingProfileNotifier(
      savedChild: _child(name: 'Saved Aarav', age: 4),
    );

    await _pumpProfileSetup(tester, notifier: notifier);
    await tester.enterText(find.byType(TextFormField), 'Typed Aarav');
    await tester.ensureVisible(find.text('Add Child'));
    await tester.tap(find.text('Add Child'));
    await tester.pumpAndSettle();

    expect(notifier.addChildCalls, 1);
    expect(find.byType(ProfileSetupScreen), findsNothing);
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
    await tester.enterText(find.byType(TextFormField), 'Aarav');
    await tester.ensureVisible(find.text('Add Child'));
    await tester.tap(find.text('Add Child'));
    await tester.pumpAndSettle();

    expect(notifier.addChildCalls, 1);
    expect(find.byType(ProfileSetupScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.textContaining('Could not save profile'), findsOneWidget);
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
    await tester.enterText(find.byType(TextFormField), 'Meera');
    await tester.ensureVisible(find.text('Add Child'));
    await tester.tap(find.text('Add Child'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileSetupScreen), findsNothing);
    expect(find.text('Created Meera (3)'), findsOneWidget);
  });
}

const _testAssets = {
  'profile_setup_bg': 'https://example.com/profile_setup_bg.webp',
};

Future<void> _pumpProfileSetup(
  WidgetTester tester, {
  required _OnboardingProfileNotifier notifier,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileNotifierProvider.overrideWith(() => notifier),
        appAssetsProvider.overrideWithValue(_testAssets),
        companionsProvider.overrideWith((ref) async => const []),
        storytimeContentProvider.overrideWith(
          (ref) async => StorytimeContent.empty(),
        ),
      ],
      child: MaterialApp(
        themeMode: ThemeMode.dark,
        darkTheme: AppTheme.darkTheme,
        home: const ProfileSetupScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
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

  @override
  Future<ChildProfilesState> build() async => const ChildProfilesState();

  @override
  Future<ChildProfileModel> addChild({
    required String name,
    required String gender,
    required int age,
    required String? companionId,
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
          createdAt: DateTime.utc(2026, 6, 9),
        );
    state = AsyncData(
      ChildProfilesState(children: [child], selectedChildId: child.id),
    );
    return child;
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

class _EmptyAsyncStorage extends GotrueAsyncStorage {
  const _EmptyAsyncStorage();

  @override
  Future<String?> getItem({required String key}) async => null;

  @override
  Future<void> removeItem({required String key}) async {}

  @override
  Future<void> setItem({required String key, required String value}) async {}
}
