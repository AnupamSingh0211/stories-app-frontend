import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dharma_app/features/auth/assets_provider.dart';
import 'package:dharma_app/features/auth/companions_provider.dart';
import 'package:dharma_app/features/auth/profile_notifier.dart';
import 'package:dharma_app/features/auth/profile_repository.dart';
import 'package:dharma_app/features/profile/profile_screen.dart';
import 'package:dharma_app/features/storytime/models/story_model.dart';
import 'package:dharma_app/features/storytime/providers/saved_library_provider.dart';
import 'package:dharma_app/features/storytime/providers/story_player_provider.dart';
import 'package:dharma_app/features/storytime/repositories/story_repository.dart';
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
          appAssetsProvider.overrideWithValue({
            'welcome_bg': 'https://example.com/welcome_bg.webp',
            'profile_setup_bg': 'https://example.com/profile_setup_bg.webp',
            'ios_icon': 'https://example.com/ios_icon.png',
            'google_icon': 'https://example.com/google_icon.png',
            'email_icon': 'https://example.com/email_icon.png',
          }),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.text('Welcome to\nBedtime Stories'), findsOneWidget);
    expect(find.text('Browse as a Guest ->'), findsOneWidget);
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
    expect(find.textContaining('Aarav'), findsWidgets);
  });
}

class _TestProfileNotifier extends ProfileNotifier {
  @override
  Future<ProfileModel?> build() async {
    return const ProfileModel(
      id: 'profile-1',
      childName: 'Aarav',
      age: 2,
      gender: 'boy',
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
