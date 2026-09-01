import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:page_flip/page_flip.dart';

import '../../../core/analytics_service.dart';
import '../../../shared/theme/app_border_radius.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_shadows.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../../shared/widgets/app_screen_background.dart';
import '../../auth/profile_notifier.dart';
import '../../auth/profile_repository.dart';
import '../../home/home_screen.dart';
import '../../library/library_screen.dart';
import '../../profile/profile_screen.dart';
import '../audio/background_music_resolver.dart';
import '../models/story_model.dart';
import '../models/story_page.dart';
import '../notifiers/story_player_state.dart';
import '../providers/continue_listening_provider.dart';
import '../providers/favorite_stories_provider.dart';
import '../providers/story_player_provider.dart';
import '../repositories/story_repository.dart';
import '../widgets/story_controls.dart';
import '../widgets/story_image_cache_policy.dart';
import '../widgets/story_image_view.dart';
import '../widgets/story_player_content.dart';

const bool _storyPageFlipEnabled = bool.fromEnvironment(
  'STORY_PAGE_FLIP_ENABLED',
  defaultValue: true,
);

const _episodePlayerHorizontalPadding = 16.0;
const _episodePlayerImageHeight = 636.0;
const _episodeHeaderImageGap = 13.0;
const _episodePlayerGap = 22.0;
const _episodeControlsHeight = 76.0;
const _episodeHeaderHeight = 56.0;
const _episodeSystemUiStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.light,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarContrastEnforced: false,
);

class StoryPlayerScreen extends ConsumerStatefulWidget {
  const StoryPlayerScreen({
    this.storyId = '',
    this.title = 'Story',
    this.story,
    this.initialPages = const [],
    this.openDirectly = false,
    this.playerImageUrl,
    super.key,
  });

  final String storyId;
  final String title;
  final StoryModel? story;
  final List<StoryPage> initialPages;
  final bool openDirectly;
  final String? playerImageUrl;

  @override
  ConsumerState<StoryPlayerScreen> createState() => _StoryPlayerScreenState();
}

