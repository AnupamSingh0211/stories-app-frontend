import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_border_radius.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_shadows.dart';
import '../../library/library_screen.dart';
import '../models/story_page.dart';
import '../providers/saved_library_provider.dart';
import '../providers/story_player_provider.dart';
import '../repositories/story_repository.dart';
import '../widgets/story_controls.dart';
import '../widgets/story_image_view.dart';

class StoryPlayerScreen extends ConsumerStatefulWidget {
  const StoryPlayerScreen({
    this.storyId = StoryRepository.morningWhispersStoryId,
    this.title = 'Kanha Ki Sunheri Subah',
    super.key,
  });

  final String storyId;
  final String title;

  @override
  ConsumerState<StoryPlayerScreen> createState() => _StoryPlayerScreenState();
}

class _StoryPlayerScreenState extends ConsumerState<StoryPlayerScreen> {
  bool _hasShownSavePrompt = false;

  String _language = 'हिंदी';

  @override
  Widget build(BuildContext context) {
    final provider = storyPlayerProvider(widget.storyId);
    final isLoading = ref.watch(provider.select((state) => state.isLoading));

    ref.listen<bool>(provider.select((state) => state.isComplete), (
      previous,
      next,
    ) {
      if (!next) {
        _hasShownSavePrompt = false;
        return;
      }

      if (!_hasShownSavePrompt) {
        _hasShownSavePrompt = true;
        Future.microtask(_showSaveStoryPrompt);
      }
    });

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
      backgroundColor: AppColors.playerBackground,
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.playerPrimary,
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

  Future<void> _showSaveStoryPrompt() async {
    if (!mounted) {
      return;
    }

    final shouldSave = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      barrierDismissible: false,
      builder: (context) => _SaveStoryPrompt(title: widget.title),
    );

    if (!mounted || shouldSave != true) {
      return;
    }

    try {
      final result = await ref
          .read(savedLibraryProvider.notifier)
          .saveStory(widget.storyId);

      if (!mounted) {
        return;
      }

      switch (result) {
        case SaveStoryResult.saved:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Story saved to your Library')),
          );
        case SaveStoryResult.alreadySaved:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This story is already in Library')),
          );
        case SaveStoryResult.full:
          await _showFullLibraryDialog();
      }
    } on StoryRepositoryException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _showFullLibraryDialog() async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Your library is full!'),
          content: const Text(
            'Delete an older story to make room, or upgrade to Premium for unlimited saves.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Not now'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const LibraryScreen(),
                  ),
                );
              },
              child: const Text('View Library'),
            ),
            TextButton(onPressed: () {}, child: const Text('Upgrade')),
          ],
        );
      },
    );
  }
}

class _SaveStoryPrompt extends StatelessWidget {
  const _SaveStoryPrompt({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 44),
      backgroundColor: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.playerPurpleDeep.withValues(alpha: 0.38),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF9ED),
                  Color(0xFFFFFDF7),
                  Color(0xFFF1E9FF),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.86)),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -40,
                  right: -26,
                  child: _PromptGlow(
                    size: 96,
                    color: AppColors.playerWarmGoldLight,
                    opacity: 0.28,
                  ),
                ),
                Positioned(
                  bottom: -46,
                  left: -42,
                  child: _PromptGlow(
                    size: 110,
                    color: AppColors.playerPrimary,
                    opacity: 0.1,
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 22,
                  child: Icon(
                    Icons.star_rounded,
                    color: AppColors.playerWarmGold,
                    size: 15,
                  ),
                ),
                Positioned(
                  top: 42,
                  right: 26,
                  child: Icon(
                    Icons.nightlight_round,
                    color: AppColors.playerWarmGold.withValues(alpha: 0.72),
                    size: 18,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF30205F),
                              Color(0xFF4B3A8F),
                              Color(0xFF6C4CCF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.auto_stories_rounded,
                                    color: AppColors.playerWarmGoldLight,
                                    size: 17,
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    'Story finished',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.78,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Icon(
                                    Icons.library_add_check_rounded,
                                    color: AppColors.playerPrimary,
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Keep this bedtime tale?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  height: 1.08,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Save it to your Library so your child can replay it anytime.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.playerPurpleDeep.withValues(
                            alpha: 0.64,
                          ),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.58,
                                ),
                                foregroundColor: const Color(0xFF55496B),
                                side: BorderSide(
                                  color: const Color(
                                    0xFF55496B,
                                  ).withValues(alpha: 0.2),
                                ),
                                minimumSize: const Size.fromHeight(46),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(17),
                                ),
                              ),
                              child: const Text(
                                'No, later',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.playerPrimary,
                                foregroundColor: colors.onPrimary,
                                minimumSize: const Size.fromHeight(46),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(17),
                                ),
                              ),
                              child: const Text(
                                'Yes, save',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PromptGlow extends StatelessWidget {
  const _PromptGlow({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
      child: SizedBox(width: size, height: size),
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
            _pageController.jumpToPage(0);
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
            child: Icon(
              Icons.star_rounded,
              color: AppColors.playerWarmGold,
              size: 14,
            ),
          ),
          const Positioned(
            left: 126,
            top: 35,
            child: Icon(
              Icons.nightlight_round,
              color: AppColors.playerWarmGoldLight,
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
              color: AppColors.playerSurface,
              surfaceTintColor: AppColors.playerSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'हिंदी',
                  child: Text(
                    'हिंदी',
                    style: TextStyle(color: AppColors.playerPurple),
                  ),
                ),
              ],
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.playerSurface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [AppShadows.playerElevation],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.language_rounded,
                      color: AppColors.playerPurpleMuted,
                      size: 19,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      language,
                      style: const TextStyle(
                        color: AppColors.playerPurple,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.playerPurpleMuted,
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
        color: AppColors.playerSurface,
        shape: BoxShape.circle,
        boxShadow: const [AppShadows.playerElevation],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.playerPurple, size: 22),
      ),
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
