import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_config.dart';
import 'core/theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/storytime/models/story_model.dart';
import 'features/storytime/providers/story_player_provider.dart';
import 'features/storytime/repositories/story_repository.dart';
import 'features/storytime/screens/story_player_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(
    ProviderScope(
      overrides: [
        activeSessionProvider.overrideWithValue(null),
        storyRepositoryProvider.overrideWithValue(
          const _PreviewStoryRepository(),
        ),
      ],
      child: const _StoryPreviewApp(),
    ),
  );
}

class _StoryPreviewApp extends StatelessWidget {
  const _StoryPreviewApp();

  @override
  Widget build(BuildContext context) {
    const previewStory = StoryModel(
      id: 'preview-story',
      title: 'Story Preview',
      thumbnailUrl: '',
      category: 'Story',
      durationMinutes: 4,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Story Page Flip Preview',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: StoryPlayerScreen(
        storyId: previewStory.id,
        title: previewStory.title,
        story: previewStory,
      ),
    );
  }
}

class _PreviewStoryRepository extends StoryRepository {
  const _PreviewStoryRepository();

  @override
  Future<bool> isFavoriteStory(String storyId, {String? profileId}) async =>
      false;

  @override
  Future<void> addFavoriteStory(String storyId, {String? profileId}) async {}

  @override
  Future<void> removeFavoriteStory(String storyId, {String? profileId}) async {}

  @override
  Future<bool> isStorySaved(String storyId) async => false;

  @override
  Future<int> fetchSavedStoryCount() async => 0;

  @override
  Future<void> saveStoryToLibrary(String storyId) async {}

  @override
  Future<void> removeSavedStory(String storyId) async {}
}