class _StoryPlayerScreenState extends ConsumerState<StoryPlayerScreen>
    with WidgetsBindingObserver {
  static const _feedViewportFraction = 663 / 704;

  final AudioPlayer _backgroundMusicPlayer = AudioPlayer();
  final GlobalKey<_StoryPageFlipViewState> _pageFlipViewKey = GlobalKey();
  late final PageController _feedController;
  bool _hasLoadedBackgroundMusic = false;
  bool _pendingStoryStart = false;
  bool _isSynchronizingFeed = false;
  bool _hasClosedAfterCompletion = false;
  bool _didTrackCompletion = false;
  int _feedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.openDirectly) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(_episodeSystemUiStyle);
    }
    _feedController = PageController(viewportFraction: _feedViewportFraction);
    WidgetsBinding.instance.addObserver(this);
    unawaited(
      PostHogAnalytics.instance.screenOpened(
        'story_player_screen',
        properties: _storyAnalyticsProperties(
          widget.story,
          storyId: widget.storyId,
          title: widget.title,
          source: widget.openDirectly ? 'episodes_screen' : 'story_player',
        ),
      ),
    );
    if (widget.initialPages.isNotEmpty) {
      ref
          .read(storyRepositoryProvider)
          .cacheStoryPages(widget.storyId, widget.initialPages);
    }
    final story = widget.story;
    if (story != null) {
      Future.microtask(() {
        if (mounted) {
          ref.read(sessionStoryHistoryProvider.notifier).recordStory(story);
        }
      });
    }
    unawaited(
      PostHogAnalytics.instance.capture(
        'story_opened',
        properties: _storyAnalyticsProperties(
          widget.story,
          storyId: widget.storyId,
          title: widget.title,
          source: widget.openDirectly ? 'episodes_screen' : 'story_player',
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _feedController.dispose();
    unawaited(_backgroundMusicPlayer.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _saveSessionProgress();
    } else if (state == AppLifecycleState.resumed && _storyPageFlipEnabled) {
      final currentPageIndex = ref
          .read(storyPlayerProvider(widget.storyId))
          .currentPageIndex;
      unawaited(
        _pageFlipViewKey.currentState?.synchronizeTo(currentPageIndex) ??
            Future<void>.value(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = storyPlayerProvider(widget.storyId);
    final playerState = ref.watch(
      provider.select(
        (state) => (
          isFavorite: state.isFavorite,
          pages: state.pages,
          currentPageIndex: state.currentPageIndex,
        ),
      ),
    );

    ref.listen(
      provider.select(
        (state) => (
          pageCount: state.pageCount,
          currentPageIndex: state.currentPageIndex,
          isComplete: state.isComplete,
          audioDuration: state.audioDuration,
          positionBucket: state.audioPosition.inSeconds ~/ 5,
        ),
      ),
      (previous, next) {
        final currentState = ref.read(provider);
        if (currentState.pageCount == 0) {
          return;
        }

        final historyNotifier = ref.read(sessionStoryHistoryProvider.notifier);
        if (currentState.isComplete || _isAtPlaybackEnd(currentState)) {
          _trackStoryCompleted(currentState);
          historyNotifier.completeStory(widget.storyId);
          if (widget.openDirectly && !_hasClosedAfterCompletion) {
            _hasClosedAfterCompletion = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.maybePop(context);
              }
            });
          }
          return;
        }

        historyNotifier.saveProgress(
          story: widget.story ?? _fallbackStory(currentState),
          currentPageIndex: currentState.currentPageIndex,
          pageCount: currentState.pageCount,
          audioPosition: currentState.audioPosition,
          audioDuration: currentState.audioDuration,
        );
      },
    );

    ref.listen<bool>(provider.select((state) => state.isPlaying), (
      previous,
      next,
    ) {
      if (next) {
        unawaited(_playBackgroundMusic());
      } else {
        unawaited(_backgroundMusicPlayer.pause());
      }
    });

    ref.listen<String>(provider.select((state) => state.nextImageUrl), (
      previous,
      next,
    ) {
      if (next.isNotEmpty) {
        final cacheWidth = StoryImageCachePolicy.widthFor(
          logicalWidth: MediaQuery.sizeOf(context).width,
          devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
        );
        unawaited(
          precacheImage(
            StoryImageCachePolicy.provider(
              imageUrl: next,
              cacheWidth: cacheWidth,
            ),
            context,
          ).catchError((Object _) {}),
        );
      }
    });

    ref.listen<int>(provider.select((state) => state.currentPageIndex), (
      previous,
      next,
    ) {
      if (_storyPageFlipEnabled || _feedIndex == 0 || _isSynchronizingFeed) {
        return;
      }
      unawaited(_animateFeedTo(next + 1, activateAudio: false));
    });

    ref.listen<int>(provider.select((state) => state.pageCount), (
      previous,
      next,
    ) {
      if (_pendingStoryStart && next > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            unawaited(_startStory());
          }
        });
      }
    });

    if (widget.openDirectly) {
      return _EpisodeStoryPlayerScaffold(
        storyId: widget.storyId,
        favoriteStory: widget.story ?? _directEpisodeFavoriteStory(),
        imageUrl: widget.playerImageUrl ?? _defaultEpisodePlayerImageUrl(),
        onBack: _exitStory,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppScreenBackground(
        child: Column(
          children: [
            _StoryFeedHeader(
              isFavorite: playerState.isFavorite,
              onBack: _exitStory,
              onToggleFavorite: () {
                unawaited(ref.read(provider.notifier).toggleFavorite());
              },
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final gap = constraints.maxHeight * (20 / 704);
                  if (_storyPageFlipEnabled) {
                    return PageView.builder(
                      key: const ValueKey('story-vertical-feed'),
                      controller: _feedController,
                      scrollDirection: Axis.vertical,
                      padEnds: false,
                      pageSnapping: true,
                      physics: _feedIndex == 0
                          ? const NeverScrollableScrollPhysics()
                          : const PageScrollPhysics(
                              parent: ClampingScrollPhysics(),
                            ),
                      itemCount: playerState.pages.isEmpty ? 1 : 2,
                      onPageChanged: _onFeedPageChanged,
                      itemBuilder: (context, feedIndex) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: gap),
                          child: feedIndex == 0
                              ? _StoryDetailPreface(
                                  key: const ValueKey('story-detail-preface'),
                                  story: widget.story,
                                  fallbackTitle: widget.title,
                                  onStart: _startStory,
                                )
                              : _StoryPageFlipView(
                                  key: _pageFlipViewKey,
                                  storyId: widget.storyId,
                                  storyTitle:
                                      widget.story?.title ?? widget.title,
                                  pages: playerState.pages,
                                  currentPageIndex:
                                      playerState.currentPageIndex,
                                  onPageFlipped: _activateFlippedPage,
                                ),
                        );
                      },
                    );
                  }
                  return PageView.builder(
                    key: const ValueKey('story-vertical-feed'),
                    controller: _feedController,
                    scrollDirection: Axis.vertical,
                    padEnds: false,
                    pageSnapping: true,
                    physics: _feedIndex == 0
                        ? const NeverScrollableScrollPhysics()
                        : const PageScrollPhysics(
                            parent: ClampingScrollPhysics(),
                          ),
                    itemCount: playerState.pages.length + 1,
                    onPageChanged: _onFeedPageChanged,
                    itemBuilder: (context, feedIndex) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: gap),
                        child: feedIndex == 0
                            ? _StoryDetailPreface(
                                key: const ValueKey('story-detail-preface'),
                                story: widget.story,
                                fallbackTitle: widget.title,
                                onStart: _startStory,
                              )
                            : StoryPlayerContent(
                                key: ValueKey('story-page-${feedIndex - 1}'),
                                storyId: widget.storyId,
                                storyTitle: widget.story?.title ?? widget.title,
                                page: playerState.pages[feedIndex - 1],
                              ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x1A007AFF),
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: AppPrimaryBottomNavigation(
          selectedIndex: 1,
          onItemSelected: _onBottomNavigationSelected,
        ),
      ),
    );
  }

  String _defaultEpisodePlayerImageUrl() {
    return '';
  }

  Future<void> _startStory() async {
    unawaited(
      PostHogAnalytics.instance.capture(
        'story_play_clicked',
        properties: _storyAnalyticsProperties(
          widget.story,
          storyId: widget.storyId,
          title: widget.title,
          source: 'story_preface',
        ),
      ),
    );
    unawaited(
      PostHogAnalytics.instance.buttonClicked(
        buttonName: 'story_play',
        screenName: 'story_player_screen',
        properties: {
          'source': 'story_preface',
          'target_type': 'story',
          'target_id': widget.storyId,
        },
      ),
    );
    final state = ref.read(storyPlayerProvider(widget.storyId));
    if (state.isLoading || state.pages.isEmpty) {
      _pendingStoryStart = true;
      return;
    }
    _pendingStoryStart = false;
    await _animateFeedTo(
      _storyPageFlipEnabled ? 1 : state.currentPageIndex + 1,
      activateAudio: true,
    );
  }

  Future<void> _onFeedPageChanged(int feedIndex) async {
    if (mounted) {
      setState(() => _feedIndex = feedIndex);
    }
    if (_isSynchronizingFeed) {
      return;
    }
    final notifier = ref.read(storyPlayerProvider(widget.storyId).notifier);
    if (feedIndex == 0) {
      await notifier.pause();
      return;
    }
    await notifier.activatePage(
      _storyPageFlipEnabled
          ? ref.read(storyPlayerProvider(widget.storyId)).currentPageIndex
          : feedIndex - 1,
      autoPlay: true,
    );
  }

  Future<void> _activateFlippedPage(int storyPageIndex) async {
    if (!mounted) {
      return;
    }
    final provider = storyPlayerProvider(widget.storyId);
    final state = ref.read(provider);
    if (storyPageIndex < 0 ||
        storyPageIndex >= state.pageCount ||
        storyPageIndex == state.currentPageIndex) {
      return;
    }
    await ref
        .read(provider.notifier)
        .activatePage(storyPageIndex, autoPlay: true);
  }

  Future<void> _animateFeedTo(
    int targetFeedIndex, {
    required bool activateAudio,
  }) async {
    if (!_feedController.hasClients) {
      return;
    }
    final pageCount = ref.read(storyPlayerProvider(widget.storyId)).pageCount;
    final maxFeedIndex = _storyPageFlipEnabled
        ? (pageCount > 0 ? 1 : 0)
        : pageCount;
    final safeTarget = targetFeedIndex.clamp(0, maxFeedIndex).toInt();
    final current = _feedController.page?.round() ?? _feedIndex;

    _isSynchronizingFeed = true;
    try {
      if (current != safeTarget) {
        await _feedController.animateToPage(
          safeTarget,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        );
      }
      if (mounted && _feedIndex != safeTarget) {
        setState(() => _feedIndex = safeTarget);
      }
    } finally {
      _isSynchronizingFeed = false;
    }

    if (activateAudio && safeTarget > 0 && mounted) {
      final storyPageIndex = _storyPageFlipEnabled
          ? ref.read(storyPlayerProvider(widget.storyId)).currentPageIndex
          : safeTarget - 1;
      await ref
          .read(storyPlayerProvider(widget.storyId).notifier)
          .activatePage(storyPageIndex, autoPlay: true);
    }
  }

  Future<void> _exitStory() async {
    unawaited(
      PostHogAnalytics.instance.capture(
        'back_clicked',
        properties: {
          'screen_name': 'story_player_screen',
          'source': widget.openDirectly ? 'episode_player' : 'story_player',
        },
      ),
    );
    unawaited(
      PostHogAnalytics.instance.buttonClicked(
        buttonName: 'back',
        screenName: 'story_player_screen',
        properties: {
          'source': widget.openDirectly ? 'episode_player' : 'story_player',
          'target_type': 'story',
          'target_id': widget.storyId,
        },
      ),
    );
    _saveSessionProgress();
    await ref.read(storyPlayerProvider(widget.storyId).notifier).pause();
    if (mounted) {
      await Navigator.maybePop(context);
    }
  }

  Future<void> _onBottomNavigationSelected(int index) async {
    if (index == 1) {
      return;
    }

    unawaited(
      PostHogAnalytics.instance.buttonClicked(
        buttonName: 'bottom_nav_item',
        screenName: 'story_player_screen',
        properties: {'source': 'bottom_nav', 'target_index': index},
      ),
    );
    _saveSessionProgress();
    await ref.read(storyPlayerProvider(widget.storyId).notifier).pause();
    if (!mounted) {
      return;
    }

    final selectedChild = ref
        .read(profileNotifierProvider)
        .valueOrNull
        ?.selectedChild;
    switch (index) {
      case 0:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (context) => HomeScreen(
              childName: selectedChild?.childName,
              childAge: selectedChild?.age,
            ),
          ),
          (route) => false,
        );
        return;
      case 2:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (context) => const LibraryScreen()),
        );
        return;
      case 3:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (context) => ProfileScreen(
              fallbackChildName: selectedChild?.childName,
              fallbackChildAge: selectedChild?.age,
            ),
          ),
        );
        return;
    }
  }

  StoryModel _fallbackStory(StoryPlayerState state) {
    final imageUrl = state.currentImageUrl;
    return StoryModel(
      id: widget.storyId,
      title: widget.title,
      thumbnailUrl: imageUrl,
      category: 'Storytime',
      durationMinutes: 0,
      imageUrl: imageUrl,
      coverUrl: imageUrl,
    );
  }

  StoryModel _directEpisodeFavoriteStory() {
    final imageUrl =
        widget.playerImageUrl ??
        widget.story?.coverUrl ??
        widget.story?.imageUrl ??
        widget.story?.thumbnailUrl ??
        _defaultEpisodePlayerImageUrl();
    return StoryModel(
      id: widget.storyId,
      title: widget.story?.title ?? widget.title,
      thumbnailUrl: imageUrl,
      category: widget.story?.category ?? 'Episode',
      durationMinutes: widget.story?.durationMinutes ?? 0,
      imageUrl: imageUrl,
      coverUrl: imageUrl,
      narrator: widget.story?.narrator,
    );
  }

  void _saveSessionProgress() {
    final state = ref.read(storyPlayerProvider(widget.storyId));
    final historyNotifier = ref.read(sessionStoryHistoryProvider.notifier);
    if (state.isComplete) {
      historyNotifier.completeStory(widget.storyId);
      return;
    }
    if (state.pageCount == 0) {
      return;
    }

    historyNotifier.saveProgress(
      story: widget.story ?? _fallbackStory(state),
      currentPageIndex: state.currentPageIndex,
      pageCount: state.pageCount,
      audioPosition: state.audioPosition,
      audioDuration: state.audioDuration,
    );
  }

  bool _isAtPlaybackEnd(StoryPlayerState state) {
    final duration = state.audioDuration;
    if (duration <= Duration.zero ||
        state.audioPosition <= Duration.zero ||
        state.currentPageIndex < state.pageCount - 1) {
      return false;
    }

    final remaining = duration - state.audioPosition;
    return remaining <= const Duration(milliseconds: 500);
  }

  void _trackStoryCompleted(StoryPlayerState state) {
    if (_didTrackCompletion) {
      return;
    }

    _didTrackCompletion = true;
    unawaited(
      PostHogAnalytics.instance.capture(
        'story_completed',
        properties: {
          ..._storyAnalyticsProperties(
            widget.story,
            storyId: widget.storyId,
            title: widget.title,
            source: widget.openDirectly ? 'episodes_screen' : 'story_player',
          ),
          'page_count': state.pageCount,
          'current_page_index': state.currentPageIndex,
          'audio_duration_seconds': state.audioDuration.inSeconds,
        },
      ),
    );
  }

  Future<void> _playBackgroundMusic() async {
    try {
      if (!_hasLoadedBackgroundMusic) {
        final locale =
            ref
                .read(profileNotifierProvider)
                .valueOrNull
                ?.selectedChild
                ?.locale ??
            defaultProfileLocale;
        final assetPath = backgroundMusicAssetForStory(
          storyId: widget.storyId,
          locale: locale,
        );
        if (assetPath == null) {
          return;
        }

        await _backgroundMusicPlayer.setAudioSource(
          AudioSource.asset(assetPath),
        );
        await _backgroundMusicPlayer.setLoopMode(LoopMode.one);
        await _backgroundMusicPlayer.setVolume(storyBackgroundMusicVolume);
        _hasLoadedBackgroundMusic = true;
      }

      await _backgroundMusicPlayer.play();
    } catch (error) {
      debugPrint('StoryPlayerScreen: background music failed. $error');
    }
  }
}

