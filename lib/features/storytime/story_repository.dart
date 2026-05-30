import 'package:supabase_flutter/supabase_flutter.dart';

import 'story_model.dart';

const _imageExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.gif'};

class StoryRepository {
  const StoryRepository();

  Future<StorytimeContent> fetchStorytimeContent() async {
    final storage = Supabase.instance.client.storage.from('app-assets');

    try {
      final featuredFiles =
          await _listFiles(storage: storage, folder: 'featured_banners').then(
            (files) => files.where((file) => _isImageFile(file.name)).toList(),
          );
      final thumbnailFiles = await _listFiles(
        storage: storage,
        folder: 'story_thumbnails',
      );

      return StorytimeContent(
        featuredBanners: _featuredBanners(storage, featuredFiles),
        forYouStories: _orderedStories(
          storage: storage,
          files: thumbnailFiles,
          folder: 'story_thumbnails',
          specs: const [
            _StoryAssetSpec(
              fileStem: 'babyKrishna_foryou_thumbnail1',
              title: 'Morning Whispers',
              durationMinutes: 8,
              category: 'Gentle',
            ),
            _StoryAssetSpec(
              fileStem: 'babyKrishna_foryou_thumbnail2',
              title: 'The Chocolate Neelam',
              durationMinutes: 12,
              category: 'Fable',
            ),
          ],
        ),
        popularStories: _orderedStories(
          storage: storage,
          files: thumbnailFiles,
          folder: 'story_thumbnails',
          specs: const [
            _StoryAssetSpec(
              fileStem: 'popular_stories_Image1',
              alternateFileStems: ['popular_stories_Images1'],
              title: 'Krishna & Yashoda',
              durationMinutes: 15,
              category: 'Sleep Stories',
              narrator: 'Narrated by Grandma',
            ),
            _StoryAssetSpec(
              fileStem: 'popular_stories_Images2',
              alternateFileStems: ['popular_stories_Image2'],
              title: 'Playful Krishna',
              durationMinutes: 20,
              category: 'Lullabies',
              narrator: 'Deep Sleep Soundscape',
            ),
          ],
        ),
        categories: StorytimeContent.empty().categories,
      );
    } on StorageException {
      return StorytimeContent.empty();
    }
  }

  Future<List<FileObject>> _listFiles({
    required StorageFileApi storage,
    required String folder,
  }) async {
    final files = await storage.list(
      path: folder,
      searchOptions: const SearchOptions(
        limit: 100,
        sortBy: SortBy(column: 'name', order: 'asc'),
      ),
    );

    return files.toList(growable: false);
  }

  List<FeaturedBannerModel> _featuredBanners(
    StorageFileApi storage,
    List<FileObject> files,
  ) {
    return files
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final file = entry.value;

          return FeaturedBannerModel(
            id: file.id ?? file.name,
            imageUrl: storage.getPublicUrl('featured_banners/${file.name}'),
            title: _bannerTitle(file.name, index),
            subtitle: index == 0 ? 'Featured bedtime story' : 'Dreamy Tales',
          );
        })
        .toList(growable: false);
  }

  List<StoryModel> _orderedStories({
    required StorageFileApi storage,
    required List<FileObject> files,
    required String folder,
    required List<_StoryAssetSpec> specs,
  }) {
    return specs
        .map((spec) {
          final file = _findByAnyStem(files, spec.fileStems);
          if (file == null) {
            return null;
          }

          return StoryModel(
            id: file.id ?? spec.fileStem,
            title: spec.title,
            thumbnailUrl: storage.getPublicUrl('$folder/${file.name}'),
            category: spec.category,
            durationMinutes: spec.durationMinutes,
            narrator: spec.narrator,
          );
        })
        .whereType<StoryModel>()
        .toList(growable: false);
  }

  FileObject? _findByAnyStem(List<FileObject> files, List<String> stems) {
    for (final stem in stems) {
      final file = _findByStem(files, stem);
      if (file != null) {
        return file;
      }
    }

    return null;
  }

  FileObject? _findByStem(List<FileObject> files, String stem) {
    final normalizedStem = _normalizedStem(stem);

    for (final file in files) {
      if (_normalizedStem(_fileStem(file.name)) == normalizedStem) {
        return file;
      }
    }

    return null;
  }

  String _normalizedStem(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String _bannerTitle(String fileName, int index) {
    final stem = _fileStem(
      fileName,
    ).replaceAll(RegExp(r'[_-]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

    if (stem.isEmpty) {
      return index == 0 ? 'Dreamy Tales' : 'Bedtime Story';
    }

    return stem
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String _fileStem(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0) {
      return fileName;
    }

    return fileName.substring(0, dotIndex);
  }

  bool _isImageFile(String fileName) {
    final lower = fileName.toLowerCase();
    return _imageExtensions.any(lower.endsWith);
  }
}

class _StoryAssetSpec {
  const _StoryAssetSpec({
    required this.fileStem,
    required this.title,
    required this.durationMinutes,
    required this.category,
    this.alternateFileStems = const [],
    this.narrator,
  });

  final String fileStem;
  final List<String> alternateFileStems;
  final String title;
  final int durationMinutes;
  final String category;
  final String? narrator;

  List<String> get fileStems => [fileStem, ...alternateFileStems];
}
