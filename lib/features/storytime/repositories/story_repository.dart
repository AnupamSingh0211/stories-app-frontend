import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client.dart';
import '../models/story_model.dart';
import '../models/story_page.dart';

const _imageExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.gif'};
const _audioExtensions = {'.aac', '.m4a', '.mp3', '.wav'};

class StoryRepository {
  const StoryRepository();

  static const morningWhispersStoryId = 'morning-whispers';
  static const _storyAssetsBucket = 'story-assets';
  static const _storyColumns =
      'id, title, category_id, thumbnail_url, is_featured';

  Future<StorytimeContent> fetchStorytimeContent() async {
    final client = SupabaseClientProvider.client;
    final storage = client.storage.from('app-assets');
    final storageContent = await _storageStorytimeContent(storage);

    final List<dynamic> results;
    try {
      results = await Future.wait([
        client
            .from('story_categories')
            .select('id, title, name, display_order')
            .order('display_order'),
        client
            .from('story_sections')
            .select(
              'id, title, display_order, '
              'section_stories(section_id, story_id, sort_order, '
              'stories($_storyColumns))',
            )
            .order('display_order'),
        client.from('stories').select(_storyColumns),
      ]);
    } catch (error) {
      debugPrint(
        'StoryRepository: Supabase story query failed; using Storage assets. $error',
      );
      return storageContent;
    }

    final categories = _mapRows(results[0]);
    final sectionRows = _mapRows(results[1]);
    final storyRows = _mapRows(results[2]);
    final categoryNames = _categoryNamesById(categories);

    final stories = storyRows
        .map((row) => _storyFromMap(row, categoryNames, storage))
        .toList(growable: false);

    final sections = sectionRows
        .map((row) => _sectionFromMap(row, categoryNames, storage))
        .where((section) => section.stories.isNotEmpty)
        .toList(growable: false);

    if (sections.isEmpty && stories.isEmpty) {
      debugPrint(
        'StoryRepository: Supabase story tables returned 0 rows; using Storage assets.',
      );
      return storageContent;
    }

    debugPrint(
      'StoryRepository: loaded ${stories.length} stories, ${sections.length} sections, ${categories.length} categories from Supabase tables.',
    );

    final mappedCategories = categories
        .map(_categoryFromMap)
        .whereType<StoryCategoryModel>()
        .toList(growable: false);
    final forYouStories = _storiesForSection(sections, 'for you');
    final popularStories = _storiesForSection(sections, 'popular');

    return StorytimeContent(
      featuredBanners: _featuredBanners(
        storyRows,
        categoryNames,
        storage,
      ).ifEmpty(storageContent.featuredBanners),
      sections: sections.isNotEmpty ? sections : storageContent.sections,
      forYouStories: forYouStories.isNotEmpty
          ? forYouStories
          : storageContent.forYouStories,
      popularStories: popularStories.isNotEmpty
          ? popularStories
          : storageContent.popularStories,
      categories: mappedCategories.isNotEmpty
          ? mappedCategories
          : storageContent.categories,
    );
  }

  Future<FullStoryModel> fetchStoryWithPages(String storyId) async {
    final client = SupabaseClientProvider.client;
    final storage = client.storage.from('app-assets');

    final storyRow = await client
        .from('stories')
        .select(_storyColumns)
        .eq('id', storyId)
        .single();

    final categoryRows = await client
        .from('story_categories')
        .select('id, title, name, display_order')
        .order('display_order');

    final pageRows = await client
        .from('story_pages')
        .select('id, story_id, page_number, content, image_url, audio_url')
        .eq('story_id', storyId)
        .order('page_number');

    return FullStoryModel(
      story: _storyFromMap(
        storyRow,
        _categoryNamesById(_mapRows(categoryRows)),
        storage,
      ),
      pages: _mapRows(pageRows).map(_storyPageFromMap).toList(growable: false),
    );
  }