Map<String, Object?> _storyAnalyticsProperties(
  StoryModel? story, {
  required String storyId,
  required String title,
  required String source,
}) {
  return {
    'source': source,
    'story_id': story?.id ?? storyId,
    'story_title': story?.title ?? title,
    'story_category': story?.category,
    'duration_minutes': story?.durationMinutes,
  };
}

class _StoryPageFlipView extends StatefulWidget {
  const _StoryPageFlipView({
    required this.storyId,
    required this.storyTitle,
    required this.pages,
    required this.currentPageIndex,
    required this.onPageFlipped,
    super.key,
  });

  final String storyId;
  final String storyTitle;
  final List<StoryPage> pages;
  final int currentPageIndex;
  final ValueChanged<int> onPageFlipped;

  @override
  State<_StoryPageFlipView> createState() => _StoryPageFlipViewState();
}

class _StoryPageFlipViewState extends State<_StoryPageFlipView> {
  GlobalKey<PageFlipWidgetState> _flipKey = GlobalKey<PageFlipWidgetState>();
  int? _pendingPageIndex;
  bool _isSynchronizing = false;
  int _pageSetGeneration = 0;

  @override
  void initState() {
    super.initState();
    _scheduleLivePageRestore();
  }

  @override
  void didUpdateWidget(covariant _StoryPageFlipView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameStoryPages(oldWidget.pages, widget.pages)) {
      _pageSetGeneration++;
      _pendingPageIndex = null;
      _isSynchronizing = false;
      _flipKey = GlobalKey<PageFlipWidgetState>();
      _scheduleLivePageRestore();
      return;
    }

