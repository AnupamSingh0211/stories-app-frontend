import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../shared/theme/app_colors.dart';
import '../models/story_page.dart';
import '../providers/story_player_provider.dart';
import 'story_image_view.dart';

class StoryPlayerContent extends ConsumerWidget {
  const StoryPlayerContent({
    required this.storyId,
    required this.storyTitle,
    required this.page,
    super.key,
  });

  final String storyId;
  final String storyTitle;
  final StoryPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = storyPlayerProvider(storyId);
    final errorMessage = ref.watch(
      provider.select((state) => state.errorMessage),
    );

    if (errorMessage != null) {
      return _PlayerErrorPanel(message: errorMessage);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaleX = constraints.maxWidth / 390;
        final scaleY = constraints.maxHeight / 844;
        final textScale = scaleX.clamp(0.88, 1.12);

        return ColoredBox(
          color: AppColors.blue25,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 483 * scaleY,
                child: StoryImageView(
                  key: ValueKey(page.imageUrl),
                  imageUrl: page.imageUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
              Positioned(
                left: 22 * scaleX,
                right: 18 * scaleX,
                top: 500 * scaleY,
                height: 128 * scaleY,
                child: Text(
                  page.text,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 18 * textScale,
                    fontWeight: FontWeight.w600,
                    height: 24 / 18,
                    color: AppColors.blue800,
                  ),
                ),
              ),
              Positioned(
                left: 22 * scaleX,
                right: 18 * scaleX,
                top: 647 * scaleY,
                child: Text(
                  storyTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 24 * textScale,
                    fontWeight: FontWeight.w600,
                    height: 28 / 24,
                    letterSpacing: -0.25,
                    color: AppColors.blue800,
                  ),
                ),
              ),
              Positioned(
                left: 22 * scaleX,
                right: 18 * scaleX,
                top: 688 * scaleY,
                height: 22 * scaleY,
                child: _StoryTimelineConsumer(
                  storyId: storyId,
                  storyPageIndex: page.pageNumber - 1,
                ),
              ),
              Positioned(
                left: 22 * scaleX,
                right: 18 * scaleX,
                top: 723 * scaleY,
                height: 36 * scaleY,
                child: _StoryPlaybackControlsConsumer(
                  storyId: storyId,
                  storyPageIndex: page.pageNumber - 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StoryTimelineConsumer extends ConsumerWidget {
  const _StoryTimelineConsumer({
    required this.storyId,
    required this.storyPageIndex,
  });

  final String storyId;
  final int storyPageIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = storyPlayerProvider(storyId);
    final timeline = ref.watch(
      provider.select((state) {
        if (state.currentPageIndex != storyPageIndex) {
          return (position: Duration.zero, duration: Duration.zero);
        }
        return (position: state.audioPosition, duration: state.audioDuration);
      }),
    );

    return _TimelineRow(
      position: timeline.position,
      duration: timeline.duration,
      onSeek: ref.read(provider.notifier).seekTo,
    );
  }
}

class _StoryPlaybackControlsConsumer extends ConsumerWidget {
  const _StoryPlaybackControlsConsumer({
    required this.storyId,
    required this.storyPageIndex,
  });

  final String storyId;
  final int storyPageIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = storyPlayerProvider(storyId);
    final controls = ref.watch(
      provider.select(
        (state) => (
          isPlaying:
              state.currentPageIndex == storyPageIndex && state.isPlaying,
          isFavorite: state.isFavorite,
          playbackSpeed: state.playbackSpeed,
        ),
      ),
    );
    final notifier = ref.read(provider.notifier);

    return _PlaybackControls(
      isPlaying: controls.isPlaying,
      isFavorite: controls.isFavorite,
      playbackSpeed: controls.playbackSpeed,
      onToggleFavorite: notifier.toggleFavorite,
      onRewind: () => notifier.seekBy(const Duration(seconds: -10)),
      onTogglePlayback: () {
        controls.isPlaying ? notifier.pause() : notifier.play();
      },
      onForward: () => notifier.seekBy(const Duration(seconds: 10)),
      onChangeSpeed: notifier.changeSpeed,
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context) {
    final progress = duration.inMilliseconds <= 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

    return Row(
      children: [
        Text(
          '${_formatDuration(position)} / ${_formatDuration(duration)}',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.gray800,
          ),
        ),
        const SizedBox(width: 12),
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
                    if (duration <= Duration.zero ||
                        constraints.maxWidth == 0) {
                      return;
                    }
                    final fraction =
                        (details.localPosition.dx / constraints.maxWidth).clamp(
                          0.0,
                          1.0,
                        );
                    onSeek(
                      Duration(
                        milliseconds: (duration.inMilliseconds * fraction)
                            .round(),
                      ),
                    );
                  },
                  child: SizedBox(
                    height: 22,
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(200),
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          value: progress,
                          backgroundColor: AppColors.gray300,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.blue500,
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
        const SizedBox(width: 12),
        const Icon(Icons.volume_up_rounded, size: 22, color: AppColors.gray800),
      ],
    );
  }

  String _formatDuration(Duration value) {
    final safeSeconds = value.inSeconds < 0 ? 0 : value.inSeconds;
    final minutes = safeSeconds ~/ 60;
    final seconds = safeSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({
    required this.isPlaying,
    required this.isFavorite,
    required this.playbackSpeed,
    required this.onToggleFavorite,
    required this.onRewind,
    required this.onTogglePlayback,
    required this.onForward,
    required this.onChangeSpeed,
  });

  final bool isPlaying;
  final bool isFavorite;
  final double playbackSpeed;
  final VoidCallback onToggleFavorite;
  final VoidCallback onRewind;
  final VoidCallback onTogglePlayback;
  final VoidCallback onForward;
  final VoidCallback onChangeSpeed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _RoundControl(
          semanticLabel: isFavorite
              ? 'Remove from favorites'
              : 'Add to favorites',
          backgroundColor: AppColors.gray400,
          onPressed: onToggleFavorite,
          child: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 21,
            color: AppColors.surfaceWhite,
          ),
        ),
        Row(
          children: [
            _RoundControl(
              semanticLabel: 'Rewind 10 seconds',
              onPressed: onRewind,
              child: SvgPicture.asset(
                'assets/icons/player/undo.svg',
                width: 36,
                height: 36,
                colorFilter: const ColorFilter.mode(
                  AppColors.blue500,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: 37),
            _RoundControl(
              semanticLabel: isPlaying ? 'Pause story' : 'Play story',
              backgroundColor: AppColors.blue500,
              onPressed: onTogglePlayback,
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 27,
                color: AppColors.surfaceWhite,
              ),
            ),
            const SizedBox(width: 37),
            _RoundControl(
              semanticLabel: 'Forward 10 seconds',
              onPressed: onForward,
              child: SvgPicture.asset(
                'assets/icons/player/replay.svg',
                width: 36,
                height: 36,
                colorFilter: const ColorFilter.mode(
                  AppColors.blue500,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
        _RoundControl(
          semanticLabel: 'Playback speed ${_speedLabel(playbackSpeed)}',
          backgroundColor: AppColors.blue600,
          onPressed: onChangeSpeed,
          child: Text(
            _speedLabel(playbackSpeed),
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 16 / 12,
              color: AppColors.blue50,
            ),
          ),
        ),
      ],
    );
  }

  static String _speedLabel(double value) {
    if (value == value.roundToDouble()) {
      return '${value.toStringAsFixed(1)}x';
    }
    return '${value}x';
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.semanticLabel,
    required this.onPressed,
    required this.child,
    this.backgroundColor = AppColors.transparent,
  });

  final String semanticLabel;
  final VoidCallback onPressed;
  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkResponse(
        onTap: onPressed,
        radius: 24,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PlayerErrorPanel extends StatelessWidget {
  const _PlayerErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.blue25,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.blue600,
                size: 40,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  color: AppColors.blue800,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
