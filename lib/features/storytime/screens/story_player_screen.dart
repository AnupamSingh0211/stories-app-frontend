import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/story_player_provider.dart';
import '../repositories/story_repository.dart';
import '../widgets/story_controls.dart';
import '../widgets/story_image_view.dart';
import '../widgets/story_text_card.dart';

const _playerBackgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF10163A), Color(0xFF0B1027), Color(0xFF070B19)],
);

class StoryPlayerScreen extends ConsumerWidget {
  const StoryPlayerScreen({
    this.storyId = StoryRepository.morningWhispersStoryId,
    this.title = 'Morning Whispers',
    super.key,
  });

  final String storyId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = storyPlayerProvider(storyId);
    final isLoading = ref.watch(provider.select((state) => state.isLoading));
    final colors = Theme.of(context).colorScheme;

    ref.listen<String>(provider.select((state) => state.nextImageUrl), (
      previous,
      next,
    ) {
      if (next.isNotEmpty) {
        unawaited(
          precacheImage(
            CachedNetworkImageProvider(next),
            context,
          ).catchError((Object _) {}),
        );
      }
    });

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: _playerBackgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PlayerAppBar(
                  title: title,
                  onBack: () => Navigator.maybePop(context),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.primary,
                          ),
                        )
                      : _PlayerBodyConsumer(storyId: storyId),
                ),
                const SizedBox(height: 18),
                if (!isLoading) _StoryControlsConsumer(storyId: storyId),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerBodyConsumer extends ConsumerWidget {
  const _PlayerBodyConsumer({required this.storyId});

  final String storyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      storyPlayerProvider(storyId).select(
        (state) => (
          imageUrl: state.currentImageUrl,
          storyText: state.currentStoryText,
          pageNumber: state.pageNumber,
          pageCount: state.pageCount,
          isComplete: state.isComplete,
          errorMessage: state.errorMessage,
        ),
      ),
    );

    return _PlayerBody(
      imageUrl: state.imageUrl,
      storyText: state.storyText,
      pageLabel: state.pageCount == 0
          ? ''
          : 'Page ${state.pageNumber} of ${state.pageCount}',
      isComplete: state.isComplete,
      errorMessage: state.errorMessage,
    );
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
        state.isPlaying ? notifier.pause() : notifier.play();
      },
      onToggleFavorite: notifier.toggleFavorite,
      onChangeSpeed: notifier.changeSpeed,
    );
  }
}

class _PlayerAppBar extends StatelessWidget {
  const _PlayerAppBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        SizedBox.square(
          dimension: 42,
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: colors.onSurface.withValues(alpha: 0.84),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colors.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerBody extends StatelessWidget {
  const _PlayerBody({
    required this.imageUrl,
    required this.storyText,
    required this.pageLabel,
    required this.isComplete,
    this.errorMessage,
  });

  final String imageUrl;
  final String storyText;
  final String pageLabel;
  final bool isComplete;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (errorMessage != null) {
      return _ErrorPanel(message: errorMessage!);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 0.86,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: StoryImageView(imageUrl: imageUrl),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  pageLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isComplete)
                Text(
                  'Story Complete',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: const Color(0xFFFFE06B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          StoryTextCard(text: isComplete ? 'Story Complete' : storyText),
        ],
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
    final colors = theme.colorScheme;

    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF121936).withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, color: colors.primary, size: 38),
              const SizedBox(height: 14),
              Text(
                'Could not play story',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.68),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