    if (oldWidget.currentPageIndex != widget.currentPageIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(synchronizeTo(widget.currentPageIndex));
        }
      });
    }
  }

  void _scheduleLivePageRestore() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _restoreLivePageAfterJump();
      }
    });
  }

  void _restoreLivePageAfterJump() {
    // page_flip 0.2.5+1 leaves its exported notifier on the active index
    // after initialIndex/goToPage, which keeps a bitmap snapshot mounted and
    // prevents controls in the page from receiving input.
    currentPage.value = -1;
  }

  Future<void> synchronizeTo(int pageIndex) async {
    if (!mounted || widget.pages.isEmpty) {
      return;
    }

    _pendingPageIndex = pageIndex.clamp(0, widget.pages.length - 1).toInt();
    if (_isSynchronizing) {
      return;
    }

    final generation = _pageSetGeneration;
    _isSynchronizing = true;
    try {
      while (mounted &&
          generation == _pageSetGeneration &&
          _pendingPageIndex != null) {
        final target = _pendingPageIndex!;
        _pendingPageIndex = null;
        final flipState = _flipKey.currentState;
        if (flipState == null) {
          return;
        }

        final current = flipState.pageNumber;
        if (target == current) {
          continue;
        }

        if (target == current + 1) {
          await flipState.nextPage();
        } else if (target == current - 1) {
          await flipState.previousPage();
        } else {
          await flipState.goToPage(target);
          _restoreLivePageAfterJump();
        }
      }
    } finally {
      if (generation == _pageSetGeneration) {
        _isSynchronizing = false;
      }
    }
  }

  void _handlePageFlipped(int pageIndex) {
    if (_isSynchronizing ||
        pageIndex < 0 ||
        pageIndex >= widget.pages.length ||
        pageIndex == widget.currentPageIndex) {
      return;
    }
    widget.onPageFlipped(pageIndex);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pages.isEmpty) {
      return const ColoredBox(
        key: ValueKey('story-page-flip-empty'),
        color: AppColors.blue25,
      );
    }

    final initialPageIndex = widget.currentPageIndex
        .clamp(0, widget.pages.length - 1)
        .toInt();

    return ColoredBox(
      key: const ValueKey('story-page-flip'),
      color: AppColors.blue25,
      child: RepaintBoundary(
        child: ClipRect(
          child: PageFlipWidget(
            key: _flipKey,
            duration: const Duration(milliseconds: 420),
            cutoffForward: 0.8,
            cutoffPrevious: 0.1,
            backgroundColor: AppColors.blue25,
            initialIndex: initialPageIndex,
            onPageFlipped: _handlePageFlipped,
            children: List<Widget>.generate(
              widget.pages.length,
              (index) => StoryPlayerContent(
                key: ValueKey('story-page-$index'),
                storyId: widget.storyId,
                storyTitle: widget.storyTitle,
                page: widget.pages[index],
              ),
              growable: false,
            ),
          ),
        ),
      ),
    );
  }
}

bool _sameStoryPages(List<StoryPage> left, List<StoryPage> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    final leftPage = left[index];
    final rightPage = right[index];
    if (leftPage.pageNumber != rightPage.pageNumber ||
        leftPage.imageUrl != rightPage.imageUrl ||
        leftPage.audioUrl != rightPage.audioUrl ||
        leftPage.text != rightPage.text) {
      return false;
    }
  }
  return true;
}

