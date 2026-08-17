import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/analytics_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/app_screen_background.dart';
import '../models/story_model.dart';
import '../providers/continue_listening_provider.dart';
import '../providers/story_player_provider.dart';
import '../repositories/story_repository.dart';
import '../widgets/story_image_view.dart';
import 'story_player_screen.dart';

typedef EpisodeAssetUrlBuilder = String Function(String bucket, String path);

const _storyTitle = 'Shararati Krishna ke karname';
const _storyAssetFolder = 'stories/kanha ki sunheri subah/images';
const _storyPlayerImagePath =
    'stories/kanha aur makhan/images/story_player_img.webp';
const _bannerPath = 'featured_banners/kanha ki sunheri subah.webp';
const _baseWidth = 390.0;
const _episodeHeroWidth = 359.0;
const _episodeHeroHeight = 202.0;

class EpisodesScreen extends ConsumerStatefulWidget {
  const EpisodesScreen({this.storyCard, this.assetUrlBuilder, super.key});

  final StoryCardModel? storyCard;
  final EpisodeAssetUrlBuilder? assetUrlBuilder;

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
          'story_card_id':
              widget.storyCard?.id ?? StoryRepository.krishnaStoryCardId,
        },
      ),
    );
    unawaited(
      PostHogAnalytics.instance.capture(
        'story_list_viewed',
        properties: {
          'screen_name': 'episodes_screen',
          'source': 'episodes_list',
          'story_card_id':
              widget.storyCard?.id ?? StoryRepository.krishnaStoryCardId,
          'story_card_title': widget.storyCard?.title ?? _storyTitle,
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
          'story_card_id':
              widget.storyCard?.id ?? StoryRepository.krishnaStoryCardId,
          'story_card_title': widget.storyCard?.title ?? _storyTitle,
        },
      ),
    );
  }

  String _assetUrl(String bucket, String path) {
    final builder = widget.assetUrlBuilder;
    if (builder != null) {
      return builder(bucket, path);
    }

    return Supabase.instance.client.storage.from(bucket).getPublicUrl(path);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCard = widget.storyCard;
    final bannerUrl =
        selectedCard?.heroBannerUrl ?? _assetUrl('app-assets', _bannerPath);
    final cmsStoriesState = selectedCard == null
        ? null
        : ref.watch(storyCardStoriesProvider(selectedCard.id));
    final history = ref.watch(sessionStoryHistoryProvider);
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
                      imageUrl: bannerUrl,
                      title: selectedCard?.title ?? _storyTitle,
                      episodeCount: episodes.length,
                      scale: scale,
                      width: heroWidth,
                      height: _episodeHeroHeight * scale,
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
                        color: AppColors.textOnPrimary,
                        fontSize: 12 * scale,
                        height: 16 / 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 8 * scale)),
                SliverList.separated(
                  itemCount: episodes.length,
                  separatorBuilder: (context, index) =>
                      SizedBox(height: 12 * scale),
                  itemBuilder: (context, index) => Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontal),
                    child: _EpisodeTile(
                      episode: episodes[index],
                      scale: scale,
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
    final isKrishnaCard =
        selectedCard == null ||
        selectedCard.id == StoryRepository.krishnaStoryCardId;
    final legacyItems = isKrishnaCard
        ? _episodes
              .map(
                (episode) => _EpisodeItem.legacy(
                  index: episode.index,
                  title: episode.title,
                  durationMinutes: episode.durationMinutes,
                  progress: history.progressForStory(episode.id),
                  isCompleted: history.isStoryCompleted(episode.id),
                  imageUrl: _assetUrl(
                    'story-assets',
                    '$_storyAssetFolder/page-${episode.imageNumber.toString().padLeft(3, '0')}.webp',
                  ),
                ),
              )
              .toList(growable: true)
        : <_EpisodeItem>[];

    final existingIds = legacyItems.map((item) => item.story?.id).toSet();
    for (final story in cmsStories) {
      if (existingIds.contains(story.id)) {
        continue;
      }
      if (isKrishnaCard &&
          (story.id == StoryRepository.morningWhispersStoryId ||
              story.id == StoryRepository.arrivalNewsStoryId)) {
        continue;
      }
      legacyItems.add(
        _EpisodeItem.cmsStory(
          index: legacyItems.length + 1,
          story: story,
          progress: history.progressForStory(story.id),
          isCompleted: history.isStoryCompleted(story.id),
        ),
      );
    }

    return List.unmodifiable(legacyItems);
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
    if (story != null) {
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
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => StoryPlayerScreen(
          storyId: StoryRepository.morningWhispersStoryId,
          title: episode.title,
          openDirectly: true,
          playerImageUrl: _assetUrl('story-assets', _storyPlayerImagePath),
          story: StoryModel(
            id: StoryRepository.morningWhispersStoryId,
            title: episode.title,
            thumbnailUrl: episode.imageUrl,
            category: 'Story',
            durationMinutes: episode.durationMinutes,
            imageUrl: episode.imageUrl,
            coverUrl: episode.imageUrl,
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.scale, required this.onBack});

  final double scale;
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
                    color: AppColors.textOnPrimary,
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.imageUrl,
    required this.title,
    required this.episodeCount,
    required this.scale,
    required this.width,
    required this.height,
  });

  final String imageUrl;
  final String title;
  final int episodeCount;
  final double scale;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
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
                border: Border.all(color: AppColors.blue400),
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
                            AppColors.surfaceBlack.withValues(alpha: 0.30),
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
                        style: AppTypography.titleSemiBold.copyWith(
                          color: AppColors.textOnPrimary,
                          fontSize: 18 * scale,
                          height: 24 / 18,
                        ),
                      ),
                      SizedBox(height: 4 * scale),
                      Text(
                        '$episodeCount Episodes',
                        style: AppTypography.bodySmallBold.copyWith(
                          color: AppColors.textOnPrimary,
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

class _HeroHeartButton extends StatelessWidget {
  const _HeroHeartButton({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44 * scale,
      height: 44 * scale,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.glassBackground,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderGlass),
      ),
      child: SvgPicture.asset(
        'assets/icons/new_boopi/State=Default, Icon=Heart.svg',
        width: 25 * scale,
        height: 25 * scale,
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({
    required this.episode,
    required this.scale,
    required this.onTap,
  });

  final _EpisodeItem episode;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              color: AppColors.backgroundGlass,
              borderRadius: BorderRadius.circular(16 * scale),
              border: Border.all(color: AppColors.borderGlass),
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
                        color: AppColors.textOnPrimary,
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
                    child: _EpisodeText(episode: episode, scale: scale),
                  ),
                  SizedBox(width: 10 * scale),
                  _EpisodeActionIcon(state: episode.state, scale: scale),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EpisodeText extends StatelessWidget {
  const _EpisodeText({required this.episode, required this.scale});

  final _EpisodeItem episode;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          episode.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyMediumSemiBold.copyWith(
            color: AppColors.textOnPrimary,
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
                  style: AppTypography.captionSemiBold.copyWith(
                    color: AppColors.textOnPrimary,
                    fontSize: 10 * scale,
                    height: 12 / 10,
                  ),
                ),
                if (episode.state == _EpisodeState.completed) ...[
                  SizedBox(width: 10 * scale),
                  Text(
                    'Watched',
                    style: AppTypography.captionSemiBold.copyWith(
                      color: AppColors.textOnPrimary,
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
                  ),
                  SizedBox(width: 4 * scale),
                  Text(
                    episode.remainingLabel,
                    style: AppTypography.captionRegular.copyWith(
                      color: AppColors.textOnPrimary,
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

class _EpisodeProgress extends StatelessWidget {
  const _EpisodeProgress({required this.scale, required this.progress});

  final double scale;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 59 * scale,
      height: 2 * scale,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.glassShadow,
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
                color: AppColors.textOnPrimary,
                borderRadius: BorderRadius.circular(200 * scale),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EpisodeActionIcon extends StatelessWidget {
  const _EpisodeActionIcon({required this.state, required this.scale});

  final _EpisodeState state;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 24 * scale,
      child: switch (state) {
        _EpisodeState.completed => DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.textOnPrimary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            color: AppColors.blue500,
            size: 18 * scale,
          ),
        ),
        _EpisodeState.continuing => DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.textOnPrimary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.play_arrow_rounded,
            color: AppColors.blue500,
            size: 19 * scale,
          ),
        ),
        _EpisodeState.left => Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.textOnPrimary,
              width: 2 * scale,
            ),
          ),
          child: Icon(
            Icons.play_arrow_rounded,
            color: AppColors.textOnPrimary,
            size: 14 * scale,
          ),
        ),
      },
    );
  }
}

