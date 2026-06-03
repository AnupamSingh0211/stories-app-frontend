import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/story_model.dart';
import '../providers/story_player_provider.dart';
import '../widgets/story_image_view.dart';
import 'story_player_screen.dart';

const _backgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF10163A), Color(0xFF0B1027), Color(0xFF070B19)],
);

final _softBorder = Border.all(color: Colors.white.withValues(alpha: 0.08));

class StorytimeScreen extends ConsumerStatefulWidget {
  const StorytimeScreen({super.key});

  @override
  ConsumerState<StorytimeScreen> createState() => _StorytimeScreenState();
}

class _StorytimeScreenState extends ConsumerState<StorytimeScreen> {
  final _pageController = PageController(viewportFraction: 0.9);
  int _activePage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contentState = ref.watch(storytimeContentProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: _backgroundGradient),
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  const SliverToBoxAdapter(child: _TopAppBar()),
                  contentState.when(
                    data: (content) => _StoryLibrary(
                      content: content,
                      pageController: _pageController,
                      activePage: _activePage,
                      onPageChanged: (page) {
                        final count = content.featuredBanners.length;
                        if (count == 0) {
                          return;
                        }
                        setState(() => _activePage = page % count);
                      },
                    ),
                    loading: () => const _LoadingLibrary(),
                    error: (error, stackTrace) => _StoryLibrary(
                      content: StorytimeContent.empty(),
                      pageController: _pageController,
                      activePage: _activePage,
                      onPageChanged: (_) {},
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
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colors.onSurface,
                fontSize: 30,
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

class _StoryLibrary extends StatelessWidget {
  const _StoryLibrary({
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
            cardStyle:
                entry.key == 0 ||
                    entry.value.title.toLowerCase().contains('for you')
                ? _StoryCardStyle.tall
                : _StoryCardStyle.square,
          ),
        ],
        if (content.categories.isNotEmpty) ...[
          const SizedBox(height: 34),
          _ExploreCategories(categories: content.categories),
        ],
      ]),
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
          label: 'Featured stories are loading',
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
            itemCount: banners.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: _FeaturedStoryCard(banner: banners[index]),
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
              StoryImageView(imageUrl: banner.imageUrl),
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

enum _StoryCardStyle { tall, square }

class _HorizontalStorySection extends StatelessWidget {
  const _HorizontalStorySection({
    required this.title,
    required this.stories,
    required this.cardStyle,
    this.titleIcon,
  });

  final String title;
  final IconData? titleIcon;
  final List<StoryModel> stories;
  final _StoryCardStyle cardStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isTall = cardStyle == _StoryCardStyle.tall;

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
                          fontSize: 30,
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
          height: isTall ? 278 : 260,
          child: stories.isEmpty
              ? ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _EmptyImageCard(
                      width: isTall ? 150 : 178,
                      height: isTall ? 248 : 224,
                      icon: Icons.auto_stories_rounded,
                      label: 'Stories are loading',
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
                      _StoryCard(story: stories[index], isTall: isTall),
                ),
        ),
      ],
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.story, required this.isTall});

  final StoryModel story;
  final bool isTall;

  bool get _opensPlayer =>
      isTall && story.title.trim().toLowerCase() == 'morning whispers';

  void _openPlayer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            StoryPlayerScreen(storyId: story.id, title: story.title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SizedBox(
      width: isTall ? 150 : 178,
      child: _Pressable(
        onTap: _opensPlayer ? () => _openPlayer(context) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: isTall ? 0.78 : 1,
              child: _ImageCard(
                imageUrl: story.thumbnailUrl,
                radius: isTall ? 16 : 18,
                overlay: isTall
                    ? const _EmptyHeartButton()
                    : _DurationBadge(label: story.durationLabel),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              story.title,
              maxLines: isTall ? 2 : 1,
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
              isTall
                  ? '${story.durationLabel} - ${story.category}'
                  : story.narrator?.isNotEmpty == true
                  ? story.narrator!
                  : story.category,
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
    );
  }
}

class _ExploreCategories extends StatelessWidget {
  const _ExploreCategories({required this.categories});

  final List<StoryCategoryModel> categories;

  @override
  Widget build(BuildContext context) {
    final visibleCategories = categories.take(4).toList(growable: false);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colors.primary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleCategories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (context, index) => _CategoryCard(
              category: visibleCategories[index],
              styleIndex: index,
            ),
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
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF121936).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: _softBorder,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_stories_rounded, color: colors.primary, size: 32),
            const SizedBox(height: 10),
            Text(
              category.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
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
            StoryImageView(imageUrl: imageUrl),
            if (overlay != null)
              Positioned(left: 8, bottom: 8, child: overlay!),
          ],
        ),
      ),
    );
  }
}

class _EmptyHeartButton extends StatelessWidget {
  const _EmptyHeartButton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
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
        dimension: 48,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            shape: BoxShape.circle,
            border: _softBorder,
          ),
          child: Icon(icon, color: colors.onSurface, size: 24),
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
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colors.primary, width: 2),
      ),
      child: Icon(Icons.face_4_rounded, color: colors.primary, size: 28),
    );
  }
}

class _LoadingLibrary extends StatelessWidget {
  const _LoadingLibrary();

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate.fixed([
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: _ShimmerBox(height: 176, radius: 24),
        ),
        const SizedBox(height: 46),
        const _LoadingRow(tall: true),
        const SizedBox(height: 34),
        const _LoadingRow(),
      ]),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow({this.tall = false});

  final bool tall;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: _ShimmerBox(width: 118, height: 28, radius: 10),
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