  Future<List<StoryPage>> fetchStoryPagesFromStorage() async {
    final client = SupabaseClientProvider.client;
    final storage = client.storage.from(_storyAssetsBucket);

    try {
      final results = await Future.wait([
        storage.list(
          path: 'images',
          searchOptions: const SearchOptions(
            limit: 100,
            sortBy: SortBy(column: 'name', order: 'asc'),
          ),
        ),
        storage.list(
          path: 'audio',
          searchOptions: const SearchOptions(
            limit: 100,
            sortBy: SortBy(column: 'name', order: 'asc'),
          ),
        ),
      ]);

      final images = _assetFilesByStem(
        results[0],
        folder: 'images',
        extensions: _imageExtensions,
      );
      final audio = _assetFilesByStem(
        results[1],
        folder: 'audio',
        extensions: _audioExtensions,
      );
      final stems = images.keys.where(audio.containsKey).toList(growable: false)
        ..sort(_compareChapterPageStems);

      if (stems.isEmpty) {
        debugPrint(
          'StoryRepository: story-assets list returned no matching pairs; using expected chapter asset paths.',
        );
        return _expectedStoryPages(storage);
      }

      final missingAudio = images.keys.where(
        (stem) => !audio.containsKey(stem),
      );
      final missingImages = audio.keys.where(
        (stem) => !images.containsKey(stem),
      );
      if (missingAudio.isNotEmpty || missingImages.isNotEmpty) {
        debugPrint(
          'StoryRepository: missing audio for ${missingAudio.join(', ')}; '
          'missing images for ${missingImages.join(', ')}.',
        );
      }

      return stems
          .map((stem) {
            final number = _pageNumberFromStem(stem);
            return StoryPage(
              pageNumber: number,
              imageUrl: storage.getPublicUrl(images[stem]!),
              audioUrl: storage.getPublicUrl(audio[stem]!),
              text: _storyTextForPage(number),
            );
          })
          .toList(growable: false);
    } catch (error) {
      if (error is StoryRepositoryException) {
        rethrow;
      }

      debugPrint(
        'StoryRepository: could not list story-assets; using expected chapter asset paths. $error',
      );
      return _expectedStoryPages(storage);
    }
  }

  Future<bool> isFavoriteStory(String storyId) async {
    final client = SupabaseClientProvider.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      return false;
    }

