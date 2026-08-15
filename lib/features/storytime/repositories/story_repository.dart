import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/performance/story_performance_metrics.dart';
import '../../../core/supabase_client.dart';
import '../../auth/auth_provider.dart';
import '../models/story_model.dart';
import '../models/story_page.dart';
import 'story_page_memory_cache.dart';
import 'storytime_content_memory_cache.dart';

class StoryRepository {
  const StoryRepository();

  // Transitional: story, favorites, saved-library, and storage reads still use
  // Supabase here until Headings 6-8 migrate each domain to backend-shaped APIs.
  static final Set<String> _favoriteStoryIds = {};
  static final Set<String> _savedStoryIds = {};

  static const savedStoryLimit = 10;
  static const morningWhispersStoryId = '11111111-1111-4111-8111-111111111111';
  static const arrivalNewsStoryId = '22222222-2222-4222-8222-222222222222';
  static const _storyAssetsBucket = 'story-assets';
  static const krishnaStoryCardId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1';
  static const _storyColumns =
      'id, title, category_id, thumbnail_url, cover_url, duration_seconds, '
      'is_featured, created_at, story_card_id, sort_order';
  static final StoryPageMemoryCache _storyPageCache = StoryPageMemoryCache();
  static final StorytimeContentMemoryCache _storytimeContentCache =
      StorytimeContentMemoryCache();
  static Future<StorytimeContent>? _storytimeContentRequest;

  Future<StorytimeContent> fetchStorytimeContent() async {
    final cached = _storytimeContentCache.get();
    if (cached != null) {
      return cached;
    }

    final pendingRequest = _storytimeContentRequest;
    if (pendingRequest != null) {
      return pendingRequest;
    }

    final request = _loadStorytimeContent();
    _storytimeContentRequest = request;
    try {
      final content = await request;
      _storytimeContentCache.put(content);
      return content;
    } finally {
      if (identical(_storytimeContentRequest, request)) {
        _storytimeContentRequest = null;
      }
    }
  }

  void invalidateStorytimeContentCache() {
    _storytimeContentCache.clear();
  }

  Future<List<StoryCardModel>> fetchStoryCards() async {
    final client = SupabaseClientProvider.client;
    final storage = client.storage.from('app-assets');

    try {
      final rows = await _trackedSupabaseRequest(
        'story_cards.select',
        () async => client
            .from('story_cards')
            .select(
              'id, title, thumbnail_url, hero_banner_url, '
              'category, sort_order, is_active',
            )
            .eq('is_active', true)
            .order('sort_order', ascending: true)
            .order('created_at', ascending: true),
      );

      return _mapRows(rows)
          .map((row) => _storyCardFromMap(row, storage))
          .whereType<StoryCardModel>()
          .toList(growable: false);
    } catch (error) {
      debugPrint('StoryRepository: story card query failed. $error');
      throw const StoryRepositoryException(
        'Story cards could not be loaded from the database.',
      );
    }
  }

  Future<List<StoryModel>> fetchStoriesForCard(String storyCardId) async {
    final client = SupabaseClientProvider.client;

    try {
      final storyRows = await _trackedSupabaseRequest(
        'stories.select_for_card',
        () async => client
            .from('stories')
            .select(_storyColumns)
            .eq('story_card_id', storyCardId)
            .order('sort_order', ascending: true)
            .order('created_at', ascending: true),
      );

      return _storyModelsFromRows(client, _mapRows(storyRows));
    } catch (error) {
      debugPrint('StoryRepository: story card stories query failed. $error');
      throw const StoryRepositoryException(
        'Stories for this card could not be loaded from the database.',
      );
    }
  }

