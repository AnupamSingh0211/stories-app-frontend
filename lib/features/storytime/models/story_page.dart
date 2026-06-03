class StoryPage {
  const StoryPage({
    required this.pageNumber,
    required this.imageUrl,
    required this.audioUrl,
    required this.text,
  });

  final int pageNumber;
  final String imageUrl;
  final String audioUrl;
  final String text;
}

typedef StoryPageModel = StoryPage;
