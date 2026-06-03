import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'story_model.dart';
import 'story_provider.dart';

const _backgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF10163A), Color(0xFF0B1027), Color(0xFF070B19)],
);
const _carouselLoopStartPage = 12000;

final _softBorder = Border.all(color: Colors.white.withValues(alpha: 0.08));

class StorytimeScreen extends ConsumerStatefulWidget {
  const StorytimeScreen({super.key});

  @override
  ConsumerState<StorytimeScreen> createState() => _StorytimeScreenState();
}

class _StorytimeScreenState extends ConsumerState<StorytimeScreen> {
  final _pageController = PageController(
    initialPage: _carouselLoopStartPage,
    viewportFraction: 0.9,
  );
  Timer? _carouselTimer;
  int _activePage = 0;
  int _carouselBannerCount = -1;

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _syncCarouselTimer(int bannerCount) {
    if (_carouselBannerCount == bannerCount) {
      return;
    }

    _carouselBannerCount = bannerCount;
    _carouselTimer?.cancel();
    if (bannerCount > 0 && _pageController.hasClients) {
      final loopStart =
          _carouselLoopStartPage - (_carouselLoopStartPage % bannerCount);
      _pageController.jumpToPage(loopStart);
      if (_activePage != 0) {
        setState(() => _activePage = 0);
      }
    }

    if (bannerCount < 2) {
      return;
    }

    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) {
        return;
      }

      final currentPage = (_pageController.page ?? _carouselLoopStartPage)
          .round();
      final nextPage = currentPage + 1;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final contentState = ref.watch(storytimeContentProvider);
    final bannerCount = contentState.valueOrNull?.featuredBanners.length ?? 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncCarouselTimer(bannerCount);
    });

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: _backgroundGradient),
        child: Stack(
          children: [
            const _AmbientBackdrop(),
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  const SliverToBoxAdapter(child: _TopAppBar()),
                  contentState.when(
                    data: (content) => _StorySlivers(
                      content: content,
                      pageController: _pageController,
                      activePage: _activePage,
                      onPageChanged: (page) {
                        final bannerCount = content.featuredBanners.length;
                        if (bannerCount == 0) {
                          return;
                        }

                        setState(() => _activePage = page % bannerCount);
                      },
                    ),
                    loading: () => const _LoadingSlivers(),
                    error: (error, stackTrace) => _StorySlivers(
                      content: StorytimeContent.empty(),
                      pageController: _pageController,
                      activePage: _activePage,
                      onPageChanged: (page) {
                        setState(() => _activePage = page);
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 118)),
                ],
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 18,
              child: _BedtimeBottomNavigation(
                selectedItem: _NavigationItem.library,
                onHomeTap: () => Navigator.maybePop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorySlivers extends StatelessWidget {
  const _StorySlivers({
    required this.content,
    required this.pageController,
    required this.activePage,
    required this.onPageChanged,
  });

  final StorytimeContent content;
  final PageController pageController;
  final int activePage;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final sections = content.sections.isNotEmpty
        ? content.sections
        : [
            StorySectionModel(
              id: 'for-you',
              title: 'For You',
              stories: content.forYouStories,
            ),
            StorySectionModel(
              id: 'popular',
              title: 'Popular Tales',
              stories: content.popularStories,
            ),
          ].where((section) => section.stories.isNotEmpty).toList();

    return SliverList(
      delegate: SliverChildListDelegate.fixed([
        _FeaturedCarousel(
          banners: content.featuredBanners,
          pageController: pageController,
          activePage: activePage,
          onPageChanged: onPageChanged,
        ),
        for (final entry in sections.asMap().entries) ...[
          const SizedBox(height: 34),
          _HorizontalStorySection(
            title: entry.value.title,
            titleIcon: entry.value.title.toLowerCase().contains('popular')
                ? Icons.auto_awesome_rounded
                : null,
            stories: entry.value.stories,
            cardBuilder: (story, index) {
              final title = entry.value.title.toLowerCase();
              if (entry.key == 0 || title.contains('for you')) {
                return _ForYouStoryCard(story: story, delayIndex: index);
              }

              return _PopularStoryCard(story: story, delayIndex: index);
            },
          ),
        ],
        const SizedBox(height: 34),
        _ExploreCategories(categories: content.categories),
      ]),
    );
  }
}

class _TopAppBar extends StatelessWidget {
  const _TopAppBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.maybePop(context),
              icon: Icon(
                Icons.arrow_back_rounded,
                color: colors.onSurface.withValues(alpha: 0.82),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Dreamy Tales',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _RoundIconButton(icon: Icons.search_rounded, onTap: () {}),
          const SizedBox(width: 12),
          _ChildAvatar(colors: colors),
        ],
      ),
    );
  }
}