  Future<StorytimeContent> _loadStorytimeContent() async {
    final client = SupabaseClientProvider.client;
    final storage = client.storage.from('app-assets');

    final List<dynamic> results;
    try {
      results = await Future.wait([
        _trackedSupabaseRequest(
          'storage.featured_banners',
          () => _featuredBannersFromStorage(storage),
        ),
        _trackedSupabaseRequest(
          'story_categories.select',
          () async => client
              .from('story_categories')
              .select('id, title, display_order')
              .order('display_order'),
        ),
        _trackedSupabaseRequest(
          'story_sections.select',
          () async => client
              .from('story_sections')
              .select(
                'id, title, display_order, '
                'section_stories(section_id, story_id, sort_order, '
                'stories($_storyColumns))',
              )
              .order('display_order'),
        ),
      ]);
    } catch (error) {
      debugPrint('StoryRepository: Supabase story query failed. $error');
      throw const StoryRepositoryException(
        'Stories could not be loaded from the database.',
      );
    }

    final featuredBanners = results[0] as List<FeaturedBannerModel>;
    final categories = _mapRows(results[1]);
    final sectionRows = _mapRows(results[2]);
    final categoryNames = _categoryNamesById(categories);

    final sections = sectionRows
        .map((row) => _sectionFromMap(row, categoryNames, storage))
        .toList(growable: false);

    if (sections.isEmpty) {
      throw const StoryRepositoryException(
        'No stories are configured in the database.',
      );
    }

    final storyCount = sections
        .expand((section) => section.stories)
        .map((story) => story.id)
        .toSet()
        .length;
    debugPrint(
      'StoryRepository: loaded $storyCount stories, ${sections.length} sections, ${categories.length} categories from Supabase tables.',
    );

    final mappedCategories = categories
        .map(_categoryFromMap)
        .whereType<StoryCategoryModel>()
        .toList(growable: false);
    final forYouStories = _storiesForSection(sections, 'for you');
    final popularStories = _storiesForSection(sections, 'popular');

    return StorytimeContent(
      featuredBanners: featuredBanners,
      sections: sections,
      forYouStories: forYouStories,
      popularStories: popularStories,
      categories: mappedCategories,
    );
  }

  Future<FullStoryModel> fetchStoryWithPages(
    String storyId, {
    StoryModel? knownStory,
    List<StoryPage> knownPages = const [],
  }) async {
    if (knownStory != null && knownStory.id != storyId) {
      throw const StoryRepositoryException(
        'The supplied story metadata does not match the requested story.',
      );
    }

    if (knownPages.isNotEmpty) {
      cacheStoryPages(storyId, knownPages);
    }

    final pagesFuture = fetchStoryPages(storyId);
    if (knownStory != null) {
      return FullStoryModel(story: knownStory, pages: await pagesFuture);
    }

    final client = SupabaseClientProvider.client;
    final storage = client.storage.from('app-assets');

    final results = await Future.wait<dynamic>([
      _trackedSupabaseRequest(
        'stories.select_one',
        () async => client
            .from('stories')
            .select(_storyColumns)
            .eq('id', storyId)
            .single(),
      ),
      _trackedSupabaseRequest(
        'story_categories.select',
        () async => client
            .from('story_categories')
            .select('id, title, display_order')
            .order('display_order'),
      ),
      pagesFuture,
    ]);
    final storyRow = results[0] as Map<String, dynamic>;
    final categoryRows = results[1];
    final pages = results[2] as List<StoryPage>;

    return FullStoryModel(
      story: _storyFromMap(
        storyRow,
        _categoryNamesById(_mapRows(categoryRows)),
        storage,
      ),
      pages: pages,
    );
  }

  void cacheStoryPages(String storyId, List<StoryPage> pages) {
    if (pages.isEmpty) {
      return;
    }
    if (pages.any((page) => page.imageUrl.isEmpty || page.audioUrl.isEmpty)) {
      throw const StoryRepositoryException(
        'A supplied story page is missing its image or audio URL.',
      );
    }

    _storyPageCache.put(storyId, pages);
  }

  Future<List<StoryPage>> fetchStoryPages(String storyId) async {
    final cached = _storyPageCache.get(storyId);
    if (cached != null) {
      return cached;
    }

    try {
      final client = SupabaseClientProvider.client;
      final pages = await _fetchPlayableStoryPages(client, storyId);

      if (pages.isEmpty) {
        throw const StoryRepositoryException(
          'This story has no pages configured in the database.',
        );
      }

      if (pages.any((page) => page.imageUrl.isEmpty || page.audioUrl.isEmpty)) {
        throw const StoryRepositoryException(
          'This story has a database page with a missing image or audio path.',
        );
      }

      _storyPageCache.put(storyId, pages);
      return pages;
    } catch (error) {
      if (error is StoryRepositoryException) {
        rethrow;
      }
      debugPrint(
        'StoryRepository: story page query failed for $storyId. $error',
      );
      throw const StoryRepositoryException(
        'Story pages could not be loaded from the database.',
      );
    }
  }