enum _EpisodeState { completed, continuing, left }

class _Episode {
  const _Episode({
    required this.index,
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.imageNumber,
    this.imageUrl = '',
  });

  final int index;
  final String id;
  final String title;
  final int durationMinutes;
  final int imageNumber;
  final String imageUrl;

  String get durationLabel => '$durationMinutes min';

  _Episode copyWith({String? imageUrl}) {
    return _Episode(
      index: index,
      id: id,
      title: title,
      durationMinutes: durationMinutes,
      imageNumber: imageNumber,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class _EpisodeItem {
  const _EpisodeItem({
    required this.index,
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.progress,
    required this.isCompleted,
    required this.imageUrl,
    this.story,
  });

  factory _EpisodeItem.legacy({
    required int index,
    required String title,
    required int durationMinutes,
    required ContinueListeningEntry? progress,
    required bool isCompleted,
    required String imageUrl,
  }) {
    return _EpisodeItem(
      index: index,
      id: 'kanha-episode-$index',
      title: title,
      durationMinutes: durationMinutes,
      progress: progress,
      isCompleted: isCompleted,
      imageUrl: imageUrl,
    );
  }

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
  final StoryModel? story;

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

const _episodes = [
  _Episode(
    index: 1,
    id: 'kanha-episode-1',
    title: 'Makhan Ki Talaash',
    durationMinutes: 3,
    imageNumber: 1,
  ),
  _Episode(
    index: 2,
    id: 'kanha-episode-2',
    title: 'Makhan Chor Kanha',
    durationMinutes: 3,
    imageNumber: 2,
  ),
  _Episode(
    index: 3,
    id: 'kanha-episode-3',
    title: 'Meri Pyari Bachhiya',
    durationMinutes: 7,
    imageNumber: 3,
  ),
  _Episode(
    index: 4,
    id: 'kanha-episode-4',
    title: 'Bansuri Ki Dhun',
    durationMinutes: 5,
    imageNumber: 4,
  ),
  _Episode(
    index: 5,
    id: 'kanha-episode-5',
    title: 'Titliyon Ke Peeche',
    durationMinutes: 6,
    imageNumber: 5,
  ),
  _Episode(
    index: 6,
    id: 'kanha-episode-6',
    title: 'Barish Wali Masti',
    durationMinutes: 4,
    imageNumber: 6,
  ),
  _Episode(
    index: 7,
    id: 'kanha-episode-7',
    title: 'Vrindavan Ke Dost',
    durationMinutes: 3,
    imageNumber: 7,
  ),
];
