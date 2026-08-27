import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend_api_client.dart';
import '../../../core/performance/story_performance_metrics.dart';
import '../../../core/supabase_client.dart';
import '../../auth/auth_provider.dart';
import '../models/story_model.dart';
import '../models/story_page.dart';
import 'story_page_memory_cache.dart';
import 'storytime_content_memory_cache.dart';

class StoryRepository {
  const StoryRepository({BackendApiClient? apiClient}) : _apiClient = apiClient;

  final BackendApiClient? _apiClient;

  // Transitional: story, saved-library, and storage reads still use Supabase here
  // until Headings 7-8 migrate each domain to backend-shaped APIs.
  static final Set<String> _favoriteStoryCardIds = {};
  static final Set<String> _favoriteStoryIds = {};
  static final Set<String> _savedStoryIds = {};

  static const savedStoryLimit = 10;
  static const _storyAssetsBucket = 'story-assets';
  static const _storyColumns =
      'id, title, category_id, thumbnail_url, cover_url, duration_seconds, '
      'is_featured, created_at, story_card_id, sort_order';
  static const _storyCardColumns =
      'id, title, thumbnail_url, hero_banner_url, category, sort_order';
  static final StoryPageMemoryCache _storyPageCache = StoryPageMemoryCache();
  static final StorytimeContentMemoryCache _storytimeContentCache =
      StorytimeContentMemoryCache();
  static Future<StorytimeContent>? _storytimeContentRequest;

