import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_client.dart';
import 'story_model.dart';

const _imageExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.gif'};

class StoryRepository {
  const StoryRepository();

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
      pages: _mapRows(
        pageRows,
      ).map(StoryPageModel.fromMap).toList(growable: false),
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
}

extension _ListFallback<T> on List<T> {
  List<T> ifEmpty(List<T> fallback) {
    return isEmpty ? fallback : this;
  }
}