class _FeaturedCarousel extends StatelessWidget {
  const _FeaturedCarousel({
    required this.banners,
    required this.pageController,
    required this.activePage,
    required this.onPageChanged,
  });

  final List<FeaturedBannerModel> banners;
  final PageController pageController;
  final int activePage;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: _EmptyImageCard(
          height: 176,
          icon: Icons.landscape_rounded,
          label: 'Add featured banners in Supabase Storage',
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 176,
          child: PageView.builder(
            controller: pageController,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final realIndex = index % banners.length;
              final banner = banners[realIndex];

              return AnimatedBuilder(
                animation: pageController,
                builder: (context, child) {
                  double scale = 1;
                  if (pageController.position.haveDimensions) {
                    final page = pageController.page ?? activePage.toDouble();
                    scale = (1 - ((page - index).abs() * 0.05)).clamp(0.94, 1);
                  }

                  return Transform.scale(scale: scale, child: child);
                },
                child: _FadeInCard(
                  delay: Duration(milliseconds: 70 * realIndex),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: _FeaturedStoryCard(banner: banner),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _PageDots(count: banners.length, activeIndex: activePage),
      ],
    );
  }
}

class _FeaturedStoryCard extends StatelessWidget {
  const _FeaturedStoryCard({required this.banner});

  final FeaturedBannerModel banner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _Pressable(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: _softBorder,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _StoryImage(imageUrl: banner.imageUrl),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF050914).withValues(alpha: 0.18),
                      const Color(0xFF050914).withValues(alpha: 0.82),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banner.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      banner.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colors.onSurface,
                        fontSize: 20,
                        height: 1.16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef _StoryCardBuilder = Widget Function(StoryModel story, int index);

class _HorizontalStorySection extends StatelessWidget {
  const _HorizontalStorySection({
    required this.title,
    required this.stories,
    required this.cardBuilder,
    this.titleIcon,
  });

  final String title;
  final IconData? titleIcon;
  final List<StoryModel> stories;
  final _StoryCardBuilder cardBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colors.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (titleIcon != null) ...[
                      const SizedBox(width: 8),
                      Icon(titleIcon, color: colors.onSurface, size: 20),
                    ],
                  ],
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: colors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('See all'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: title == 'For You' ? 278 : 260,
          child: stories.isEmpty
              ? ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _EmptyImageCard(
                      width: title == 'For You' ? 150 : 178,
                      height: title == 'For You' ? 248 : 224,
                      icon: Icons.image_rounded,
                      label: 'Add images in story_thumbnails',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: stories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 16),
                  itemBuilder: (context, index) =>
                      cardBuilder(stories[index], index),
                ),
        ),
      ],
    );
  }
}

class _ForYouStoryCard extends StatelessWidget {
  const _ForYouStoryCard({required this.story, required this.delayIndex});