  BackendApiClient get _requiredApiClient {
    final apiClient = _apiClient;
    if (apiClient == null) {
      throw const StoryRepositoryException(
        'Backend API client is required for this story operation.',
      );
    }
    return apiClient;
  }

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
    try {
      final rows = await _requiredApiClient.getList('/api/v1/stories/cards');
      return rows.map(_storyCardFromBackendMap).toList(growable: false);
    } on BackendApiException catch (error) {
      debugPrint('StoryRepository: backend story card query failed. $error');
      throw StoryRepositoryException(error.message);
    } catch (error) {
      debugPrint('StoryRepository: backend story card query failed. $error');
      throw const StoryRepositoryException('Story cards could not be loaded.');
    }
  }

  Future<List<StoryModel>> fetchStoriesForCard(String storyCardId) async {
    try {
      final rows = await _requiredApiClient.getList(
        '/api/v1/stories/cards/$storyCardId/stories',
      );
      return rows.map(_storyFromBackendMap).toList(growable: false);
    } on BackendApiException catch (error) {
      debugPrint(
        'StoryRepository: backend story card stories query failed. $error',
      );
      throw StoryRepositoryException(error.message);
    } catch (error) {
      debugPrint(
        'StoryRepository: backend story card stories query failed. $error',
      );
      throw const StoryRepositoryException(
        'Stories for this card could not be loaded.',
      );
    }
  }

  Future<StorytimeContent> _loadStorytimeContent() async {
    try {
      final data = await _requiredApiClient.getObject(
        '/api/v1/stories/content',
      );
      final content = _storytimeContentFromBackendMap(data);
      if (content.sections.isNotEmpty) {
        debugPrint(
          'StoryRepository: loaded storytime content from backend API.',
        );
        return content;
      }
      throw const StoryRepositoryException(
        'No stories are configured in the backend.',
      );
    } on BackendApiException catch (error) {
      debugPrint('StoryRepository: backend storytime content failed. $error');
      throw StoryRepositoryException(error.message);
    } catch (error) {
      debugPrint('StoryRepository: backend storytime content failed. $error');
      throw const StoryRepositoryException(
        'Stories could not be loaded from the backend.',
      );
    }
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

    try {
      final results = await Future.wait<dynamic>([
        _requiredApiClient.getObject('/api/v1/stories/$storyId'),
        pagesFuture,
      ]);

      return FullStoryModel(
        story: _storyFromBackendMap(results[0] as Map<String, dynamic>),
        pages: results[1] as List<StoryPage>,
      );
    } catch (error) {
      debugPrint('StoryRepository: backend story lookup failed. $error');
      rethrow;
    }
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
      final pages = await _fetchBackendEpisodePages(storyId);

      if (pages.isEmpty) {
        throw const StoryRepositoryException(
          'This story has no episodes configured in the database.',
        );
      }

      if (pages.any((page) => page.imageUrl.isEmpty || page.audioUrl.isEmpty)) {
        throw const StoryRepositoryException(
          'This story has an episode with a missing image or audio path.',
        );
      }

      _storyPageCache.put(storyId, pages);
      return pages;
    } catch (error) {
      debugPrint(
        'StoryRepository: backend story episodes unavailable for $storyId. $error',
      );
      throw const StoryRepositoryException(
        'Story episodes could not be loaded from the database.',
      );
    }
  }

  Future<List<StoryPage>> _fetchBackendEpisodePages(String storyId) async {
    final rows = await _requiredApiClient.getList(
      '/api/v1/stories/$storyId/episodes',
    );
    return rows.map(_storyPageFromBackendMap).toList(growable: false);
  }

  Future<List<StoryModel>> fetchFavoriteStories({String? profileId}) async {
    if (kUseAuthBypass) {
      final storyIds = _favoriteStoryIds.toList();
      if (storyIds.isEmpty) return const [];

      final client = SupabaseClientProvider.client;
      final rows = await _trackedSupabaseRequest(
        'stories.favorite_bypass.select',
        () async => client
            .from('stories')
            .select(_storyColumns)
            .inFilter('id', storyIds),
      );
      return _storyModelsFromRows(client, _mapRows(rows));
    }

    final selectedProfileId = profileId?.trim();
    if (selectedProfileId == null || selectedProfileId.isEmpty) {
      return const [];
    }

    try {
      final rows = await _requiredApiClient.getList(
        '/api/v1/favorites/stories',
        authenticated: true,
        queryParameters: {'profile_id': selectedProfileId},
      );
      return rows.map(_storyFromBackendMap).toList(growable: false);
    } on BackendApiException catch (error) {
      debugPrint(
        'StoryRepository: favorite stories backend load failed. $error',
      );
      throw StoryRepositoryException(error.message);
    } catch (error) {
      debugPrint('StoryRepository: favorite stories load failed. $error');
      throw const StoryRepositoryException(
        'Favorite stories could not be loaded.',
      );
    }
  }

  Future<List<StoryCardModel>> fetchFavoriteStoryCards({
    String? profileId,
  }) async {
    if (kUseAuthBypass) {
      final cardIds = _favoriteStoryCardIds.toList();
      if (cardIds.isEmpty) return const [];

      final client = SupabaseClientProvider.client;
      final rows = await _trackedSupabaseRequest(
        'story_cards.favorite_bypass.select',
        () async => client
            .from('story_cards')
            .select(_storyCardColumns)
            .inFilter('id', cardIds),
      );
      return _mapRows(rows).map(_storyCardFromBackendMap).toList(
        growable: false,
      );
    }

    final selectedProfileId = profileId?.trim();
    if (selectedProfileId == null || selectedProfileId.isEmpty) {
      return const [];
    }

    try {
      final rows = await _requiredApiClient.getList(
        '/api/v1/favorites/story-cards',
        authenticated: true,
        queryParameters: {'profile_id': selectedProfileId},
      );
      return rows.map(_storyCardFromBackendMap).toList(growable: false);
    } on BackendApiException catch (error) {
      debugPrint(
        'StoryRepository: favorite story cards backend load failed. $error',
      );
      throw StoryRepositoryException(error.message);
    } catch (error) {
      debugPrint('StoryRepository: favorite story cards load failed. $error');
      throw const StoryRepositoryException(
        'Favorite story cards could not be loaded.',
      );
    }
  }

  Future<void> addFavoriteStoryCard(
    String storyCardId, {
    String? profileId,
  }) async {
    if (kUseAuthBypass) {
      _favoriteStoryCardIds.add(storyCardId);
      return;
    }

    final selectedProfileId = profileId?.trim();
    if (selectedProfileId == null || selectedProfileId.isEmpty) {
      throw const StoryRepositoryException(
        'Please select a child profile before saving favorites.',
      );
    }

    try {
      await _requiredApiClient.postObject(
        '/api/v1/favorites/story-cards',
        authenticated: true,
        body: {
          'profile_id': selectedProfileId,
          'story_card_id': storyCardId,
        },
      );
    } on BackendApiException catch (error) {
      debugPrint('StoryRepository: favorite story card insert failed. $error');
      throw StoryRepositoryException(error.message);
    } catch (error) {
      debugPrint('StoryRepository: favorite story card insert failed. $error');
      throw const StoryRepositoryException(
        'Favorite story card could not be saved. Please try again.',
      );
    }
  }

  Future<void> removeFavoriteStoryCard(
    String storyCardId, {
    String? profileId,
  }) async {
    if (kUseAuthBypass) {
      _favoriteStoryCardIds.remove(storyCardId);
      return;
    }

    final selectedProfileId = profileId?.trim();
    if (selectedProfileId == null || selectedProfileId.isEmpty) {
      throw const StoryRepositoryException(
        'Please select a child profile before updating favorites.',
      );
    }

    try {
      await _requiredApiClient.delete(
        '/api/v1/favorites/story-cards/$storyCardId',
        authenticated: true,
        queryParameters: {'profile_id': selectedProfileId},
      );
    } on BackendApiException catch (error) {
      debugPrint('StoryRepository: favorite story card delete failed. $error');
      throw StoryRepositoryException(error.message);
    } catch (error) {
      debugPrint('StoryRepository: favorite story card delete failed. $error');
      throw const StoryRepositoryException(
        'Favorite story card could not be removed. Please try again.',
      );
    }
  }

  Future<bool> isFavoriteStory(String storyId, {String? profileId}) async {
    if (kUseAuthBypass) {
      return _favoriteStoryIds.contains(storyId);
    }

    try {
      final favorites = await fetchFavoriteStories(profileId: profileId);
      return favorites.any((story) => story.id == storyId);
    } catch (error) {
      debugPrint('StoryRepository: favorite lookup failed. $error');
      throw const StoryRepositoryException(
        'Favorite status could not be loaded.',
      );
    }
  }

  Future<void> addFavoriteStory(String storyId, {String? profileId}) async {
    if (kUseAuthBypass) {
      _favoriteStoryIds.add(storyId);
      return;
    }

    final selectedProfileId = profileId?.trim();
    if (selectedProfileId == null || selectedProfileId.isEmpty) {
      throw const StoryRepositoryException(
        'Please select a child profile before saving favorites.',
      );
    }

    try {
      await _requiredApiClient.postObject(
        '/api/v1/favorites/stories',
        authenticated: true,
        body: {'profile_id': selectedProfileId, 'story_id': storyId},
      );
    } on BackendApiException catch (error) {
      debugPrint('StoryRepository: favorite insert failed. $error');
      throw StoryRepositoryException(error.message);
    } catch (error) {
      debugPrint('StoryRepository: favorite insert failed. $error');
      throw const StoryRepositoryException(
        'Favorite could not be saved. Please try again.',
      );
    }
  }

  Future<void> removeFavoriteStory(String storyId, {String? profileId}) async {
    if (kUseAuthBypass) {
      _favoriteStoryIds.remove(storyId);
      return;
    }

    final selectedProfileId = profileId?.trim();
    if (selectedProfileId == null || selectedProfileId.isEmpty) {
      throw const StoryRepositoryException(
        'Please select a child profile before updating favorites.',
      );
    }

    try {
      await _requiredApiClient.delete(
        '/api/v1/favorites/stories/$storyId',
        authenticated: true,
        queryParameters: {'profile_id': selectedProfileId},
      );
    } on BackendApiException catch (error) {
      debugPrint('StoryRepository: favorite delete failed. $error');
      throw StoryRepositoryException(error.message);
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

  StoryModel _storyFromMap(
    Map<String, dynamic> row,
    Map<String, String> categoryNames,
    StorageFileApi storage,
  ) {
    final durationSeconds = _intValue(row['duration_seconds']);
    final thumbnailUrl = _assetUrl(
      storage,
      _firstString(row, ['thumbnail_url']),
      defaultFolder: 'story_cards',
    );

    return StoryModel(
      id: row['id'].toString(),
      title: row['title'] as String,
      thumbnailUrl: thumbnailUrl,
      category: categoryNames[row['category_id']?.toString()] ?? 'Story',
      durationMinutes: durationSeconds <= 0
          ? 0
          : (durationSeconds / Duration.secondsPerMinute).ceil(),
      imageUrl: _assetUrl(
        storage,
        _firstString(row, ['cover_url']),
        defaultFolder: 'story_cards',
      ),
      coverUrl: _assetUrl(
        storage,
        _firstString(row, ['cover_url']),
        defaultFolder: 'story_cards',
      ),
    );
  }

  StoryModel _storyFromBackendMap(Map<String, dynamic> row) {
    final durationMinutes =
        _nullableIntValue(row['durationMinutes']) ??
        _nullableIntValue(row['duration_minutes']) ??
        _durationMinutesFromSeconds(row['durationSeconds']) ??
        _durationMinutesFromSeconds(row['duration_seconds']) ??
        0;
    final thumbnailUrl = _firstString(row, [
      'thumbnailUrl',
      'thumbnail_url',
      'imageUrl',
      'image_url',
      'coverUrl',
      'cover_url',
    ]);
    final coverUrl = _firstString(row, ['coverUrl', 'cover_url']);
    final imageUrl = _firstString(row, ['imageUrl', 'image_url']);

    return StoryModel(
      id: row['id'].toString(),
      title: _firstNonEmptyString([
        _firstString(row, ['title']),
        'Story',
      ]),
      thumbnailUrl: thumbnailUrl,
      category: _firstNonEmptyString([
        _firstString(row, ['category']),
        'Story',
      ]),
      durationMinutes: durationMinutes,
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
      coverUrl: coverUrl.isEmpty ? null : coverUrl,
    );
  }

  StorytimeContent _storytimeContentFromBackendMap(Map<String, dynamic> row) {
    final sections = _listOfMaps(
      row['sections'],
    ).map(_sectionFromBackendMap).toList(growable: false);

    return StorytimeContent(
      featuredBanners: _listOfMaps(
        row['featuredBanners'],
      ).map(_featuredBannerFromBackendMap).toList(growable: false),
      sections: sections,
      forYouStories: _listOfMaps(
        row['forYouStories'],
      ).map(_storyFromBackendMap).toList(growable: false),
      popularStories: _listOfMaps(
        row['popularStories'],
      ).map(_storyFromBackendMap).toList(growable: false),
      categories: _listOfMaps(row['categories'])
          .map(_categoryFromMap)
          .whereType<StoryCategoryModel>()
          .toList(growable: false),
    );
  }

  FeaturedBannerModel _featuredBannerFromBackendMap(Map<String, dynamic> row) {
    return FeaturedBannerModel(
      id: row['id'].toString(),
      imageUrl: _firstString(row, ['imageUrl', 'image_url']),
      title: _firstNonEmptyString([
        _firstString(row, ['title']),
        'Story',
      ]),
      subtitle: _firstString(row, ['subtitle']),
    );
  }

  StoryCardModel _storyCardFromBackendMap(Map<String, dynamic> row) {
    return StoryCardModel(
      id: row['id'].toString(),
      title: _firstNonEmptyString([
        _firstString(row, ['title']),
        'Story card',
      ]),
      thumbnailUrl: _firstString(row, ['thumbnailUrl', 'thumbnail_url']),
      heroBannerUrl: _firstString(row, ['heroBannerUrl', 'hero_banner_url']),
      category: _firstNonEmptyString([
        _firstString(row, ['category']),
        'Story',
      ]),
      sortOrder:
          _nullableIntValue(row['sortOrder']) ??
          _nullableIntValue(row['sort_order']) ??
          0,
    );
  }

  StorySectionModel _sectionFromBackendMap(Map<String, dynamic> row) {
    return StorySectionModel(
      id: row['id'].toString(),
      title: _firstNonEmptyString([
        _firstString(row, ['title']),
        'Stories',
      ]),
      stories: _listOfMaps(
        row['stories'],
      ).map(_storyFromBackendMap).toList(growable: false),
    );
  }

  StoryPage _storyPageFromBackendMap(Map<String, dynamic> row) {
    return StoryPage(
      pageNumber:
          _nullableIntValue(row['pageNumber']) ??
          _nullableIntValue(row['page_number']) ??
          0,
      imageUrl: _firstString(row, ['imageUrl', 'image_url']),
      audioUrl: _firstString(row, ['audioUrl', 'audio_url']),
      text: _firstString(row, ['text', 'hindi_text', 'english_text']),
    );
  }

  int? _durationMinutesFromSeconds(Object? value) {
    final seconds = _nullableIntValue(value);
    if (seconds == null || seconds <= 0) return null;
    return (seconds / Duration.secondsPerMinute).ceil();
  }

  Future<List<StoryModel>> _storyModelsFromRows(
    SupabaseClient client,
    List<Map<String, dynamic>> rows,
  ) async {
    final storage = client.storage.from(_storyAssetsBucket);
    final categories = await client
        .from('story_categories')
        .select('id, title, display_order')
        .order('display_order');
    final categoryNames = _categoryNamesById(_mapRows(categories));

    return rows
        .map((row) => _storyFromMap(row, categoryNames, storage))
        .toList(growable: false);
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

  List<Map<String, dynamic>> _listOfMaps(Object? rows) {
    if (rows is List) {
      return rows
          .whereType<Map>()
          .map((row) {
            if (row is Map<String, dynamic>) return row;
            return row.map((key, value) => MapEntry(key.toString(), value));
          })
          .toList(growable: false);
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

  String _firstNonEmptyString(List<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }

    return '';
  }

  String _assetUrl(
    StorageFileApi storage,
    String value, {
    String? defaultFolder,
  }) {
    final trimmed = value.trim();
    if (trimmed.isEmpty ||
        trimmed.startsWith('http://') ||
        trimmed.startsWith('https://')) {
      return trimmed;
    }

    final path = defaultFolder != null && !trimmed.contains('/')
        ? '$defaultFolder/$trimmed'
        : trimmed;
    return storage.getPublicUrl(path);
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

  int? _nullableIntValue(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }

  Future<T> _trackedSupabaseRequest<T>(
    String operation,
    Future<T> Function() request,
  ) {
    StoryPerformanceMetrics.instance.recordSupabaseRequest(operation);
    return request();
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
