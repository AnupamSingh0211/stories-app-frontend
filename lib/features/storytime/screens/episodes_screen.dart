import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/analytics_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_tokens.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/app_screen_background.dart';
import '../models/story_model.dart';
import '../providers/continue_listening_provider.dart';
import '../providers/story_player_provider.dart';
import '../widgets/story_image_view.dart';
import 'story_player_screen.dart';

const _baseWidth = 390.0;
const _episodeHeroWidth = 359.0;
const _episodeHeroHeight = 202.0;

class EpisodesScreen extends ConsumerStatefulWidget {
  const EpisodesScreen({this.storyCard, super.key});

  final StoryCardModel? storyCard;

  @override
  ConsumerState<EpisodesScreen> createState() => _EpisodesScreenState();
}

class _EpisodesScreenState extends ConsumerState<EpisodesScreen> {
  final ScrollController _episodesScrollController = ScrollController();
  bool _hasTrackedStoryListEnd = false;

  @override
  void initState() {
    super.initState();
    _episodesScrollController.addListener(_trackStoryListEndIfNeeded);
    unawaited(
      PostHogAnalytics.instance.screenOpened(
        'episodes_screen',
        properties: {
          'source': 'story_card',
          'story_card_id': widget.storyCard?.id,
        },
      ),
    );
    unawaited(
      PostHogAnalytics.instance.capture(
        'story_list_viewed',
        properties: {
          'screen_name': 'episodes_screen',
          'source': 'episodes_list',
          'story_card_id': widget.storyCard?.id,
          'story_card_title': widget.storyCard?.title,
        },
      ),
    );
  }

  @override
  void dispose() {
    _episodesScrollController
      ..removeListener(_trackStoryListEndIfNeeded)
      ..dispose();
    super.dispose();
  }

