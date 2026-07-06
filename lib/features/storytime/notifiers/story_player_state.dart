import '../models/story_page.dart';

class StoryPlayerState {
  const StoryPlayerState({
    this.pages = const [],
    this.currentPageIndex = 0,
    this.isPlaying = false,
    this.isFavorite = false,
    this.playbackSpeed = 1,
    this.audioPosition = Duration.zero,
    this.audioDuration = Duration.zero,
    this.isLoading = false,
    this.isComplete = false,
    this.errorMessage,
  });

  factory StoryPlayerState.initial() {
    return const StoryPlayerState();
  }

  final List<StoryPage> pages;
  final int currentPageIndex;
  final bool isPlaying;
  final bool isFavorite;
  final double playbackSpeed;
  final Duration audioPosition;
  final Duration audioDuration;
  final bool isLoading;
  final bool isComplete;
  final String? errorMessage;

  StoryPage? get currentPage {
    if (pages.isEmpty ||
        currentPageIndex < 0 ||
        currentPageIndex >= pages.length) {
      return null;
    }

    return pages[currentPageIndex];
  }

  String get currentImageUrl => currentPage?.imageUrl ?? '';
  String get currentAudioUrl => currentPage?.audioUrl ?? '';
  String get currentStoryText => currentPage?.text ?? '';
  String get nextImageUrl =>
      hasNextPage ? pages[currentPageIndex + 1].imageUrl : '';
  String get nextAudioUrl =>
      hasNextPage ? pages[currentPageIndex + 1].audioUrl : '';
  bool get hasPreviousPage => currentPageIndex > 0;
  bool get hasNextPage => currentPageIndex < pages.length - 1;
  double get progress =>
      pages.isEmpty ? 0 : (currentPageIndex + 1) / pages.length;
  int get pageCount => pages.length;
  int get pageNumber => currentPage?.pageNumber ?? 0;

  StoryPlayerState copyWith({
    List<StoryPage>? pages,
    int? currentPageIndex,
    bool? isPlaying,
    bool? isFavorite,
    double? playbackSpeed,
    Duration? audioPosition,
    Duration? audioDuration,
    bool? isLoading,
    bool? isComplete,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StoryPlayerState(
      pages: pages ?? this.pages,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      isFavorite: isFavorite ?? this.isFavorite,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      audioPosition: audioPosition ?? this.audioPosition,
      audioDuration: audioDuration ?? this.audioDuration,
      isLoading: isLoading ?? this.isLoading,
      isComplete: isComplete ?? this.isComplete,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
