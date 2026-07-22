import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../models/story_model.dart';
import '../repositories/story_repository.dart';
import '../widgets/story_image_view.dart';
import 'story_player_screen.dart';

typedef EpisodeAssetUrlBuilder = String Function(String bucket, String path);

const _storyTitle = 'Shararati Krishna ke karname';
const _storyAssetFolder = 'stories/kanha ki sunheri subah/images';
const _bannerPath = 'featured_banners/kanha ki sunheri subah.webp';
const _baseWidth = 390.0;

class EpisodesScreen extends StatelessWidget {
  const EpisodesScreen({this.assetUrlBuilder, super.key});

  final EpisodeAssetUrlBuilder? assetUrlBuilder;

  String _assetUrl(String bucket, String path) {
    final builder = assetUrlBuilder;
    if (builder != null) {
      return builder(bucket, path);
    }

    return Supabase.instance.client.storage.from(bucket).getPublicUrl(path);
  }

  @override
  Widget build(BuildContext context) {
    final bannerUrl = _assetUrl('app-assets', _bannerPath);
    final episodes = _episodes
        .map(
          (episode) => episode.copyWith(
            imageUrl: _assetUrl(
              'story-assets',
              '$_storyAssetFolder/page-${episode.imageNumber.toString().padLeft(3, '0')}.webp',
            ),
          ),
        )
        .toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.blue500,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF69BCF6),
              Color(0xFF2D86EA),
              Color(0xFF0F3F88),
            ],
            stops: [0, 0.52, 1],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = (constraints.maxWidth / _baseWidth).toDouble();

            return CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    left: false,
                    right: false,
                    bottom: false,
                    child: _TopBar(
                      scale: scale,
                      onBack: () => Navigator.maybePop(context),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _HeroCard(imageUrl: bannerUrl, scale: scale),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 27 * scale)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16 * scale),
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
                    padding: EdgeInsets.symmetric(horizontal: 16 * scale),
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

  void _openEpisode(BuildContext context, _Episode episode) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => StoryPlayerScreen(
          storyId: StoryRepository.morningWhispersStoryId,
          title: episode.title,
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
  const _HeroCard({required this.imageUrl, required this.scale});

  final String imageUrl;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 17 * scale),
      child: SizedBox(
        height: 187 * scale,
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
                          _storyTitle,
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
                          '7 Episodes',
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
      child: Icon(
        Icons.favorite_border_rounded,
        color: AppColors.textOnPrimary,
        size: 25 * scale,
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

  final _Episode episode;
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

  final _Episode episode;
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
                  _EpisodeProgress(scale: scale),
                  SizedBox(width: 4 * scale),
                  Text(
                    '1 min left',
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
  const _EpisodeProgress({required this.scale});

  final double scale;

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
            width: 39 * scale,
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
    required this.title,
    required this.durationMinutes,
    required this.imageNumber,
    required this.state,
    this.imageUrl = '',
  });

  final int index;
  final String title;
  final int durationMinutes;
  final int imageNumber;
  final _EpisodeState state;
  final String imageUrl;

  String get durationLabel => '$durationMinutes min';

  String get stageLabel {
    return switch (state) {
      _EpisodeState.completed => 'completed episode',
      _EpisodeState.continuing => 'continuing episode',
      _EpisodeState.left => 'left episode',
    };
  }

  _Episode copyWith({String? imageUrl}) {
    return _Episode(
      index: index,
      title: title,
      durationMinutes: durationMinutes,
      imageNumber: imageNumber,
      state: state,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

const _episodes = [
  _Episode(
    index: 1,
    title: 'Makhan Ki Talaash',
    durationMinutes: 3,
    imageNumber: 1,
    state: _EpisodeState.completed,
  ),
  _Episode(
    index: 2,
    title: 'Makhan Chor Kanha',
    durationMinutes: 3,
    imageNumber: 2,
    state: _EpisodeState.continuing,
  ),
  _Episode(
    index: 3,
    title: 'Meri Pyari Bachhiya',
    durationMinutes: 7,
    imageNumber: 3,
    state: _EpisodeState.left,
  ),
  _Episode(
    index: 4,
    title: 'Bansuri Ki Dhun',
    durationMinutes: 5,
    imageNumber: 4,
    state: _EpisodeState.left,
  ),
  _Episode(
    index: 5,
    title: 'Titliyon Ke Peeche',
    durationMinutes: 6,
    imageNumber: 5,
    state: _EpisodeState.left,
  ),
  _Episode(
    index: 6,
    title: 'Barish Wali Masti',
    durationMinutes: 4,
    imageNumber: 6,
    state: _EpisodeState.left,
  ),
  _Episode(
    index: 7,
    title: 'Vrindavan Ke Dost',
    durationMinutes: 3,
    imageNumber: 7,
    state: _EpisodeState.left,
  ),
];
