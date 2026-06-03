class StorytimeContent {
  const StorytimeContent({
    required this.featuredBanners,
    required this.sections,
    required this.forYouStories,
    required this.popularStories,
    required this.categories,
  });

  factory StorytimeContent.empty() {
    return const StorytimeContent(
      featuredBanners: [],
      sections: [],
      forYouStories: [],
      popularStories: [],
      categories: [],
    );
  }

  final List<FeaturedBannerModel> featuredBanners;
  final List<StorySectionModel> sections;
  final List<StoryModel> forYouStories;
  final List<StoryModel> popularStories;
  final List<StoryCategoryModel> categories;
}

class FeaturedBannerModel {
  const FeaturedBannerModel({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String imageUrl;
  final String title;
  final String subtitle;
}

class StoryModel {
  const StoryModel({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.category,
    required this.durationMinutes,
    this.imageUrl,
    this.coverUrl,
    this.narrator,
  });

  final String id;
  final String title;
  final String thumbnailUrl;
  final String category;
  final int durationMinutes;
  final String? imageUrl;
  final String? coverUrl;
  final String? narrator;

  String get durationLabel => '$durationMinutes min';
}

class StorySectionModel {
  const StorySectionModel({
    required this.id,
    required this.title,
    required this.stories,
  });

  final String id;
  final String title;
  final List<StoryModel> stories;
}

class FullStoryModel {
  const FullStoryModel({required this.story, required this.pages});

  final StoryModel story;
  final List<StoryPageModel> pages;
}

class StoryPageModel {
  const StoryPageModel({
    required this.id,
    required this.storyId,
    required this.pageNumber,
    required this.content,
    this.imageUrl,
    this.audioUrl,
  });

  factory StoryPageModel.fromMap(Map<String, dynamic> row) {
    return StoryPageModel(
      id: row['id'].toString(),
      storyId: row['story_id'].toString(),
      pageNumber: row['page_number'] as int,
      content: row['content'] as String,
      imageUrl: row['image_url'] as String?,
      audioUrl: row['audio_url'] as String?,
    );
  }

  final String id;
  final String storyId;
  final int pageNumber;
  final String content;
  final String? imageUrl;
  final String? audioUrl;
}

class StoryCategoryModel {
  const StoryCategoryModel({required this.title});

  final String title;
}