  Future<List<StoryPage>> _fetchPlayableStoryPages(
    SupabaseClient client,
    String storyId,
  ) async {
    final storyAssets = client.storage.from(_storyAssetsBucket);

    try {
      final pageRows = await _fetchDatabaseStoryPages(client, storyId);
      final pages = _storyPagesFromRows(pageRows, storyAssets);
      if (pages.isNotEmpty) {
        return pages;
      }
    } catch (error) {
      debugPrint(
        'StoryRepository: story_pages unavailable for $storyId. $error',
      );
    }

    final episodeRows = await _fetchDatabaseEpisodes(client, storyId);
    return _storyPagesFromEpisodeRows(episodeRows, storyAssets);
  }

  Future<dynamic> _fetchDatabaseStoryPages(
    SupabaseClient client,
    String storyId,
  ) {
    return _trackedSupabaseRequest(
      'story_pages.select',
      () async => client
          .from('story_pages')
          .select('id, story_id, page_number, hindi_text, image_url, audio_url')
          .eq('story_id', storyId)
          .order('page_number', ascending: true),
    );
  }

  Future<dynamic> _fetchDatabaseEpisodes(
    SupabaseClient client,
    String storyId,
  ) {
    return _trackedSupabaseRequest(
      'episodes.select',
      () async => client
          .from('episodes')
          .select(
            'id, story_id, episode_number, title, hindi_script, '
            'english_script, image_url, audio_url, duration_seconds',
          )
          .eq('story_id', storyId)
          .order('episode_number', ascending: true),
    );
  }

  Future<bool> isFavoriteStory(String storyId) async {
    if (kUseAuthBypass) {
      return _favoriteStoryIds.contains(storyId);
    }
    final client = SupabaseClientProvider.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      return false;
    }