void _showFavoriteError(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class _EpisodeStoryPlayerScaffold extends ConsumerWidget {
  const _EpisodeStoryPlayerScaffold({
    required this.storyId,
    required this.favoriteStory,
    required this.imageUrl,
    required this.onBack,
  });

  final String storyId;
  final StoryModel favoriteStory;
  final String imageUrl;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = storyPlayerProvider(storyId);
    final state = ref.watch(
      provider.select(
        (state) => (
          isPlaying: state.isPlaying,
          audioPosition: state.audioPosition,
          audioDuration: state.audioDuration,
          currentImageUrl: state.currentImageUrl,
          isEnabled: state.pages.isNotEmpty && state.errorMessage == null,
        ),
      ),
    );
    final isFavorite = ref.watch(
      favoriteStoriesProvider.select(
        (stories) => stories.any((item) => item.id == favoriteStory.id),
      ),
    );
    final contentColor = AppTokenColors.of(ref).playerOverlayIcon;
    final notifier = ref.read(provider.notifier);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _episodeSystemUiStyle,
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: AppScreenBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final playerWidth =
                  (constraints.maxWidth - _episodePlayerHorizontalPadding * 2)
                      .clamp(0.0, constraints.maxWidth);
              final safeTop = MediaQuery.paddingOf(context).top;
              final bottomSafe = MediaQuery.paddingOf(context).bottom;
              final availableHeight =
                  constraints.maxHeight - safeTop - bottomSafe;
              const contentHeight =
                  _episodeHeaderHeight +
                  _episodeHeaderImageGap +
                  _episodePlayerImageHeight +
                  _episodePlayerGap +
                  _episodeControlsHeight;
              final contentTop =
                  safeTop +
                  ((availableHeight - contentHeight) / 2)
                      .clamp(0.0, double.infinity)
                      .toDouble();

              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  _episodePlayerHorizontalPadding,
                  contentTop,
                  _episodePlayerHorizontalPadding,
                  bottomSafe,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: playerWidth,
                      height: _episodeHeaderHeight,
                      child: _EpisodePlayerHeader(
                        isFavorite: isFavorite,
                        contentColor: contentColor,
                        onBack: onBack,
                        onToggleFavorite: () {
                          unawaited(
                            ref
                                .read(favoriteStoriesProvider.notifier)
                                .toggleStory(
                                  favoriteStory,
                                  source: 'episode_player',
                                )
                                .catchError((Object error) {
                                  if (context.mounted &&
                                      error is StoryRepositoryException) {
                                    _showFavoriteError(context, error.message);
                                  }
                                }),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: _episodeHeaderImageGap),
                    _EpisodeStoryImage(
                      imageUrl: state.currentImageUrl.isNotEmpty
                          ? state.currentImageUrl
                          : imageUrl,
                      width: playerWidth,
                      height: _episodePlayerImageHeight,
                    ),
                    const SizedBox(height: _episodePlayerGap),
                    _EpisodePlayerControls(
                      width: playerWidth,
                      contentColor: contentColor,
                      isPlaying: state.isPlaying,
                      isEnabled: state.isEnabled,
                      position: state.audioPosition,
                      duration: state.audioDuration,
                      onSeek: notifier.seekTo,
                      onBackward: () {
                        unawaited(
                          PostHogAnalytics.instance.buttonClicked(
                            buttonName: 'rewind_10_seconds',
                            screenName: 'story_player_screen',
                            properties: {
                              'source': 'episode_player',
                              'target_type': 'episode',
                              'target_id': storyId,
                            },
                          ),
                        );
                        notifier.seekBy(const Duration(seconds: -10));
                      },
                      onTogglePlayback: () {
                        unawaited(
                          PostHogAnalytics.instance.capture(
                            state.isPlaying
                                ? 'story_pause_clicked'
                                : 'story_play_clicked',
                            properties: {
                              'screen_name': 'story_player_screen',
                              'source': 'episode_player',
                              'story_id': storyId,
                            },
                          ),
                        );
                        unawaited(
                          PostHogAnalytics.instance.buttonClicked(
                            buttonName: state.isPlaying
                                ? 'story_pause'
                                : 'story_play',
                            screenName: 'story_player_screen',
                            properties: {
                              'source': 'episode_player',
                              'target_type': 'episode',
                              'target_id': storyId,
                            },
                          ),
                        );
                        state.isPlaying ? notifier.pause() : notifier.play();
                      },
                      onForward: () {
                        unawaited(
                          PostHogAnalytics.instance.buttonClicked(
                            buttonName: 'forward_10_seconds',
                            screenName: 'story_player_screen',
                            properties: {
                              'source': 'episode_player',
                              'target_type': 'episode',
                              'target_id': storyId,
                            },
                          ),
                        );
                        notifier.seekBy(const Duration(seconds: 10));
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EpisodePlayerHeader extends StatelessWidget {
  const _EpisodePlayerHeader({
    required this.isFavorite,
    required this.contentColor,
    required this.onBack,
    required this.onToggleFavorite,
  });

  final bool isFavorite;
  final Color contentColor;
  final VoidCallback onBack;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 28,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Semantics(
                  button: true,
                  label: 'Back',
                  child: InkResponse(
                    onTap: onBack,
                    radius: 24,
                    child: SizedBox.square(
                      dimension: 28,
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: contentColor,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                _EpisodeGlassIconButton(
                  size: 28,
                  iconSize: 15.273,
                  semanticLabel: isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  onPressed: onToggleFavorite,
                  asset: isFavorite
                      ? 'assets/icons/new_boopi/State=Bold, Icon=Heart.svg'
                      : 'assets/icons/new_boopi/State=Default, Icon=Heart.svg',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EpisodeStoryImage extends ConsumerWidget {
  const _EpisodeStoryImage({
    required this.imageUrl,
    required this.width,
    required this.height,
  });

  final String imageUrl;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: StoryImageView(
              key: ValueKey(imageUrl),
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: AppTokenColors.of(ref).playerImageBorder,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EpisodePlayerControls extends StatelessWidget {
  const _EpisodePlayerControls({
    required this.width,
    required this.contentColor,
    required this.isPlaying,
    required this.isEnabled,
    required this.position,
    required this.duration,
    required this.onSeek,
    required this.onBackward,
    required this.onTogglePlayback,
    required this.onForward,
  });

  final double width;
  final Color contentColor;
  final bool isPlaying;
  final bool isEnabled;
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onBackward;
  final VoidCallback onTogglePlayback;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: _episodeControlsHeight,
      child: Column(
        children: [
          _EpisodeTimeline(
            position: position,
            duration: duration,
            contentColor: contentColor,
            onSeek: onSeek,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _EpisodeGlassIconButton(
                size: 28,
                iconSize: 15.273,
                semanticLabel: 'Backward',
                onPressed: isEnabled ? onBackward : null,
                asset:
                    'assets/icons/new_boopi/State=Default, Icon=Backward.svg',
              ),
              const SizedBox(width: 28),
              _EpisodeGlassIconButton(
                size: 44,
                iconSize: 24,
                semanticLabel: isPlaying ? 'Pause story' : 'Play story',
                onPressed: isEnabled ? onTogglePlayback : null,
                asset: isPlaying
                    ? 'assets/icons/new_boopi/State=Default, Icon=Pause Circle.svg'
                    : 'assets/icons/new_boopi/State=Bold, Icon=pause_fill Circle.svg',
              ),
              const SizedBox(width: 28),
              _EpisodeGlassIconButton(
                size: 28,
                iconSize: 15.273,
                semanticLabel: 'Forward',
                onPressed: isEnabled ? onForward : null,
                asset: 'assets/icons/new_boopi/State=Default, Icon=Forward.svg',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EpisodeTimeline extends ConsumerStatefulWidget {
  const _EpisodeTimeline({
    required this.position,
    required this.duration,
    required this.contentColor,
    required this.onSeek,
  });

  final Duration position;
  final Duration duration;
  final Color contentColor;
  final ValueChanged<Duration> onSeek;

  @override
  ConsumerState<_EpisodeTimeline> createState() => _EpisodeTimelineState();
}

class _EpisodeTimelineState extends ConsumerState<_EpisodeTimeline> {
  Duration? _dragPosition;

  @override
  Widget build(BuildContext context) {
    final tokenColors = AppTokenColors.of(ref);
    final displayPosition = _dragPosition ?? widget.position;
    final duration = widget.duration;
    final progress = duration.inMilliseconds <= 0
        ? 0.0
        : (displayPosition.inMilliseconds / duration.inMilliseconds).clamp(
            0.0,
            1.0,
          );

    return SizedBox(
      height: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 35,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _formatDuration(displayPosition),
                style: _timelineTextStyle.copyWith(
                  color: tokenColors.playerTimelineLabel,
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Semantics(
                  slider: true,
                  label: 'Story progress',
                  value: '${(progress * 100).round()} percent',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) {
                      final target = _positionForDrag(
                        details.localPosition.dx,
                        constraints.maxWidth,
                      );
                      if (target != null) {
                        setState(() => _dragPosition = target);
                      }
                    },
                    onTapUp: (details) {
                      final target =
                          _dragPosition ??
                          _positionForDrag(
                            details.localPosition.dx,
                            constraints.maxWidth,
                          );
                      _finishSeek(target);
                    },
                    onTapCancel: () => setState(() => _dragPosition = null),
                    onHorizontalDragStart: (details) {
                      final target = _positionForDrag(
                        details.localPosition.dx,
                        constraints.maxWidth,
                      );
                      if (target != null) {
                        setState(() => _dragPosition = target);
                      }
                    },
                    onHorizontalDragUpdate: (details) {
                      final target = _positionForDrag(
                        details.localPosition.dx,
                        constraints.maxWidth,
                      );
                      if (target != null) {
                        setState(() => _dragPosition = target);
                      }
                    },
                    onHorizontalDragEnd: (_) => _finishSeek(_dragPosition),
                    onHorizontalDragCancel: () {
                      setState(() => _dragPosition = null);
                    },
                    child: SizedBox(
                      height: 16,
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(200),
                          child: LinearProgressIndicator(
                            minHeight: 6,
                            value: progress.toDouble(),
                            backgroundColor: tokenColors.playerTimelineTrack,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              tokenColors.playerTimelineFill,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 35,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                _formatDuration(widget.duration),
                style: _timelineTextStyle.copyWith(
                  color: tokenColors.playerTimelineLabel,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Duration? _positionForDrag(double dx, double width) {
    final duration = widget.duration;
    if (duration <= Duration.zero || width <= 0) {
      return null;
    }
    final fraction = (dx / width).clamp(0.0, 1.0);
    return Duration(milliseconds: (duration.inMilliseconds * fraction).round());
  }

  void _finishSeek(Duration? target) {
    if (target == null) {
      setState(() => _dragPosition = null);
      return;
    }

    widget.onSeek(target);
    setState(() => _dragPosition = null);
  }

  static const _timelineTextStyle = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textOnPrimary,
  );

  String _formatDuration(Duration value) {
    final safeSeconds = value.inSeconds < 0 ? 0 : value.inSeconds;
    final minutes = safeSeconds ~/ 60;
    final seconds = safeSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _EpisodeGlassIconButton extends ConsumerWidget {
  const _EpisodeGlassIconButton({
    required this.size,
    required this.iconSize,
    required this.semanticLabel,
    required this.onPressed,
    required this.asset,
  });

  final double size;
  final double iconSize;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final String asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = onPressed != null;
    final tokenColors = AppTokenColors.of(ref);

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: InkResponse(
        onTap: onPressed,
        radius: size / 2,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.55,
          duration: const Duration(milliseconds: 160),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tokenColors.playerOverlayButtonBackground,
              shape: BoxShape.circle,
              border: Border.all(color: tokenColors.playerOverlayButtonBorder),
            ),
            child: SvgPicture.asset(
              asset,
              width: iconSize,
              height: iconSize,
              colorFilter: ColorFilter.mode(
                enabled
                    ? tokenColors.playerOverlayIcon
                    : tokenColors.playerSheetControlDisabled,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryFeedHeader extends StatelessWidget {
  const _StoryFeedHeader({
    required this.isFavorite,
    required this.onBack,
    required this.onToggleFavorite,
  });

  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: ColoredBox(
        color: AppColors.blue25,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _FeedHeaderButton(
                semanticLabel: 'Back',
                onPressed: onBack,
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 24,
                  color: AppColors.gray900,
                ),
              ),
              Row(
                children: [
                  _FeedHeaderButton(
                    semanticLabel: isFavorite
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                    onPressed: onToggleFavorite,
                    child: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 24,
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(width: 20),
                  _FeedHeaderButton(
                    semanticLabel: 'Download story',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Story downloads are not available yet.',
                          ),
                        ),
                      );
                    },
                    child: SvgPicture.asset(
                      'assets/icons/new_boopi/State=Default, Icon=Download.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        AppColors.gray900,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedHeaderButton extends StatelessWidget {
  const _FeedHeaderButton({
    required this.semanticLabel,
    required this.onPressed,
    required this.child,
  });

  final String semanticLabel;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox(
        width: 24,
        height: 44,
        child: InkResponse(
          onTap: onPressed,
          radius: 22,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _StoryDetailPreface extends StatefulWidget {
  const _StoryDetailPreface({
    required this.story,
    required this.fallbackTitle,
    required this.onStart,
    super.key,
  });

  final StoryModel? story;
  final String fallbackTitle;
  final VoidCallback onStart;

  @override
  State<_StoryDetailPreface> createState() => _StoryDetailPrefaceState();
}

class _StoryDetailPrefaceState extends State<_StoryDetailPreface> {
  double _verticalDrag = 0;

  @override
  Widget build(BuildContext context) {
    final story = widget.story;
    final imageUrl =
        story?.coverUrl ?? story?.imageUrl ?? story?.thumbnailUrl ?? '';
    final title = story?.title ?? widget.fallbackTitle;
    final duration = story?.durationLabel ?? '';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (_) => _verticalDrag = 0,
      onVerticalDragUpdate: (details) {
        _verticalDrag += details.primaryDelta ?? 0;
      },
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (_verticalDrag < -60 || velocity < -350) {
          widget.onStart();
        }
        _verticalDrag = 0;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final scaleX = width / 390;
          final scaleY = height / 643;
          final textScale = scaleX.clamp(0.88, 1.12);
          final overlayHeight = 202 * scaleY;

          return Stack(
            fit: StackFit.expand,
            children: [
              StoryImageView(imageUrl: imageUrl, fit: BoxFit.cover),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: overlayHeight,
                child: ColoredBox(
                  color: AppColors.surfaceBlack.withValues(alpha: 0.55),
                ),
              ),
              Positioned(
                left: 20 * scaleX,
                right: 20 * scaleX,
                bottom: (overlayHeight - 43 * scaleY),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 24 * textScale,
                          fontWeight: FontWeight.w600,
                          height: 28 / 24,
                          letterSpacing: -0.25,
                          color: AppColors.blue25,
                        ),
                      ),
                    ),
                    if (duration.isNotEmpty) ...[
                      SizedBox(width: 12 * scaleX),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12 * scaleX,
                          vertical: 4 * scaleY,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gray700.withValues(alpha: 0.67),
                          borderRadius: BorderRadius.circular(12 * scaleX),
                        ),
                        child: Text(
                          duration,
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 12 * textScale,
                            fontWeight: FontWeight.w700,
                            height: 16 / 12,
                            letterSpacing: 0.5,
                            color: AppColors.surfaceWhite,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                left: 20 * scaleX,
                right: 20 * scaleX,
                bottom: 38 * scaleY,
                height: 52 * scaleY,
                child: Semantics(
                  button: true,
                  label: 'Play $title',
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.blue500,
                          AppColors.blue400,
                          AppColors.blue500,
                        ],
                        stops: [0, 0.51442, 1],
                      ),
                      borderRadius: BorderRadius.circular(24 * scaleX),
                      border: Border.all(color: AppColors.blue600),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.blue700,
                          blurRadius: 2,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: AppColors.transparent,
                      borderRadius: BorderRadius.circular(24 * scaleX),
                      child: InkWell(
                        onTap: widget.onStart,
                        borderRadius: BorderRadius.circular(24 * scaleX),
                        child: Center(
                          child: Text(
                            'Play Now',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 16 * textScale,
                              fontWeight: FontWeight.w700,
                              height: 20 / 16,
                              color: AppColors.surfaceWhite,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlayerBodyConsumer extends ConsumerStatefulWidget {
  const _PlayerBodyConsumer({required this.storyId, required this.topControls});

  final String storyId;
  final Widget topControls;

  @override
  ConsumerState<_PlayerBodyConsumer> createState() =>
      _PlayerBodyConsumerState();
}

class _PlayerBodyConsumerState extends ConsumerState<_PlayerBodyConsumer> {
  final _pageController = PageController();
  bool _isChangingPage = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = storyPlayerProvider(widget.storyId);
    final state = ref.watch(
      provider.select(
        (state) => (
          pages: state.pages,
          currentPageIndex: state.currentPageIndex,
          pageNumber: state.pageNumber,
          pageCount: state.pageCount,
          errorMessage: state.errorMessage,
          hasNextPage: state.hasNextPage,
          hasPreviousPage: state.hasPreviousPage,
        ),
      ),
    );
    final notifier = ref.read(provider.notifier);

    ref.listen<int>(provider.select((state) => state.currentPageIndex), (
      previous,
      next,
    ) {
      final shouldAnimate = previous != null && (previous - next).abs() == 1;
      unawaited(_syncPageController(next, animate: shouldAnimate));
    });

    ref.listen<int>(provider.select((state) => state.pageCount), (
      previous,
      next,
    ) {
      if ((previous ?? 0) == 0 && next > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pageController.hasClients) {
            _pageController.jumpToPage(ref.read(provider).currentPageIndex);
          }
        });
      }
    });

    return _PlayerBody(
      pages: state.pages,
      currentPageIndex: state.currentPageIndex,
      pageNumber: state.pageNumber,
      pageCount: state.pageCount,
      errorMessage: state.errorMessage,
      pageController: _pageController,
      onPageChanged: (page) async {
        if (_isChangingPage || page == state.currentPageIndex) {
          return;
        }

        _isChangingPage = true;
        try {
          if (page > state.currentPageIndex && state.hasNextPage) {
            await notifier.nextPage();
          } else if (page < state.currentPageIndex && state.hasPreviousPage) {
            await notifier.previousPage();
          } else {
            await _syncPageController(state.currentPageIndex);
          }
        } finally {
          _isChangingPage = false;
        }
      },
      controls: _StoryControlsConsumer(storyId: widget.storyId),
      topControls: widget.topControls,
    );
  }

  Future<void> _syncPageController(int pageIndex, {bool animate = true}) async {
    if (!_pageController.hasClients) {
      return;
    }

    final currentPage = _pageController.page?.round();
    if (currentPage == pageIndex) {
      return;
    }

    _isChangingPage = true;
    try {
      if (animate) {
        await _pageController.animateToPage(
          pageIndex,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      } else {
        _pageController.jumpToPage(pageIndex);
      }
    } finally {
      _isChangingPage = false;
    }
  }
}

class _StoryControlsConsumer extends ConsumerWidget {
  const _StoryControlsConsumer({required this.storyId});

  final String storyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = storyPlayerProvider(storyId);
    final state = ref.watch(
      provider.select(
        (state) => (
          isPlaying: state.isPlaying,
          isFavorite: state.isFavorite,
          playbackSpeed: state.playbackSpeed,
          isEnabled: state.pages.isNotEmpty,
        ),
      ),
    );
    final notifier = ref.read(provider.notifier);

    return StoryControls(
      isPlaying: state.isPlaying,
      isFavorite: state.isFavorite,
      playbackSpeed: state.playbackSpeed,
      isEnabled: state.isEnabled,
      onTogglePlayback: () {
        unawaited(
          PostHogAnalytics.instance.capture(
            state.isPlaying ? 'story_pause_clicked' : 'story_play_clicked',
            properties: {
              'screen_name': 'story_player_screen',
              'source': 'story_controls',
              'story_id': storyId,
            },
          ),
        );
        unawaited(
          PostHogAnalytics.instance.buttonClicked(
            buttonName: state.isPlaying ? 'story_pause' : 'story_play',
            screenName: 'story_player_screen',
            properties: {
              'source': 'story_controls',
              'target_type': 'story',
              'target_id': storyId,
            },
          ),
        );
        state.isPlaying ? notifier.pause() : notifier.play();
      },
      onToggleFavorite: () {
        unawaited(
          PostHogAnalytics.instance.buttonClicked(
            buttonName: 'favorite',
            screenName: 'story_player_screen',
            properties: {
              'source': 'story_controls',
              'target_type': 'story',
              'target_id': storyId,
            },
          ),
        );
        notifier.toggleFavorite();
      },
      onChangeSpeed: () {
        unawaited(
          PostHogAnalytics.instance.buttonClicked(
            buttonName: 'playback_speed',
            screenName: 'story_player_screen',
            properties: {
              'source': 'story_controls',
              'target_type': 'story',
              'target_id': storyId,
            },
          ),
        );
        notifier.changeSpeed();
      },
    );
  }
}

class _PlayerBody extends StatelessWidget {
  const _PlayerBody({
    required this.pages,
    required this.currentPageIndex,
    required this.pageNumber,
    required this.pageCount,
    required this.pageController,
    required this.onPageChanged,
    required this.controls,
    required this.topControls,
    this.errorMessage,
  });

  final List<StoryPage> pages;
  final int currentPageIndex;
  final int pageNumber;
  final int pageCount;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final Widget controls;
  final Widget topControls;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return _ErrorPanel(message: errorMessage!);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final imageHeight = constraints.maxHeight * 0.78;
        final imageBottom = 8 + imageHeight;
        final controlsTop = (imageBottom + 18)
            .clamp(0.0, constraints.maxHeight - 94)
            .toDouble();

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              height: imageHeight,
              child: _StoryPageView(
                pages: pages,
                controller: pageController,
                onPageChanged: onPageChanged,
              ),
            ),
            Positioned(top: 0, left: 0, right: 0, child: topControls),
            if (pageCount > 1)
              Positioned(
                top: 82,
                right: 28,
                child: _MiniPageCounter(
                  pageNumber: pageNumber,
                  pageCount: pageCount,
                ),
              ),
            Positioned(top: controlsTop, left: 24, right: 24, child: controls),
          ],
        );
      },
    );
  }
}

class _StoryPageView extends StatelessWidget {
  const _StoryPageView({
    required this.pages,
    required this.controller,
    required this.onPageChanged,
  });

  final List<StoryPage> pages;
  final PageController controller;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.playerBorder,
        borderRadius: AppBorderRadius.panel,
        boxShadow: const [AppShadows.playerElevation],
      ),
      clipBehavior: Clip.antiAlias,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: PageView.builder(
          controller: controller,
          scrollDirection: Axis.vertical,
          reverse: false,
          physics: const PageScrollPhysics(),
          itemCount: pages.length,
          onPageChanged: onPageChanged,
          itemBuilder: (context, index) {
            return StoryImageView(
              key: ValueKey(pages[index].imageUrl),
              imageUrl: pages[index].imageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            );
          },
        ),
      ),
    );
  }
}

class _MiniPageCounter extends StatelessWidget {
  const _MiniPageCounter({required this.pageNumber, required this.pageCount});

  final int pageNumber;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.playerPurpleDeep.withValues(alpha: 0.72),
        borderRadius: AppBorderRadius.panel,
      ),
      child: Text(
        '$pageNumber / $pageCount',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.playerSurface,
          borderRadius: AppBorderRadius.panel,
          boxShadow: const [AppShadows.playerElevation],
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.playerPrimary,
                size: 38,
              ),
              const SizedBox(height: 14),
              Text(
                'Could not play story',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.playerText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.playerTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
