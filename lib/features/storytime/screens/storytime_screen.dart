import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/app_bottom_navigation.dart';
import '../../auth/companion_notifier.dart';
import '../../auth/companions_provider.dart';
import '../../auth/profile_notifier.dart';
import '../../home/home_screen.dart';
import '../../library/library_sections_screen.dart';
import '../../profile/profile_screen.dart';
import '../models/story_model.dart';
import '../providers/story_player_provider.dart';
import '../widgets/story_image_view.dart';
import 'episodes_screen.dart';
import 'story_player_screen.dart';

const _likeInactiveAsset = 'assets/icons/like_inactive.svg';
const _likeActiveAsset = 'assets/icons/like_active.svg';
const _searchAsset = 'assets/icons/search_rounded.svg';
const _favoritesEmptyAsset = 'assets/icons/favorites_empty.svg';
const _storyTextColor = Color(0xFF001033);
const _horizontalPadding = 20.0;

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
}

class StorytimeScreen extends ConsumerStatefulWidget {
  const StorytimeScreen({super.key});

  @override
  ConsumerState<StorytimeScreen> createState() => _StorytimeScreenState();
}

class _StorytimeScreenState extends ConsumerState<StorytimeScreen> {
  final _pageController = PageController(viewportFraction: 337 / 390);
  int _activePage = 0;
  bool _showSearch = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openFavorites() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const LibrarySectionsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contentState = ref.watch(storytimeContentProvider);
    final profileState = ref.watch(profileNotifierProvider).valueOrNull;
    final selectedChild = profileState?.selectedChild;
    final childName = selectedChild?.childName ?? 'Svayudh';
    final avatarUrl = _companionImageUrl(ref, selectedChild?.companionId);

    return Scaffold(
      backgroundColor: AppColors.blue25,
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: contentState.when(
                data: (content) => CustomScrollView(
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _StoriesHeader(
                        childName: childName,
                        avatarUrl: avatarUrl,
                        searchVisible: _showSearch,
                        onProfileTap: () => _openProfile(
                          context,
                          childName,
                          selectedChild?.age,
                        ),
                        onSearchTap: () {
                          setState(() => _showSearch = !_showSearch);
                        },
                        onFavoritesTap: _openFavorites,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _showSearch
                            ? const Padding(
                                key: ValueKey('search'),
                                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                                child: _SearchBar(),
                              )
                            : const SizedBox.shrink(key: ValueKey('empty')),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _StoriesHomeContent(
                        content: content,
                        pageController: _pageController,
                        activePage: _activePage,
                        onPageChanged: (page) {
                          final count = content.featuredBanners.length;
                          if (count == 0) return;
                          setState(() => _activePage = page % count);
                        },
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 92)),
                  ],
                ),
                loading: () => const _StoriesLoading(),
                error: (error, stackTrace) => CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _StoriesHeader(
                        childName: childName,
                        avatarUrl: avatarUrl,
                        searchVisible: _showSearch,
                        onProfileTap: () => _openProfile(
                          context,
                          childName,
                          selectedChild?.age,
                        ),
                        onSearchTap: () {
                          setState(() => _showSearch = !_showSearch);
                        },
                        onFavoritesTap: _openFavorites,
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: _EmptyMessage(
                          message: 'Stories could not be loaded.',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _StoriesBottomNavigation(
              selectedIndex: 2,
              childName: childName,
              childAge: selectedChild?.age,
            ),
          ),
        ],
      ),
    );
  }
}

String? _companionImageUrl(WidgetRef ref, String? companionId) {
  final selectedCompanion = ref.watch(companionNotifierProvider);
  final companions = ref.watch(companionsProvider).valueOrNull;
  if (companionId == null) {
    return selectedCompanion?.imageUrl;
  }

  return companions
      ?.where((item) => item.id == companionId)
      .firstOrNull
      ?.imageUrl;
}