  final StoryModel story;
  final int delayIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _FadeInCard(
      delay: Duration(milliseconds: 80 * delayIndex),
      child: SizedBox(
        width: 150,
        child: _Pressable(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 0.78,
                child: _ImageCard(
                  imageUrl: story.thumbnailUrl,
                  radius: 16,
                  overlay: const _EmptyHeartButton(),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                story.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.22,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${story.durationLabel} - ${story.category}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.68),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularStoryCard extends StatelessWidget {
  const _PopularStoryCard({required this.story, required this.delayIndex});

  final StoryModel story;
  final int delayIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _FadeInCard(
      delay: Duration(milliseconds: 80 * delayIndex),
      child: SizedBox(
        width: 178,
        child: _Pressable(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: _ImageCard(
                  imageUrl: story.thumbnailUrl,
                  radius: 18,
                  overlay: _DurationBadge(label: story.durationLabel),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                story.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                story.narrator?.isNotEmpty == true
                    ? story.narrator!
                    : story.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.66),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreCategories extends StatelessWidget {
  const _ExploreCategories({required this.categories});

  final List<StoryCategoryModel> categories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final visibleCategories = categories.take(6).toList(growable: false);

    if (visibleCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore Categories',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colors.primary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 16.0;
              final cardWidth = (constraints.maxWidth - gap) / 2;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (var i = 0; i < visibleCategories.length; i++)
                    SizedBox(
                      width: cardWidth,
                      child: _CategoryCard(
                        category: visibleCategories[i],
                        styleIndex: i,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.styleIndex});

  final StoryCategoryModel category;
  final int styleIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = Theme.of(context).colorScheme;
    final icon = _iconForCategory(category.title);
    final gradient = _gradientForIndex(styleIndex);

    return _FadeInCard(
      delay: Duration(milliseconds: 90 * styleIndex),
      child: _Pressable(
        child: AspectRatio(
          aspectRatio: 0.96,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: gradient,
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: styleIndex == 1 ? 0.54 : 0.08,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: colors.primary, size: 40),
                const SizedBox(height: 20),
                Text(
                  category.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForCategory(String title) {
    final value = title.toLowerCase();
    if (value.contains('sleep')) return Icons.nightlight_round;
    if (value.contains('happy') || value.contains('joy')) {
      return Icons.sentiment_satisfied_alt_rounded;
    }
    if (value.contains('lullaby') || value.contains('music')) {
      return Icons.music_note_rounded;
    }
    if (value.contains('growth') || value.contains('lesson')) {
      return Icons.psychology_alt_rounded;
    }
    if (value.contains('kind')) return Icons.favorite_rounded;
    return Icons.auto_stories_rounded;
  }

  LinearGradient _gradientForIndex(int index) {
    const gradients = [
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A1F55), Color(0xFF151A42)],
      ),
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF251F3F), Color(0xFF1B1830)],
      ),
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF29305B), Color(0xFF202746)],
      ),
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF252B3B), Color(0xFF1C2130)],
      ),
    ];

    return gradients[index % gradients.length];
  }
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({
    required this.imageUrl,
    required this.radius,
    this.overlay,
  });

  final String imageUrl;
  final double radius;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: _softBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _StoryImage(imageUrl: imageUrl),
            if (overlay != null)
              Positioned(left: 8, bottom: 8, child: overlay!),
          ],
        ),
      ),
    );
  }
}

class _StoryImage extends StatelessWidget {
  const _StoryImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final cacheWidth = (mediaQuery.size.width * mediaQuery.devicePixelRatio)
        .round();

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      memCacheWidth: cacheWidth,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (context, url) => const _ImagePlaceholder(),
      errorWidget: (context, url, error) =>
          const _ImagePlaceholder(icon: Icons.auto_stories_rounded),
    );
  }
}

class _EmptyHeartButton extends StatelessWidget {
  const _EmptyHeartButton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _Pressable(
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFF080C19).withValues(alpha: 0.46),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Icon(
          Icons.favorite_border_rounded,
          color: colors.primary,
          size: 17,
        ),
      ),
    );
  }
}

class _DurationBadge extends StatelessWidget {
  const _DurationBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return _GlassBadge(child: Text(label.toUpperCase()));
  }
}

class _GlassBadge extends StatelessWidget {
  const _GlassBadge({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTextStyle(
      style: theme.textTheme.labelSmall!.copyWith(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF080C19).withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: child,
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: index == activeIndex ? 16 : 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: index == activeIndex
                ? colors.primary
                : colors.onSurface.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _Pressable(
      onTap: onTap,
      child: SizedBox.square(
        dimension: 40,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            shape: BoxShape.circle,
            border: _softBorder,
          ),
          child: Icon(icon, color: colors.onSurface, size: 22),
        ),
      ),
    );
  }
}