    try {
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

  StoryPage _storyPageFromMap(Map<String, dynamic> row) {
    final pageNumber = _intValue(row['page_number']);
    return StoryPage(
      pageNumber: pageNumber,
      imageUrl: _firstString(row, ['image_url']),
      audioUrl: _firstString(row, ['audio_url']),
      text: _firstString(row, [
        'content',
      ]).ifEmpty(_storyTextForPage(pageNumber)),
    );
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

  StoryModel _storyFromMap(
    Map<String, dynamic> row,
    Map<String, String> categoryNames,
    StorageFileApi storage,
  ) {
    final thumbnailUrl = _assetUrl(
      storage,
      _firstString(row, ['thumbnail_url']),
    );

    return StoryModel(
      id: row['id'].toString(),
      title: row['title'] as String,
      thumbnailUrl: thumbnailUrl,
      category: categoryNames[row['category_id']?.toString()] ?? 'Story',
      durationMinutes: 0,
    );
  }

  List<FeaturedBannerModel> _featuredBanners(
    List<Map<String, dynamic>> rows,
    Map<String, String> categoryNames,
    StorageFileApi storage,
  ) {
    final featuredRows = rows.where((row) => row['is_featured'] == true);

    return featuredRows
        .map((row) {
          final imageUrl = _firstString(row, ['thumbnail_url']);
          if (imageUrl.isEmpty) {
            return null;
          }

          return FeaturedBannerModel(
            id: row['id'].toString(),
            imageUrl: _assetUrl(storage, imageUrl),
            title: row['title'] as String,
            subtitle: categoryNames[row['category_id']?.toString()] ?? 'Story',
          );
        })
        .whereType<FeaturedBannerModel>()
        .toList(growable: false);
  }

  Future<StorytimeContent> _storageStorytimeContent(
    StorageFileApi storage,
  ) async {
    final thumbnailFiles = await _listImageFiles(
      storage,
      folder: 'story_thumbnails',
    );
    final featuredBanners = await _featuredBannersFromStorage(storage);
    final forYouStories = [
      _storageStory(
        storage: storage,
        id: 'storage-morning-whispers',
        title: 'Morning Whispers',
        category: 'Gentle',
        durationMinutes: 8,
        folder: 'story_thumbnails',
        files: thumbnailFiles,
        stems: const [
          'babyKrishna_foryou_thumbnail1',
          'babykrishna_Foryou_thumbnail1',
          'babyKrishna_Foryou_thumbnail1',
        ],
      ),
      _storageStory(
        storage: storage,
        id: 'storage-chocolate-neelam',
        title: 'The Chocolate Neelam',
        category: 'Fable',
        durationMinutes: 12,
        folder: 'story_thumbnails',
        files: thumbnailFiles,
        stems: const [
          'babykrishna_foryou_thumbnail2',
          'babykrishna_Foryou_thumbnail2',
          'babyKrishna_foryou_thumbnail2',
          'babyKrishna_Foryou_thumbnail2',
        ],
      ),
    ];
    final popularStories = [
      _storageStory(
        storage: storage,
        id: 'storage-krishna-yashoda',
        title: 'Krishna & Yashoda',
        category: 'Sleep Stories',
        durationMinutes: 15,
        folder: 'story_thumbnails',
        files: thumbnailFiles,
        stems: const [
          'babyKrishna_popularTales_thumbnail1',
          'babykrishna_popularTales_thumbnail1',
        ],
        narrator: 'Narrated by Grandma',
      ),
      _storageStory(
        storage: storage,
        id: 'storage-playful-krishna',
        title: 'Playful Krishna',
        category: 'Lullabies',
        durationMinutes: 20,
        folder: 'story_thumbnails',
        files: thumbnailFiles,
        stems: const [
          'babyKrishna_popularTales_thumbnail2',
          'babykrishna_popularTales_thumbnail2',
        ],
        narrator: 'Deep Sleep Soundscape',
      ),
    ];

    debugPrint(
      'StoryRepository: using Storage assets for ${featuredBanners.length} banners, ${forYouStories.length} For You stories, ${popularStories.length} Popular stories.',
    );

    return StorytimeContent(
      featuredBanners: featuredBanners,
      sections: [
        StorySectionModel(
          id: 'storage-for-you',
          title: 'For You',
          stories: forYouStories,
        ),
        StorySectionModel(
          id: 'storage-popular',
          title: 'Popular Tales',
          stories: popularStories,
        ),
      ],
      forYouStories: forYouStories,
      popularStories: popularStories,
      categories: const [
        StoryCategoryModel(title: 'Sleep Stories'),
        StoryCategoryModel(title: 'Happy Tales'),
        StoryCategoryModel(title: 'Lullabies'),
        StoryCategoryModel(title: 'Growth Tales'),
      ],
    );
  }

  Future<List<FeaturedBannerModel>> _featuredBannersFromStorage(
    StorageFileApi storage,
  ) async {
    final imageFiles = await _listImageFiles(
      storage,
      folder: 'featured_banners',
    );

    if (imageFiles.isNotEmpty) {
      return imageFiles
          .map((file) {
            return FeaturedBannerModel(
              id: file.id ?? file.name,
              imageUrl: storage.getPublicUrl('featured_banners/${file.name}'),
              title: _titleFromFileName(file.name),
              subtitle: 'Dreamy Tales',
            );
          })
          .toList(growable: false);
    }

    debugPrint(
      'StoryRepository: featured_banners list returned 0 files; using direct fallback banner path.',
    );

    return [
      FeaturedBannerModel(
        id: 'storage-banner-krishna-flute',
        imageUrl: storage.getPublicUrl(
          'story_thumbnails/babyKrishna_popularTales_thumbnail1.webp',
        ),
        title: 'Krishna With Flute',
        subtitle: 'Dreamy Tales',
      ),
    ];
  }

  StoryModel _storageStory({
    required StorageFileApi storage,
    required String id,
    required String title,
    required String category,
    required int durationMinutes,
    required String folder,
    required List<FileObject> files,
    required List<String> stems,
    String? narrator,
  }) {
    return StoryModel(
      id: id,
      title: title,
      thumbnailUrl: _storageImageUrl(storage, folder, files, stems),
      category: category,
      durationMinutes: durationMinutes,
      narrator: narrator,
    );
  }

  String _storageImageUrl(
    StorageFileApi storage,
    String folder,
    List<FileObject> files,
    List<String> stems,
  ) {
    final file = _findFileByStems(files, stems);
    return storage.getPublicUrl(
      '$folder/${file?.name ?? '${stems.first}.webp'}',
    );
  }

  Future<List<FileObject>> _listImageFiles(
    StorageFileApi storage, {
    required String folder,
  }) async {
    try {
      final files = await storage.list(
        path: folder,
        searchOptions: const SearchOptions(
          limit: 100,
          sortBy: SortBy(column: 'name', order: 'asc'),
        ),
      );

      return files
          .where((file) => _isImageFile(file.name))
          .toList(growable: false);
    } catch (error) {
      debugPrint('StoryRepository: could not list $folder. $error');
      return const [];
    }
  }

  FileObject? _findFileByStems(List<FileObject> files, List<String> stems) {
    final normalizedStems = stems.map(_normalizedStem).toSet();

    for (final file in files) {
      if (normalizedStems.contains(_normalizedStem(_fileStem(file.name)))) {
        return file;
      }
    }

    return null;
  }

  String _fileStem(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0) {
      return fileName;
    }

    return fileName.substring(0, dotIndex);
  }

  String _normalizedStem(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
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

  String _titleFromFileName(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    final stem = (dotIndex <= 0 ? fileName : fileName.substring(0, dotIndex))
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (stem.isEmpty) {
      return 'Dreamy Tale';
    }

    return stem
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  bool _isImageFile(String fileName) {
    final lower = fileName.toLowerCase();
    return _imageExtensions.any(lower.endsWith);
  }

  Map<String, String> _assetFilesByStem(
    List<FileObject> files, {
    required String folder,
    required Set<String> extensions,
  }) {
    final entries = <String, String>{};

    for (final file in files) {
      final lower = file.name.toLowerCase();
      if (!extensions.any(lower.endsWith)) {
        continue;
      }

      final stem = _assetStem(file.name);
      if (stem == null) {
        continue;
      }

      entries[stem] = '$folder/${file.name}';
    }

    return entries;
  }

  String? _assetStem(String fileName) {
    final stem = _fileStem(fileName);
    final match = RegExp(
      r'^(chapter\d+_page\d+)_(?:image|audio)$',
      caseSensitive: false,
    ).firstMatch(stem);

    return match?.group(1)?.toLowerCase();
  }

  int _compareChapterPageStems(String left, String right) {
    final leftParts = _chapterPageNumbers(left);
    final rightParts = _chapterPageNumbers(right);
    final chapterCompare = leftParts.$1.compareTo(rightParts.$1);
    if (chapterCompare != 0) {
      return chapterCompare;
    }

    return leftParts.$2.compareTo(rightParts.$2);
  }

  (int, int) _chapterPageNumbers(String stem) {
    final match = RegExp(
      r'^chapter(\d+)_page(\d+)$',
      caseSensitive: false,
    ).firstMatch(stem);

    return (
      int.tryParse(match?.group(1) ?? '') ?? 0,
      int.tryParse(match?.group(2) ?? '') ?? 0,
    );
  }

  int _pageNumberFromStem(String stem) {
    return _chapterPageNumbers(stem).$2;
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

  String _storyTextForPage(int pageNumber) {
    return 'Morning Whispers - Page $pageNumber';
  }

  List<StoryPage> _expectedStoryPages(StorageFileApi storage) {
    return List.generate(9, (index) {
      final pageNumber = index + 1;
      return StoryPage(
        pageNumber: pageNumber,
        imageUrl: storage.getPublicUrl(
          'images/chapter${pageNumber}_page${pageNumber}_image.png',
        ),
        audioUrl: storage.getPublicUrl(
          'audio/chapter${pageNumber}_page${pageNumber}_audio.mp3',
        ),
        text: _storyTextForPage(pageNumber),
      );
    }, growable: false);
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

extension _ListFallback<T> on List<T> {
  List<T> ifEmpty(List<T> fallback) {
    return isEmpty ? fallback : this;
  }
}

extension _StringFallback on String {
  String ifEmpty(String fallback) {
    return isEmpty ? fallback : this;
  }
}