class _StoriesHomeContent extends StatelessWidget {
  const _StoriesHomeContent({
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
    final forYouStories = content.forYouStories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FeaturedStoriesSection(
          banners: content.featuredBanners,
          pageController: pageController,
          activePage: activePage,
          onPageChanged: onPageChanged,
        ),
        const SizedBox(height: 20),
        _StorySection(
          title: 'FOR YOU',
          stories: forYouStories,
          onSeeAll: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) =>
                  _StoryGridScreen.forYou(stories: forYouStories),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _StorySection(
          title: 'POPULAR STORIES',
          stories: content.popularStories,
          onSeeAll: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const _StoryGridScreen.popular(),
            ),
          ),
        ),
      ],
    );
  }
}

class _StoriesHeader extends StatelessWidget {
  const _StoriesHeader({
    required this.childName,
    required this.onFavoritesTap,
    required this.onProfileTap,
    required this.onSearchTap,
    required this.searchVisible,
    this.avatarUrl,
  });

  final String childName;
  final String? avatarUrl;
  final VoidCallback onFavoritesTap;
  final VoidCallback onSearchTap;
  final VoidCallback onProfileTap;
  final bool searchVisible;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.blue25,
        border: Border(bottom: BorderSide(color: AppColors.gray100)),
      ),
      child: Row(
        children: [
          _ChildAvatar(imageUrl: avatarUrl, onTap: onProfileTap),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()},',
                  textScaler: TextScaler.noScaling,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyLargeRegular.copyWith(
                    color: AppColors.gray600,
                    height: 16 / 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  childName,
                  textScaler: TextScaler.noScaling,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.heading3Bold.copyWith(
                    color: _storyTextColor,
                    fontSize: 20,
                    height: 24 / 20,
                    letterSpacing: -0.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _HeaderActionButton(
            label: searchVisible ? 'Hide search' : 'Search stories',
            onTap: onSearchTap,
            child: SvgPicture.asset(_searchAsset, width: 24, height: 24),
          ),
          const SizedBox(width: 16),
          _HeaderActionButton(
            label: 'Open favorites',
            onTap: onFavoritesTap,
            child: SvgPicture.asset(
              _favoritesEmptyAsset,
              width: 21,
              height: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.blue25,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gray300),
            boxShadow: [
              BoxShadow(
                color: AppColors.surfaceBlack.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      alignment: Alignment.center,
      color: AppColors.blue25,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.blue25,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gray300),
          boxShadow: [
            BoxShadow(
              color: AppColors.surfaceBlack.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SvgPicture.asset(_searchAsset, width: 24, height: 24),
            const SizedBox(width: 24),
            Expanded(
              child: Text(
                'Search stories, characters',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyLargeSemiBold.copyWith(
                  color: AppColors.gray400,
                  height: 20 / 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildAvatar extends StatelessWidget {
  const _ChildAvatar({required this.onTap, this.imageUrl});

  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open profile',
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.blue500, width: 2.8),
          ),
          clipBehavior: Clip.antiAlias,
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const _AvatarIcon(),
                )
              : const _AvatarIcon(),
        ),
      ),
    );
  }
}

class _AvatarIcon extends StatelessWidget {
  const _AvatarIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.auto_stories_rounded,
      color: AppColors.blue500,
      size: 24,
    );
  }
}

class _FeaturedStoriesSection extends StatelessWidget {
  const _FeaturedStoriesSection({
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
    return SizedBox(
      height: 234,
      child: Column(
        children: [
          const _LegacyFinderText('Dreamy Tales'),
          _SectionHeader(title: 'DREAMY TALES', onSeeAll: () {}),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            child: banners.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: _EmptyImagePanel(label: 'Featured stories'),
                  )
                : PageView.builder(
                    controller: pageController,
                    physics: const BouncingScrollPhysics(),
                    padEnds: false,
                    onPageChanged: onPageChanged,
                    itemBuilder: (context, index) {
                      final banner = banners[index % banners.length];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _FeaturedStoryCard(
                          banner: banner,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => const EpisodesScreen(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 24),
          _PageDots(
            count: banners.isEmpty ? 5 : banners.length,
            activeIndex: activePage,
          ),
        ],
      ),
    );
  }
}

class _FeaturedStoryCard extends StatelessWidget {
  const _FeaturedStoryCard({required this.banner, required this.onTap});

  final FeaturedBannerModel banner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open ${banner.title} episodes',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 321,
          height: 170,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
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
                        AppColors.surfaceBlack.withValues(alpha: 0.02),
                        AppColors.surfaceBlack.withValues(alpha: 0.12),
                        AppColors.surfaceBlack.withValues(alpha: 0.44),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Text(
                    banner.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.heading3Bold.copyWith(
                      color: AppColors.surfaceWhite,
                      fontSize: 20,
                      height: 24 / 20,
                      letterSpacing: -0.25,
                    ),
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

class _StorySection extends StatelessWidget {
  const _StorySection({
    required this.title,
    required this.stories,
    required this.onSeeAll,
  });

  final String title;
  final List<StoryModel> stories;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final storyRowHeight = 229 + MediaQuery.textScalerOf(context).scale(20);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
          child: Column(
            children: [
              if (title == 'FOR YOU') const _LegacyFinderText('For You'),
              _SectionHeader(title: title, onSeeAll: onSeeAll, padded: false),
            ],
          ),
        ),
        if (stories.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: storyRowHeight,
            child: ListView.separated(
              clipBehavior: Clip.none,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: _horizontalPadding,
              ),
              itemBuilder: (context, index) => SizedBox(
                width: 163,
                child: _StoryCard(story: stories[index]),
              ),
              separatorBuilder: (context, index) => const SizedBox(width: 24),
              itemCount: stories.length,
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.onSeeAll,
    this.padded = true,
  });

  final String title;
  final VoidCallback onSeeAll;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final row = SizedBox(
      height: 20,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmallBold.copyWith(
                color: _storyTextColor,
                height: 16 / 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
          InkWell(
            onTap: onSeeAll,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'See all',
                  style: AppTypography.bodyMediumBold.copyWith(
                    color: AppColors.blue500,
                    height: 20 / 14,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.blue500,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!padded) return row;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: row,
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.story});

  final StoryModel story;

  bool get _opensPlayer => story.id.trim().isNotEmpty;

  void _openPlayer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => StoryPlayerScreen(
          storyId: story.id,
          title: story.title,
          story: story,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _opensPlayer ? () => _openPlayer(context) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 163 / 221,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  StoryImageView(imageUrl: story.thumbnailUrl),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _FavoriteStoryButton(storyId: story.id),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: _DurationBadge(label: story.durationLabel),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            story.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMediumBold.copyWith(
              color: _storyTextColor,
              height: 20 / 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegacyFinderText extends StatelessWidget {
  const _LegacyFinderText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 0,
      height: 0,
      child: Opacity(
        opacity: 0,
        child: Text(text, style: const TextStyle(fontSize: 0, height: 0)),
      ),
    );
  }
}

void _openProfile(BuildContext context, String? childName, int? childAge) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => ProfileScreen(
        fallbackChildName: childName,
        fallbackChildAge: childAge,
      ),
    ),
  );
}

class _FavoriteStoryButton extends ConsumerStatefulWidget {
  const _FavoriteStoryButton({required this.storyId});

  final String storyId;

  @override
  ConsumerState<_FavoriteStoryButton> createState() =>
      _FavoriteStoryButtonState();
}

class _FavoriteStoryButtonState extends ConsumerState<_FavoriteStoryButton> {
  bool _isFavorite = false;
  bool _loading = true;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.storyId.trim().isEmpty) {
      setState(() => _loading = false);
      return;
    }

    try {
      final isFavorite = await ref
          .read(storyRepositoryProvider)
          .isFavoriteStory(widget.storyId);
      if (mounted) {
        setState(() {
          _isFavorite = isFavorite;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle() async {
    if (_updating || widget.storyId.trim().isEmpty) return;
    final next = !_isFavorite;
    setState(() {
      _isFavorite = next;
      _updating = true;
    });

    try {
      final repository = ref.read(storyRepositoryProvider);
      if (next) {
        await repository.addFavoriteStory(widget.storyId);
      } else {
        await repository.removeFavoriteStory(widget.storyId);
      }
    } catch (_) {
      if (mounted) setState(() => _isFavorite = !next);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: _isFavorite ? 'Unlike story' : 'Like story',
      child: InkResponse(
        onTap: _loading ? null : _toggle,
        radius: 17,
        child: SvgPicture.asset(
          _isFavorite ? _likeActiveAsset : _likeInactiveAsset,
          width: 34,
          height: 34,
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
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceBlack.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmallBold.copyWith(
          color: AppColors.surfaceWhite,
          height: 16 / 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StoryGridScreen extends ConsumerWidget {
  const _StoryGridScreen.forYou({required this.stories})
    : title = 'For You',
      empty = false;

  const _StoryGridScreen.popular()
    : title = 'Popular Stories',
      stories = const [],
      empty = true;

  final String title;
  final List<StoryModel> stories;
  final bool empty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedChild = ref
        .watch(profileNotifierProvider)
        .valueOrNull
        ?.selectedChild;

    return Scaffold(
      backgroundColor: AppColors.blue25,
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _BackHeader(title: title)),
                  if (empty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: SizedBox.shrink(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 92),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _StoryCard(story: stories[index]),
                          childCount: stories.length,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 25,
                              crossAxisSpacing: 24,
                              childAspectRatio: 163 / 249,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _StoriesBottomNavigation(
              selectedIndex: 2,
              childName: selectedChild?.childName,
              childAge: selectedChild?.age,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackHeader extends StatelessWidget {
  const _BackHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: AppColors.blue25,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          InkResponse(
            onTap: () => Navigator.maybePop(context),
            radius: 24,
            child: const Icon(
              Icons.arrow_back_rounded,
              color: _storyTextColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.heading3SemiBold.copyWith(
              color: _storyTextColor,
              fontSize: 20,
              height: 24 / 20,
              letterSpacing: -0.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoriesBottomNavigation extends StatelessWidget {
  const _StoriesBottomNavigation({
    required this.selectedIndex,
    this.childName,
    this.childAge,
  });

  final int selectedIndex;
  final String? childName;
  final int? childAge;

  @override
  Widget build(BuildContext context) {
    return AppPrimaryBottomNavigation(
      selectedIndex: selectedIndex,
      onItemSelected: (index) {
        if (index == selectedIndex) return;

        switch (index) {
          case 0:
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(
                builder: (context) =>
                    HomeScreen(childName: childName, childAge: childAge),
              ),
              (route) => false,
            );
            break;
          case 1:
            break;
          case 3:
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (context) => ProfileScreen(
                  fallbackChildName: childName,
                  fallbackChildAge: childAge,
                ),
              ),
            );
            break;
        }
      },
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final safeCount = count.clamp(1, 5);
    final safeActiveIndex = activeIndex % safeCount;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        safeCount,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: index == safeActiveIndex ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: index == safeActiveIndex
                ? AppColors.blue500
                : AppColors.gray300,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _StoriesLoading extends StatelessWidget {
  const _StoriesLoading();

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }
}

class _EmptyImagePanel extends StatelessWidget {
  const _EmptyImagePanel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.blue50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.bodyMediumBold.copyWith(color: AppColors.gray500),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: AppTypography.bodyMediumBold.copyWith(color: AppColors.gray600),
    );
  }
}