class _ChildAvatar extends StatelessWidget {
  const _ChildAvatar({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [colors.primary, colors.tertiary]),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF202B62), Color(0xFF161B37)],
          ),
        ),
        child: Icon(Icons.face_4_rounded, color: colors.primary, size: 24),
      ),
    );
  }
}

class _LoadingSlivers extends StatelessWidget {
  const _LoadingSlivers();

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate.fixed([
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: _ShimmerBox(height: 176, radius: 24),
        ),
        const SizedBox(height: 46),
        const _LoadingRow(title: 'For You', tall: true),
        const SizedBox(height: 34),
        const _LoadingRow(title: 'Popular Tales'),
        const SizedBox(height: 34),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _ShimmerBox(width: 100, height: 24, radius: 10),
              SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _ShimmerBox(height: 150, radius: 22)),
                  SizedBox(width: 16),
                  Expanded(child: _ShimmerBox(height: 150, radius: 22)),
                ],
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow({required this.title, this.tall = false});

  final String title;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: const [
              _ShimmerBox(width: 118, height: 24, radius: 10),
              Spacer(),
              _ShimmerBox(width: 54, height: 18, radius: 9),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: tall ? 224 : 238,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) => _ShimmerBox(
              width: tall ? 150 : 178,
              height: tall ? 214 : 224,
              radius: 18,
            ),
          ),
        ),
      ],
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({required this.height, required this.radius, this.width});

  final double? width;
  final double height;
  final double radius;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.2 + _controller.value * 2.4, -0.7),
              end: Alignment(-0.2 + _controller.value * 2.4, 0.7),
              colors: [
                Colors.white.withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({this.icon});

  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF202A5F), Color(0xFF111832)],
        ),
      ),
      child: Center(
        child: Icon(
          icon ?? Icons.nightlight_round,
          color: colors.primary.withValues(alpha: 0.72),
          size: 34,
        ),
      ),
    );
  }
}

class _EmptyImageCard extends StatelessWidget {
  const _EmptyImageCard({
    required this.height,
    required this.icon,
    required this.label,
    this.width,
  });

  final double? width;
  final double height;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF121936).withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(22),
          border: _softBorder,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: colors.primary.withValues(alpha: 0.72),
                size: 34,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.58),
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FadeInCard extends StatelessWidget {
  const _FadeInCard({required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + delay.inMilliseconds),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final delayed =
            ((value * (360 + delay.inMilliseconds)) - delay.inMilliseconds)
                .clamp(0.0, 360.0) /
            360.0;

        return Opacity(
          opacity: delayed,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - delayed)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _AmbientBackdrop extends StatelessWidget {
  const _AmbientBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: const [
          Positioned(
            top: 88,
            right: -70,
            child: _Glow(size: 220, color: Color(0xFF7B76FF), opacity: 0.12),
          ),
          Positioned(
            top: 340,
            left: -92,
            child: _Glow(size: 240, color: Color(0xFFFFD66B), opacity: 0.06),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color, required this.opacity});

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 8,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: opacity),
              blurRadius: size * 0.55,
              spreadRadius: size * 0.22,
            ),
          ],
        ),
        child: SizedBox(width: size, height: size),
      ),
    );
  }
}

enum _NavigationItem { home, library, profile }

class _BedtimeBottomNavigation extends StatelessWidget {
  const _BedtimeBottomNavigation({required this.selectedItem, this.onHomeTap});

  final _NavigationItem selectedItem;
  final VoidCallback? onHomeTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111735).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _NavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              selected: selectedItem == _NavigationItem.home,
              onTap: onHomeTap,
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.menu_book_outlined,
              label: 'Library',
              selected: selectedItem == _NavigationItem.library,
              onTap: () {},
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.account_circle_outlined,
              label: 'Profile',
              selected: selectedItem == _NavigationItem.profile,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final activeColor = colors.primary;
    final inactiveColor = colors.onSurface.withValues(alpha: 0.54);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: selected ? activeColor : inactiveColor, size: 28),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? colors.onSurface : inactiveColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