  void _trackStoryListEndIfNeeded() {
    if (_hasTrackedStoryListEnd || !_episodesScrollController.hasClients) {
      return;
    }

    final position = _episodesScrollController.position;
    if (position.maxScrollExtent <= 0) {
      return;
    }

    const bottomThreshold = 80.0;
    final isNearBottom =
        position.pixels >= position.maxScrollExtent - bottomThreshold;
    if (!isNearBottom) {
      return;
    }

    _hasTrackedStoryListEnd = true;
    unawaited(
      PostHogAnalytics.instance.capture(
        'story_list_end_reached',
        properties: {
          'screen_name': 'episodes_screen',
          'source': 'episodes_list',
          'story_card_id': widget.storyCard?.id,
          'story_card_title': widget.storyCard?.title,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCard = widget.storyCard;
    final cmsStoriesState = selectedCard == null
        ? null
        : ref.watch(storyCardStoriesProvider(selectedCard.id));
    final history = ref.watch(sessionStoryHistoryProvider);
    final contentColor = AppTokenColors.of(ref).homeCardTextPrimary;
    final episodes = _episodeItems(
      selectedCard,
      cmsStoriesState?.valueOrNull ?? const [],
      history,
    );

    return Scaffold(
      body: AppScreenBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = (constraints.maxWidth / _baseWidth).toDouble();
            final heroWidth = _episodeHeroWidth * scale;
            final horizontal = ((constraints.maxWidth - heroWidth) / 2)
                .clamp(0.0, double.infinity)
                .toDouble();

            return CustomScrollView(
              controller: _episodesScrollController,
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    left: false,
                    right: false,
                    bottom: false,
                    child: _TopBar(
                      scale: scale,
                      contentColor: contentColor,
                      onBack: () {
                        unawaited(
                          PostHogAnalytics.instance.capture(
                            'back_clicked',
                            properties: {
                              'screen_name': 'episodes_screen',
                              'source': 'episodes_header',
                            },
                          ),
                        );
                        unawaited(
                          PostHogAnalytics.instance.buttonClicked(
                            buttonName: 'back',
                            screenName: 'episodes_screen',
                            properties: {'source': 'episodes_header'},
                          ),
                        );
                        Navigator.maybePop(context);
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontal),
                    child: _HeroCard(
                      imageUrl: selectedCard?.heroBannerUrl ?? '',
                      title: selectedCard?.title ?? 'Stories',
                      episodeCount: episodes.length,
                      scale: scale,
                      width: heroWidth,
                      height: _episodeHeroHeight * scale,
                      contentColor: contentColor,
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 27 * scale)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontal),
                    child: Text(
                      'Episodes',
                      style: AppTypography.bodySmallBold.copyWith(
                        color: contentColor,
                        fontSize: 12 * scale,
                        height: 16 / 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 8 * scale)),
                if (episodes.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontal),
                      child: _EmptyEpisodesMessage(
                        scale: scale,
                        contentColor: contentColor,
                      ),
                    ),
                  )
                else
                  SliverList.separated(
                    itemCount: episodes.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: 12 * scale),
                    itemBuilder: (context, index) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontal),
                      child: _EpisodeTile(
                        episode: episodes[index],
                        scale: scale,
                        contentColor: contentColor,
                        onTap: () => _openEpisode(context, episodes[index]),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(child: SizedBox(height: 52 * scale)),
              ],
            );
          },
        ),
      ),
    );
  }

  List<_EpisodeItem> _episodeItems(
    StoryCardModel? selectedCard,
    List<StoryModel> cmsStories,
    SessionStoryHistoryState history,
  ) {
    if (selectedCard == null) {
      return const [];
    }

    return List.unmodifiable([
      for (final (index, story) in cmsStories.indexed)
        _EpisodeItem.cmsStory(
          index: index + 1,
          story: story,
          progress: history.progressForStory(story.id),
          isCompleted: history.isStoryCompleted(story.id),
        ),
    ]);
  }

  void _openEpisode(BuildContext context, _EpisodeItem episode) {
    unawaited(
      PostHogAnalytics.instance.buttonClicked(
        buttonName: 'episode',
        screenName: 'episodes_screen',
        properties: {
          'source': 'episodes_list',
          'target_type': 'episode',
          'target_id': episode.id,
        },
      ),
    );
    final story = episode.story;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => StoryPlayerScreen(
          storyId: story.id,
          title: story.title,
          openDirectly: true,
          playerImageUrl:
              story.coverUrl ?? story.imageUrl ?? story.thumbnailUrl,
          story: story,
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.scale,
    required this.contentColor,
    required this.onBack,
  });

  final double scale;
  final Color contentColor;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56 * scale,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16 * scale,
          16 * scale,
          16 * scale,
          16 * scale,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Semantics(
            button: true,
            label: 'Back',
            child: SizedBox.square(
              dimension: 48 * scale,
              child: InkResponse(
                onTap: onBack,
                radius: 24 * scale,
                child: Center(
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: contentColor,
                    size: 24 * scale,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends ConsumerWidget {
  const _HeroCard({
    required this.imageUrl,
    required this.title,
    required this.episodeCount,
    required this.scale,
    required this.width,
    required this.height,
    required this.contentColor,
  });

  final String imageUrl;
  final String title;
  final int episodeCount;
  final double scale;
  final double width;
  final double height;
  final Color contentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenColors = AppTokenColors.of(ref);
    final tokenTextStyles = AppTokenTextStyles.of(ref);

    return SizedBox(
      key: const ValueKey('episodesHeroBanner'),
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20 * scale),
                border: Border.all(color: tokenColors.episodesHeroBorder),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.surfaceBlack.withValues(alpha: 0.10),
                    blurRadius: 4 * scale,
                    offset: Offset(0, 4 * scale),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20 * scale),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    StoryImageView(imageUrl: imageUrl, fit: BoxFit.cover),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.transparent,
                            tokenColors.episodesHeroOverlay,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16 * scale,
            right: 16 * scale,
            bottom: 13 * scale,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tokenTextStyles.episodesHeroTitle.copyWith(
                          color: contentColor,
                          fontSize: 18 * scale,
                          height: 24 / 18,
                        ),
                      ),
                      SizedBox(height: 4 * scale),
                      Text(
                        '$episodeCount Episodes',
                        style: tokenTextStyles.episodesHeroMeta.copyWith(
                          color: contentColor,
                          fontSize: 12 * scale,
                          height: 16 / 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12 * scale),
                _HeroHeartButton(scale: scale),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroHeartButton extends ConsumerWidget {
  const _HeroHeartButton({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenColors = AppTokenColors.of(ref);

    return Container(
      width: 44 * scale,
      height: 44 * scale,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokenColors.playerOverlayButtonBackground,
        shape: BoxShape.circle,
        border: Border.all(color: tokenColors.playerOverlayButtonBorder),
      ),
      child: SvgPicture.asset(
        'assets/icons/new_boopi/State=Default, Icon=Heart.svg',
        width: 25 * scale,
        height: 25 * scale,
      ),
    );
  }
}

class _EmptyEpisodesMessage extends StatelessWidget {
  const _EmptyEpisodesMessage({
    required this.scale,
    required this.contentColor,
  });

  final double scale;
  final Color contentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24 * scale),
      child: Text(
        'No episodes available yet.',
        textAlign: TextAlign.center,
        style: AppTypography.bodyMediumSemiBold.copyWith(
          color: contentColor,
          fontSize: 14 * scale,
          height: 20 / 14,
        ),
      ),
    );
  }
}

class _EpisodeTile extends ConsumerWidget {
  const _EpisodeTile({
    required this.episode,
    required this.scale,
    required this.contentColor,
    required this.onTap,
  });

  final _EpisodeItem episode;
  final double scale;
  final Color contentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenColors = AppTokenColors.of(ref);

    return Semantics(
      button: true,
      container: true,
      label: '${episode.title}, ${episode.stageLabel}',
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16 * scale),
          child: Ink(
            key: ValueKey(
              'episode-stage-${episode.state.name}-${episode.index}',
            ),
            height: 64 * scale,
            decoration: BoxDecoration(
              color: tokenColors.episodesTileBackground,
              borderRadius: BorderRadius.circular(16 * scale),
              border: Border.all(color: tokenColors.episodesTileBorder),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16 * scale,
                vertical: 12 * scale,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 12 * scale,
                    child: Text(
                      '${episode.index}',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLargeBold.copyWith(
                        color: contentColor,
                        fontSize: 16 * scale,
                        height: 20 / 16,
                      ),
                    ),
                  ),
                  SizedBox(width: 12 * scale),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8 * scale),
                    child: SizedBox.square(
                      dimension: 40 * scale,
                      child: StoryImageView(imageUrl: episode.imageUrl),
                    ),
                  ),
                  SizedBox(width: 8 * scale),
                  Expanded(
                    child: _EpisodeText(
                      episode: episode,
                      scale: scale,
                      contentColor: contentColor,
                    ),
                  ),
                  SizedBox(width: 10 * scale),
                  _EpisodeActionIcon(
                    state: episode.state,
                    scale: scale,
                    contentColor: contentColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EpisodeText extends ConsumerWidget {
  const _EpisodeText({
    required this.episode,
    required this.scale,
    required this.contentColor,
  });

  final _EpisodeItem episode;
  final double scale;
  final Color contentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenTextStyles = AppTokenTextStyles.of(ref);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          episode.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tokenTextStyles.episodesTileTitle.copyWith(
            color: contentColor,
            fontSize: 14 * scale,
            height: 20 / 14,
          ),
        ),
        SizedBox(height: 4 * scale),
        Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  episode.durationLabel,
                  style: tokenTextStyles.episodesTileMeta.copyWith(
                    color: contentColor,
                    fontSize: 10 * scale,
                    height: 12 / 10,
                  ),
                ),
                if (episode.state == _EpisodeState.completed) ...[
                  SizedBox(width: 10 * scale),
                  Text(
                    'Watched',
                    style: tokenTextStyles.episodesTileMeta.copyWith(
                      color: contentColor,
                      fontSize: 10 * scale,
                      height: 12 / 10,
                    ),
                  ),
                ],
                if (episode.state == _EpisodeState.continuing) ...[
                  SizedBox(width: 10 * scale),
                  _EpisodeProgress(
                    scale: scale,
                    progress: episode.progressValue,
                    contentColor: contentColor,
                  ),
                  SizedBox(width: 4 * scale),
                  Text(
                    episode.remainingLabel,
                    style: tokenTextStyles.episodesTileMeta.copyWith(
                      color: contentColor,
                      fontSize: 10 * scale,
                      height: 12 / 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EpisodeProgress extends ConsumerWidget {
  const _EpisodeProgress({
    required this.scale,
    required this.progress,
    required this.contentColor,
  });

  final double scale;
  final double progress;
  final Color contentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenColors = AppTokenColors.of(ref);

    return SizedBox(
      width: 59 * scale,
      height: 2 * scale,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tokenColors.episodesProgressTrack,
                borderRadius: BorderRadius.circular(200 * scale),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 59 * progress.clamp(0.0, 1.0) * scale,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tokenColors.episodesActionContinuingIcon,
                borderRadius: BorderRadius.circular(200 * scale),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EpisodeActionIcon extends ConsumerWidget {
  const _EpisodeActionIcon({
    required this.state,
    required this.scale,
    required this.contentColor,
  });

  final _EpisodeState state;
  final double scale;
  final Color contentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenColors = AppTokenColors.of(ref);

    return SizedBox.square(
      dimension: 24 * scale,
      child: switch (state) {
        _EpisodeState.completed => DecoratedBox(
          decoration: BoxDecoration(
            color: tokenColors.episodesActionCompletedBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            color: tokenColors.episodesActionCompletedIcon,
            size: 18 * scale,
          ),
        ),
        _EpisodeState.continuing => DecoratedBox(
          decoration: BoxDecoration(
            color: tokenColors.episodesActionContinuingBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.play_arrow_rounded,
            color: tokenColors.episodesActionContinuingIcon,
            size: 19 * scale,
          ),
        ),
        _EpisodeState.left => Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: tokenColors.episodesActionLeftBorder,
              width: 2 * scale,
            ),
          ),
          child: Icon(
            Icons.play_arrow_rounded,
            color: tokenColors.episodesActionLeftIcon,
            size: 14 * scale,
          ),
        ),
      },
    );
  }
}

enum _EpisodeState { completed, continuing, left }

class _EpisodeItem {
  const _EpisodeItem({
    required this.index,
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.progress,
    required this.isCompleted,
    required this.imageUrl,
    required this.story,
  });

  factory _EpisodeItem.cmsStory({
    required int index,
    required StoryModel story,
    required ContinueListeningEntry? progress,
    required bool isCompleted,
  }) {
    return _EpisodeItem(
      index: index,
      id: story.id,
      title: story.title,
      durationMinutes: story.durationMinutes,
      progress: progress,
      isCompleted: isCompleted,
      imageUrl: story.thumbnailUrl,
      story: story,
    );
  }

  final int index;
  final String id;
  final String title;
  final int durationMinutes;
  final ContinueListeningEntry? progress;
  final bool isCompleted;
  final String imageUrl;
  final StoryModel story;

  String get durationLabel => '$durationMinutes min';

  _EpisodeState get state {
    if (isCompleted) {
      return _EpisodeState.completed;
    }
    final entry = progress;
    if (entry != null && entry.progress > 0 && entry.progress < 1) {
      return _EpisodeState.continuing;
    }
    return _EpisodeState.left;
  }

  double get progressValue => progress?.progress ?? 0;

  String get remainingLabel {
    final entry = progress;
    final total = entry?.audioDuration ?? Duration(minutes: durationMinutes);
    if (total <= Duration.zero) {
      return '';
    }
    final remaining = total - (entry?.audioPosition ?? Duration.zero);
    final minutes = (remaining.inSeconds / Duration.secondsPerMinute).ceil();
    return '${minutes.clamp(1, durationMinutes)} min left';
  }

  String get stageLabel {
    return switch (state) {
      _EpisodeState.completed => 'completed episode',
      _EpisodeState.continuing => 'continuing episode',
      _EpisodeState.left => 'left episode',
    };
  }
}
