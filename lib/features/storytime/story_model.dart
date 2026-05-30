class StorytimeContent {
  const StorytimeContent({
    required this.featuredBanners,
    required this.forYouStories,
    required this.popularStories,
    required this.categories,
  });

  factory StorytimeContent.empty() {
    return const StorytimeContent(
      featuredBanners: [],
      forYouStories: [],
      popularStories: [],
      categories: _defaultCategories,
    );
  }

  final List<FeaturedBannerModel> featuredBanners;
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
    this.narrator,
  });

  final String id;
  final String title;
  final String thumbnailUrl;
  final String category;
  final int durationMinutes;
  final String? narrator;

  String get durationLabel => '$durationMinutes min';
}

class StoryCategoryModel {
  const StoryCategoryModel({required this.title});

  final String title;
}

const _defaultCategories = [
  StoryCategoryModel(title: 'Sleep Stories'),
  StoryCategoryModel(title: 'Happy Tales'),
  StoryCategoryModel(title: 'Lullabies'),
  StoryCategoryModel(title: 'Growth Tales'),
];