    try {
      StoryPerformanceMetrics.instance.recordSupabaseRequest(
        'favorite_stories.select',
      );
      final rows = await client
          .from('favorite_stories')
          .select('id')
          .eq('user_id', userId)
          .eq('story_id', storyId)
          .limit(1);

      return rows.isNotEmpty;
    } catch (error) {
      debugPrint('StoryRepository: favorite lookup failed. $error');
      throw const StoryRepositoryException(
        'Favorite status could not be loaded.',
      );
    }
  }

  Future<void> addFavoriteStory(String storyId) async {
    if (kUseAuthBypass) {
      _favoriteStoryIds.add(storyId);
      return;
    }
    final client = SupabaseClientProvider.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw const StoryRepositoryException(
        'Please sign in to favorite this story.',
      );
    }

    try {
      await client.from('favorite_stories').insert({
        'user_id': userId,
        'story_id': storyId,
      });
    } catch (error) {
      debugPrint('StoryRepository: favorite insert failed. $error');
      throw const StoryRepositoryException(
        'Favorite could not be saved. Please try again.',
      );
    }
  }

  Future<void> removeFavoriteStory(String storyId) async {
    if (kUseAuthBypass) {
      _favoriteStoryIds.remove(storyId);
      return;
    }
    final client = SupabaseClientProvider.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw const StoryRepositoryException(
        'Please sign in to update favorites.',
      );
    }

    try {
      await client
          .from('favorite_stories')
          .delete()
          .eq('user_id', userId)
          .eq('story_id', storyId);
    } catch (error) {
      debugPrint('StoryRepository: favorite delete failed. $error');
      throw const StoryRepositoryException(
        'Favorite could not be removed. Please try again.',
      );
    }
  }

  Future<List<StoryModel>> fetchSavedStories() async {
    if (kUseAuthBypass) {
      final client = SupabaseClientProvider.client;
      final storyIds = _savedStoryIds.toList();
      if (storyIds.isEmpty) {
        return const [];
      }
      try {
        final storyRows = await client
            .from('stories')
            .select(_storyColumns)
            .inFilter('id', storyIds);
        return await _storyModelsFromRows(client, _mapRows(storyRows));
      } catch (e) {
        debugPrint('StoryRepository: saved stories bypass lookup failed. $e');
        return const [];
      }
    }
    final client = SupabaseClientProvider.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      return const [];
    }

    try {
      final rows = await client
          .from('saved_stories')
          .select('story_id, created_at, stories($_storyColumns)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final savedRows = _mapRows(rows);
      final joinedStories = savedRows
          .map((row) => row['stories'])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);

      if (joinedStories.isNotEmpty) {
        return _storyModelsFromRows(client, joinedStories);
      }

      final storyIds = savedRows
          .map((row) => row['story_id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList(growable: false);

      if (storyIds.isEmpty) {
        return const [];
      }

      final storyRows = await client
          .from('stories')
          .select(_storyColumns)
          .inFilter('id', storyIds);

      final storiesById = {
        for (final story in await _storyModelsFromRows(
          client,
          _mapRows(storyRows),
        ))
          story.id: story,
      };

      return storyIds
          .map((id) => storiesById[id])
          .whereType<StoryModel>()
          .toList(growable: false);
    } catch (error) {
      debugPrint('StoryRepository: saved stories lookup failed. $error');
      throw const StoryRepositoryException(
        'Saved stories could not be loaded.',
      );
    }
  }

  Future<int> fetchSavedStoryCount() async {
    if (kUseAuthBypass) {
      return _savedStoryIds.length;
    }
    final client = SupabaseClientProvider.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      return 0;
    }

    try {
      final rows = await client
          .from('saved_stories')
          .select('id')
          .eq('user_id', userId);

      return _mapRows(rows).length;
    } catch (error) {
      debugPrint('StoryRepository: saved stories count failed. $error');
      throw const StoryRepositoryException(
        'Saved story count could not be loaded.',
      );
    }
  }

  Future<bool> isStorySaved(String storyId) async {
    if (kUseAuthBypass) {
      return _savedStoryIds.contains(storyId);
    }
    final client = SupabaseClientProvider.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      return false;
    }

    try {
      final rows = await client
          .from('saved_stories')
          .select('id')
          .eq('user_id', userId)
          .eq('story_id', storyId)
          .limit(1);

      return _mapRows(rows).isNotEmpty;
    } catch (error) {
      debugPrint('StoryRepository: saved story lookup failed. $error');
      throw const StoryRepositoryException(
        'Saved story status could not be loaded.',
      );
    }
  }

  Future<void> saveStoryToLibrary(String storyId) async {
    if (kUseAuthBypass) {
      if (_savedStoryIds.length >= savedStoryLimit) {
        throw const StoryLibraryFullException();
      }
      _savedStoryIds.add(storyId);
      return;
    }
    final client = SupabaseClientProvider.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw const StoryRepositoryException(
        'Please sign in to save stories to your library.',
      );
    }

    if (await isStorySaved(storyId)) {
      return;
    }

    final savedCount = await fetchSavedStoryCount();
    if (savedCount >= savedStoryLimit) {
      throw const StoryLibraryFullException();
    }

    try {
      await client.from('saved_stories').insert({
        'user_id': userId,
        'story_id': storyId,
      });
    } catch (error) {
      debugPrint('StoryRepository: saved story insert failed. $error');
      throw const StoryRepositoryException(
        'Story could not be saved. Please try again.',
      );
    }
  }

  Future<void> removeSavedStory(String storyId) async {
    if (kUseAuthBypass) {
      _savedStoryIds.remove(storyId);
      return;
    }
    final client = SupabaseClientProvider.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw const StoryRepositoryException(
        'Please sign in to update your library.',
      );
    }

    try {
      await client
          .from('saved_stories')
          .delete()
          .eq('user_id', userId)
          .eq('story_id', storyId);
    } catch (error) {
      debugPrint('StoryRepository: saved story delete failed. $error');
      throw const StoryRepositoryException(
        'Story could not be removed. Please try again.',
      );
    }
  }

  StoryPage _storyPageFromMap(
    Map<String, dynamic> row,
    StorageFileApi storage,
  ) {
    final pageNumber = _intValue(row['page_number']);
    return StoryPage(
      pageNumber: pageNumber,
      imageUrl: _assetUrl(storage, _firstString(row, ['image_url'])),
      audioUrl: _assetUrl(storage, _firstString(row, ['audio_url'])),
      text: _firstString(row, ['content', 'hindi_text']),
    );
  }

  List<StoryPage> _storyPagesFromRows(Object? rows, StorageFileApi storage) {
    final pages = _mapRows(
      rows,
    ).map((row) => _storyPageFromMap(row, storage)).toList();
    pages.sort((left, right) => left.pageNumber.compareTo(right.pageNumber));
    return List.unmodifiable(pages);
  }

  StoryPage _storyPageFromEpisodeMap(
    Map<String, dynamic> row,
    StorageFileApi storage,
  ) {
    final episodeNumber = _intValue(row['episode_number']);
    return StoryPage(
      pageNumber: episodeNumber,
      imageUrl: _assetUrl(storage, _firstString(row, ['image_url'])),
      audioUrl: _assetUrl(storage, _firstString(row, ['audio_url'])),
      text: _firstString(row, ['hindi_script', 'english_script', 'title']),
    );
  }

  List<StoryPage> _storyPagesFromEpisodeRows(
    Object? rows,
    StorageFileApi storage,
  ) {
    final pages = _mapRows(
      rows,
    ).map((row) => _storyPageFromEpisodeMap(row, storage)).toList();
    pages.sort((left, right) => left.pageNumber.compareTo(right.pageNumber));
    return List.unmodifiable(pages);
  }

  StorySectionModel _sectionFromMap(
    Map<String, dynamic> row,
    Map<String, String> categoryNames,
    StorageFileApi storage,
  ) {
    final joins = _mapRows(row['section_stories']);
    joins.sort((a, b) => _orderValue(a).compareTo(_orderValue(b)));

    final stories = joins
        .map((join) => join['stories'])
        .whereType<Map<String, dynamic>>()
        .map((story) => _storyFromMap(story, categoryNames, storage))
        .toList(growable: false);

    return StorySectionModel(
      id: row['id'].toString(),
      title: row['title'] as String,
      stories: stories,
    );
  }

  StoryCardModel? _storyCardFromMap(
    Map<String, dynamic> row,
    StorageFileApi storage,
  ) {
    final title = _firstString(row, ['title']);
    final thumbnailUrl = _assetUrl(
      storage,
      _firstString(row, ['thumbnail_url']),
    );
    final heroBannerUrl = _assetUrl(
      storage,
      _firstString(row, ['hero_banner_url']),
    );

    if (title.isEmpty || thumbnailUrl.isEmpty || heroBannerUrl.isEmpty) {
      return null;
    }

    final category = _firstString(row, ['category']);

    return StoryCardModel(
      id: row['id'].toString(),
      title: title,
      thumbnailUrl: thumbnailUrl,
      heroBannerUrl: heroBannerUrl,
      category: category.isEmpty ? 'Story' : category,
      sortOrder: _intValue(row['sort_order']),
    );
  }

  StoryModel _storyFromMap(
    Map<String, dynamic> row,
    Map<String, String> categoryNames,
    StorageFileApi storage,
  ) {
    final durationSeconds = _intValue(row['duration_seconds']);
    final thumbnailUrl = _assetUrl(
      storage,
      _firstString(row, ['thumbnail_url']),
    );

    return StoryModel(
      id: row['id'].toString(),
      title: row['title'] as String,
      thumbnailUrl: thumbnailUrl,
      category: categoryNames[row['category_id']?.toString()] ?? 'Story',
      durationMinutes: durationSeconds <= 0
          ? 0
          : (durationSeconds / Duration.secondsPerMinute).ceil(),
      imageUrl: _assetUrl(storage, _firstString(row, ['cover_url'])),
      coverUrl: _assetUrl(storage, _firstString(row, ['cover_url'])),
    );
  }

  Future<List<StoryModel>> _storyModelsFromRows(
    SupabaseClient client,
    List<Map<String, dynamic>> rows,
  ) async {
    final storage = client.storage.from('app-assets');
    final categories = await client
        .from('story_categories')
        .select('id, title, display_order')
        .order('display_order');
    final categoryNames = _categoryNamesById(_mapRows(categories));

    return rows
        .map((row) => _storyFromMap(row, categoryNames, storage))
        .toList(growable: false);
  }

  Future<List<FeaturedBannerModel>> _featuredBannersFromStorage(
    StorageFileApi storage,
  ) async {
    final files = await storage.list(
      path: 'featured_banners',
      searchOptions: const SearchOptions(
        limit: 100,
        sortBy: SortBy(column: 'name', order: 'asc'),
      ),
    );

    return files
        .where((file) => file.name.toLowerCase().endsWith('.webp'))
        .map(
          (file) => FeaturedBannerModel(
            id: file.id ?? file.name,
            imageUrl: storage.getPublicUrl('featured_banners/${file.name}'),
            title: _fileNameWithoutExtension(file.name),
            subtitle: 'Dreamy Tales',
          ),
        )
        .toList(growable: false);
  }

  String _fileNameWithoutExtension(String fileName) {
    final extensionIndex = fileName.lastIndexOf('.');
    if (extensionIndex <= 0) {
      return fileName;
    }

    return fileName.substring(0, extensionIndex);
  }

  List<StoryModel> _storiesForSection(
    List<StorySectionModel> sections,
    String needle,
  ) {
    for (final section in sections) {
      if (section.title.toLowerCase().contains(needle)) {
        return section.stories;
      }
    }

    return const [];
  }

  StoryCategoryModel? _categoryFromMap(Map<String, dynamic> row) {
    final title = _firstString(row, ['title', 'name']);
    if (title.isEmpty) {
      return null;
    }

    return StoryCategoryModel(title: title);
  }

  Map<String, String> _categoryNamesById(List<Map<String, dynamic>> rows) {
    return {
      for (final row in rows)
        if (_firstString(row, ['title', 'name']).isNotEmpty)
          row['id'].toString(): _firstString(row, ['title', 'name']),
    };
  }

  List<Map<String, dynamic>> _mapRows(Object? rows) {
    if (rows is List) {
      return rows.cast<Map<String, dynamic>>();
    }

    return const [];
  }

  String _firstString(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  String _assetUrl(StorageFileApi storage, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty ||
        trimmed.startsWith('http://') ||
        trimmed.startsWith('https://')) {
      return trimmed;
    }

    return storage.getPublicUrl(trimmed);
  }

  int _orderValue(Map<String, dynamic> row) {
    final value = row['sort_order'] ?? row['display_order'];
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.round();
    }

    return 0;
  }

  int _intValue(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.round();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<T> _trackedSupabaseRequest<T>(
    String operation,
    Future<T> Function() request,
  ) {
    StoryPerformanceMetrics.instance.recordSupabaseRequest(operation);
    return request();
  }

  // Legacy text is retained only as source material; playback never reads it.
  // ignore: unused_element
  String _storyTextForPage(int pageNumber) {
    return switch (pageNumber) {
      1 =>
        'वृंदावन में, जहाँ मोर नाचते थे और यमुना नदी गुनगुनाती थी — '
            'वहाँ एक प्यारा सा बालक रहता था। उसका नाम था... कृष्ण।',
      2 =>
        'एक सुबह, जब चिड़ियाँ चहचहाने लगीं — तब भी कृष्ण अपनी '
            'मखमली पीली चादर ओढ़कर सोते रहे।',
      3 =>
        'तभी उनकी माँ यशोदा आईं। हाथ में था एक मिट्टी का घड़ा — '
            'और एक छोटी सी नीम की दातून।',
      4 =>
        '“उठो, मेरे कन्हैया,” यशोदा ने प्यार से कहा। '
            '“क्या तुम जानते हो — मोर इतना सुंदर क्यों होता है?”',
      5 => 'कृष्ण ने चादर से झाँककर पूछा — “क्या पंखों की वजह से, मैया?”',
      6 =>
        '“नहीं, कन्हैया।” यशोदा मुस्कुराईं। '
            '“मोर सूरज से पहले जागता है, मुँह धोता है, और दुनिया को '
            'ताज़े मन से नमस्कार करता है — इसलिए वह नाचता है।”',
      7 =>
        'कृष्ण आँगन में गए। उन्होंने दातून से दाँत साफ़ किए — '
            'गोल-गोल, धीरे-धीरे। फिर ठंडे पानी से मुँह धोया — '
            'और ज़ोर से हँस पड़े।',
      8 =>
        'जब सूरज की पहली किरण वृंदावन पर पड़ी — कृष्ण तैयार खड़े थे। '
            'चेहरा चमकता, मन खिला। उन्होंने महसूस किया — '
            '“जब मैं तैयार होता हूँ, तो पूरा दिन मेरा इंतज़ार करता है।”',
      9 =>
        'आज की सीख: “जब हम सुबह उठकर दाँत साफ़ करते हैं, मुँह धोते हैं, '
            'और तैयार होते हैं — तो हम अपने दिन के लिए कवच पहनते हैं। '
            'एक ताज़ी सुबह से ही खिला हुआ दिन बनता है।”',
      _ => 'कहानी का यह सुंदर पल धीरे-धीरे आगे बढ़ता है।',
    };
  }
}

class StoryRepositoryException implements Exception {
  const StoryRepositoryException(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}

class StoryLibraryFullException extends StoryRepositoryException {
  const StoryLibraryFullException()
    : super(
        'Your library is full! Delete an older story to make room, or upgrade to Premium for unlimited saves.',
      );
}
