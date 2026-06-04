import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/story_player_provider.dart';
import '../repositories/story_repository.dart';
import '../widgets/story_controls.dart';
import '../widgets/story_image_view.dart';

const _playerBackgroundColor = Color(0xFFFFF8EE);

class StoryPlayerScreen extends ConsumerStatefulWidget {
  const StoryPlayerScreen({
    this.storyId = StoryRepository.morningWhispersStoryId,
    this.title = 'Morning Whispers',
    super.key,
  });

  final String storyId;
  final String title;

  @override
  ConsumerState<StoryPlayerScreen> createState() => _StoryPlayerScreenState();
}

class _StoryPlayerScreenState extends ConsumerState<StoryPlayerScreen> {
  String _language = 'हिंदी';

  @override
  Widget build(BuildContext context) {
    final provider = storyPlayerProvider(widget.storyId);
    final isLoading = ref.watch(provider.select((state) => state.isLoading));

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
      backgroundColor: _playerBackgroundColor,
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFFF6B5A),
                ),
              )
            : _PlayerBodyConsumer(
                storyId: widget.storyId,
                topControls: _PlayerHeader(
                  language: _language,
                  onBack: () => Navigator.maybePop(context),
                  onLanguageChanged: (language) {
                    setState(() => _language = language);
                  },
                ),
              ),
      ),
    );
  }
}

class _PlayerBodyConsumer extends ConsumerWidget {
  const _PlayerBodyConsumer({required this.storyId, required this.topControls});

  final String storyId;
  final Widget topControls;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      storyPlayerProvider(storyId).select(
        (state) => (
          imageUrl: state.currentImageUrl,
          pageNumber: state.pageNumber,
          pageCount: state.pageCount,
          errorMessage: state.errorMessage,
          hasNextPage: state.hasNextPage,
          hasPreviousPage: state.hasPreviousPage,
        ),
      ),
    );
    final notifier = ref.read(storyPlayerProvider(storyId).notifier);

    return _PlayerBody(
      imageUrl: state.imageUrl,
      pageNumber: state.pageNumber,
      pageCount: state.pageCount,
      errorMessage: state.errorMessage,
      onSwipeLeft: state.hasNextPage ? notifier.nextPage : null,
      onSwipeRight: state.hasPreviousPage ? notifier.previousPage : null,
      controls: _StoryControlsConsumer(storyId: storyId),
      topControls: topControls,
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

class _PlayerHeader extends StatelessWidget {
  const _PlayerHeader({
    required this.language,
    required this.onBack,
    required this.onLanguageChanged,
  });

  final String language;
  final VoidCallback onBack;
  final ValueChanged<String> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: Stack(
        children: [
          const Positioned(
            left: 92,
            top: 12,
            child: Icon(Icons.star_rounded, color: Color(0xFFFFC95C), size: 14),
          ),
          const Positioned(
            left: 126,
            top: 35,
            child: Icon(
              Icons.nightlight_round,
              color: Color(0xFFFFD47A),
              size: 20,
            ),
          ),
          Positioned(
            left: 18,
            top: 10,
            child: _HeaderCircleButton(
              onPressed: onBack,
              icon: Icons.arrow_back_rounded,
            ),
          ),
          Positioned(
            right: 18,
            top: 10,
            child: PopupMenuButton<String>(
              onSelected: onLanguageChanged,
              color: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'हिंदी',
                  child: Text(
                    'हिंदी',
                    style: TextStyle(color: Color(0xFF4B3A73)),
                  ),
                ),
                PopupMenuItem(
                  value: 'English',
                  child: Text(
                    'English',
                    style: TextStyle(color: Color(0xFF4B3A73)),
                  ),
                ),
              ],
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4B3A73).withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.language_rounded,
                      color: Color(0xFF6D5C9F),
                      size: 19,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      language,
                      style: const TextStyle(
                        color: Color(0xFF4B3A73),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF6D5C9F),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({required this.onPressed, required this.icon});

  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4B3A73).withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, color: const Color(0xFF4B3A73), size: 22),
      ),
    );
  }
}

class _PlayerBody extends StatelessWidget {
  const _PlayerBody({
    required this.imageUrl,
    required this.pageNumber,
    required this.pageCount,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.controls,
    required this.topControls,
    this.errorMessage,
  });

  final String imageUrl;
  final int pageNumber;
  final int pageCount;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final Widget controls;
  final Widget topControls;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return _ErrorPanel(message: errorMessage!);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -250) {
          onSwipeLeft?.call();
        } else if (velocity > 250) {
          onSwipeRight?.call();
        }
      },
      child: LayoutBuilder(
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
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1E7D8),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5B4636).withValues(alpha: 0.14),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 360),
                    switchInCurve: Curves.easeOut,
                    child: StoryImageView(
                      key: ValueKey(imageUrl),
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
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
              Positioned(
                top: controlsTop,
                left: 24,
                right: 24,
                child: controls,
              ),
            ],
          );
        },
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
        color: const Color(0xFF2D216F).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        '$pageNumber / $pageCount',
        style: const TextStyle(
          color: Colors.white,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4B3A73).withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFFFF6B5A),
                size: 38,
              ),
              const SizedBox(height: 14),
              Text(
                'Could not play story',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF3B3451),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF746B84),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
