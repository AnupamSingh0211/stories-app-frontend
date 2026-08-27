import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/analytics_service.dart';
import '../../core/supabase_config.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/widgets/custom_search_bar.dart';
import '../../shared/widgets/app_screen_background.dart';
import '../../shared/widgets/glassy_bottom_nav_bar.dart';
import '../../shared/widgets/play_circle_button.dart';
import '../../shared/widgets/story_card.dart';
import '../auth/profile_notifier.dart';
import '../library/library_sections_screen.dart';
import '../profile/profile_screen.dart';
import '../storytime/models/story_model.dart';
import '../storytime/providers/favorite_stories_provider.dart';
import '../storytime/providers/story_player_provider.dart';
import '../storytime/repositories/story_repository.dart';
import '../storytime/screens/episodes_screen.dart';
import '../storytime/screens/story_player_screen.dart';

const double _figmaWidth = 390;
const double _homeHeroBannerWidth = 359;
const double _homeHeroBannerHeight = 202;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    this.childName,
    this.childAge,
    this.initialTab = 0,
  });

  final String? childName;
  final int? childAge;
  final int initialTab;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late int _bottomNavIndex;
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _homeScrollController = ScrollController();
  bool _hasTrackedStoryListEnd = false;

  @override
  void initState() {
    super.initState();
    _bottomNavIndex = widget.initialTab.clamp(0, 2);
    _homeScrollController.addListener(_trackStoryListEndIfNeeded);
    unawaited(
      PostHogAnalytics.instance.screenOpened(
        'home_screen',
        properties: {'source': 'app_navigation'},
      ),
    );
    unawaited(
      PostHogAnalytics.instance.capture(
        'story_list_viewed',
        properties: {
          'screen_name': 'home_screen',
          'source': 'home_story_cards',
        },
      ),
    );
  }

  @override
  void dispose() {
    _homeScrollController
      ..removeListener(_trackStoryListEndIfNeeded)
      ..dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _trackStoryListEndIfNeeded() {
    if (_hasTrackedStoryListEnd || !_homeScrollController.hasClients) {
      return;
    }

    final position = _homeScrollController.position;
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
          'screen_name': 'home_screen',
          'source': 'home_story_cards',
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final selectedChild = profileState.valueOrNull?.selectedChild;
    final childName = _firstNonEmpty([
      selectedChild?.childName,
      widget.childName,
      'Little One',
    ]);
    final contentState = ref.watch(storytimeContentProvider);
    final storyCardsState = ref.watch(storyCardsProvider);
    final favoriteStoryCards = ref.watch(favoriteStoryCardsProvider);

    return MediaQuery.withNoTextScaling(
      child: Scaffold(
        body: AppScreenBackground(
          child: Stack(
            children: [
              Positioned.fill(
                child: SafeArea(
                  bottom: false,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final scale = (constraints.maxWidth / _figmaWidth)
                          .clamp(0.88, 1.16)
                          .toDouble();
                      final heroWidth = _homeHeroBannerWidth * scale;
                      final horizontal =
                          ((constraints.maxWidth - heroWidth) / 2)
                              .clamp(0.0, double.infinity)
                              .toDouble();
                      final banner = _resolveBanner(contentState.valueOrNull);
                      final homeStories = _homeStoryCards(
                        storyCardsState.valueOrNull ?? const [],
                      );

                      if (_bottomNavIndex == 1) {
                        return _PopularTab(
                          scale: scale,
                          stories:
                              contentState.valueOrNull?.popularStories ??
                              const [],
                          onBack: () => setState(() => _bottomNavIndex = 0),
                        );
                      }

                      if (_bottomNavIndex == 2) {
                        return _ComingSoonTab(
                          scale: scale,
                          onBack: () => setState(() => _bottomNavIndex = 0),
                        );
                      }

                      return SingleChildScrollView(
                        controller: _homeScrollController,
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          24 * scale,
                          horizontal,
                          118 * scale + MediaQuery.paddingOf(context).bottom,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Header(
                              name: childName,
                              scale: scale,
                              onFavoritesTap: () => _openFavorites(context),
                            ),
                            SizedBox(height: 24 * scale),
                            CustomSearchBar(focusNode: _searchFocusNode),
                            SizedBox(height: 20 * scale),
                            if (banner != null) ...[
                              _HeroBanner(
                                banner: banner,
                                scale: scale,
                                width: heroWidth,
                                height: _homeHeroBannerHeight * scale,
                              ),
                              SizedBox(height: 22 * scale),
                            ],
                            _SectionTitle('Top Picks for You', scale: scale),
                            SizedBox(height: 12 * scale),
                            _TwoColumnStoryGrid(
                              scale: scale,
                              stories: homeStories.take(2).toList(),
                              favoriteStoryIds: {
                                for (final card in favoriteStoryCards) card.id,
                              },
                            ),
                            if (homeStories.length > 2) ...[
                              SizedBox(height: 22 * scale),
                              _SectionTitle('Made for You', scale: scale),
                              SizedBox(height: 12 * scale),
                              _TwoColumnStoryGrid(
                                scale: scale,
                                stories: homeStories.skip(2).toList(),
                                favoriteStoryIds: {
                                  for (final card in favoriteStoryCards)
                                    card.id,
                                },
                              ),
                            ],
                            if (homeStories.isEmpty) ...[
                              SizedBox(height: 16 * scale),
                              Text(
                                'No stories available yet.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmallMedium.copyWith(
                                  color: Colors.white.withValues(alpha: 0.72),
                                ),
                              ),
                            ],
                            if (contentState.hasError) ...[
                              SizedBox(height: 16 * scale),
                              Text(
                                'Stories could not be refreshed.',
                                style: AppTypography.bodySmallMedium.copyWith(
                                  color: Colors.white.withValues(alpha: 0.72),
                                ),
                              ),
                            ],
                            if (storyCardsState.hasError) ...[
                              SizedBox(height: 16 * scale),
                              Text(
                                'Story cards could not be refreshed.',
                                style: AppTypography.bodySmallMedium.copyWith(
                                  color: Colors.white.withValues(alpha: 0.72),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: GlassyBottomNavBar(
                  currentIndex: _bottomNavIndex,
                  onTap: (index) {
                    _dismissSearchFocus();
                    if (index == 3) {
                      unawaited(
                        PostHogAnalytics.instance.buttonClicked(
                          buttonName: 'profile_tab',
                          screenName: 'home_screen',
                          properties: {'source': 'bottom_nav'},
                        ),
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => ProfileScreen(
                            fallbackChildName: childName,
                            fallbackChildAge:
                                selectedChild?.age ?? widget.childAge,
                          ),
                        ),
                      );
                      return;
                    }

                    unawaited(
                      PostHogAnalytics.instance.buttonClicked(
                        buttonName: 'bottom_nav_item',
                        screenName: 'home_screen',
                        properties: {
                          'source': 'bottom_nav',
                          'target_index': index,
                        },
                      ),
                    );
                    setState(() => _bottomNavIndex = index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _HomeBannerData? _resolveBanner(StorytimeContent? content) {
    final banner = content?.featuredBanners.firstOrNull;
    if (banner == null) {
      return null;
    }

    return _HomeBannerData(
      imageUrl: banner.imageUrl,
      title: banner.title,
      subtitle: banner.subtitle,
    );
  }

  void _openFavorites(BuildContext context) {
    _dismissSearchFocus();
    unawaited(
      PostHogAnalytics.instance.buttonClicked(
        buttonName: 'favorites',
        screenName: 'home_screen',
        properties: {'source': 'home_header'},
      ),
    );
    unawaited(
      PostHogAnalytics.instance.capture(
        'favorites_clicked',
        properties: {'screen_name': 'home_screen', 'source': 'home_header'},
      ),
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const LibrarySectionsScreen(),
      ),
    );
  }

  void _dismissSearchFocus() {
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
  }

  List<_HomeStoryCard> _homeStoryCards(List<StoryCardModel> cmsCards) {
    return List.unmodifiable(cmsCards.map(_HomeStoryCard.cms));
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.scale,
    required this.onFavoritesTap,
  });

  final String name;
  final double scale;
  final VoidCallback onFavoritesTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning,',
                style: AppTypography.bodySmallRegular.copyWith(
                  color: Colors.white,
                  fontSize: 12 * scale,
                ),
              ),
              SizedBox(height: 2 * scale),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyLargeBold.copyWith(
                  color: Colors.white,
                  fontSize: 16 * scale,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 16 * scale),
        Row(
          children: [
            _GlassyActionButton(
              label: 'Open favorites',
              iconPath: 'assets/icons/new_boopi/State=Default, Icon=Heart.svg',
              size: 42 * scale,
              onTap: onFavoritesTap,
            ),
            SizedBox(width: 10 * scale),
            _GlassyActionButton(
              label: 'Notifications',
              iconPath:
                  'assets/icons/new_boopi/State=Default, Icon=Notification.svg',
              size: 42 * scale,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _GlassyActionButton extends StatelessWidget {
  const _GlassyActionButton({
    required this.label,
    required this.iconPath,
    required this.size,
    required this.onTap,
  });

  final String label;
  final String iconPath;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
                border: Border.all(color: Colors.white.withValues(alpha: 0.38)),
              ),
              child: SvgPicture.asset(
                iconPath,
                width: size * 0.48,
                height: size * 0.48,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.banner,
    required this.scale,
    required this.width,
    required this.height,
  });

  final _HomeBannerData banner;
  final double scale;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('homeHeroBanner'),
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16 * scale),
          border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              offset: const Offset(0, 8),
              blurRadius: 18,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16 * scale),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                banner.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const ColoredBox(color: AppColors.backgroundHero);
                },
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                    stops: const [0.36, 0.66, 1],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16 * scale,
                  16 * scale,
                  16 * scale,
                  14 * scale,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            banner.subtitle,
                            style: AppTypography.captionBold.copyWith(
                              color: Colors.white,
                              fontSize: 10 * scale,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(height: 4 * scale),
                          Text(
                            banner.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyLargeBold.copyWith(
                              color: Colors.white,
                              fontSize: 16 * scale,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12 * scale),
                    PlayCircleButton(size: 42 * scale, onTap: () {}),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {required this.scale});

  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.bodyLargeBold.copyWith(
        color: Colors.white,
        fontSize: 16 * scale,
      ),
    );
  }
}

class _TwoColumnStoryGrid extends StatelessWidget {
  const _TwoColumnStoryGrid({
    required this.stories,
    required this.scale,
    required this.favoriteStoryIds,
  });

  final List<_HomeStoryCard> stories;
  final double scale;
  final Set<String> favoriteStoryIds;

  @override
  Widget build(BuildContext context) {
    final count = stories.length;
    if (count == 0) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 16 * scale;
        final cardWidth = (constraints.maxWidth - gap) / 2;

        return Wrap(
          spacing: gap,
          runSpacing: 16 * scale,
          children: [
            for (var index = 0; index < count; index += 1)
              SizedBox(
                width: cardWidth,
                height: 256 * scale,
                child: Consumer(
                  builder: (context, ref, child) {
                    final story = stories[index];
                    return StoryCard(
                      title: story.title,
                      imageUrl: story.thumbnailUrl,
                      episodeCount: story.episodeCountLabel,
                      imageHeight: 184 * scale,
                      onTap: () {
                        unawaited(
                          PostHogAnalytics.instance.capture(
                            'home_story_card_clicked',
                            properties: {
                              'screen_name': 'home_screen',
                              'source': 'home_story_cards',
                              'story_card_id': story.storyCard?.id ?? story.id,
                            },
                          ),
                        );
                        unawaited(
                          PostHogAnalytics.instance.buttonClicked(
                            buttonName: 'story_card',
                            screenName: 'home_screen',
                            properties: {
                              'source': 'home_story_cards',
                              'target_type': 'story_card',
                              'target_id': story.storyCard?.id ?? story.id,
                            },
                          ),
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) =>
                                EpisodesScreen(storyCard: story.storyCard),
                          ),
                        );
                      },
                      isFavorite:
                          story.storyCard != null &&
                          favoriteStoryIds.contains(story.storyCard!.id),
                      onFavoriteTap: () {
                        final storyCard = story.storyCard;
                        if (storyCard == null) {
                          _showFavoriteError(
                            context,
                            'This story card is not available to favorite yet.',
                          );
                          return;
                        }
                        unawaited(
                          _toggleFavoriteStoryCard(
                            context,
                            ref,
                            storyCard,
                            source: 'home_story_card',
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PopularTab extends StatelessWidget {
  const _PopularTab({
    required this.scale,
    required this.stories,
    required this.onBack,
  });

  final double scale;
  final List<StoryModel> stories;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = 118 * scale + MediaQuery.paddingOf(context).bottom;

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _TabHeader(title: 'Popular', scale: scale, onBack: onBack),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            16 * scale,
            0,
            16 * scale,
            bottomPadding,
          ),
          sliver: stories.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: _TabEmptyState(
                    scale: scale,
                    icon: Icons.auto_awesome_rounded,
                    title: 'No popular stories yet.',
                    subtitle:
                        'Popular picks will appear here as children listen.',
                  ),
                )
              : SliverList.separated(
                  itemCount: stories.length,
                  separatorBuilder: (context, index) =>
                      SizedBox(height: 12 * scale),
                  itemBuilder: (context, index) {
                    final story = stories[index];
                    return _PopularStoryTile(story: story, scale: scale);
                  },
                ),
        ),
      ],
    );
  }
}

class _PopularStoryTile extends StatelessWidget {
  const _PopularStoryTile({required this.story, required this.scale});

  final StoryModel story;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => StoryPlayerScreen(
              storyId: story.id,
              title: story.title,
              story: story,
            ),
          ),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.backgroundGlass,
          borderRadius: BorderRadius.circular(12 * scale),
          border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        ),
        child: Padding(
          padding: EdgeInsets.all(12 * scale),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8 * scale),
                child: SizedBox.square(
                  dimension: 72 * scale,
                  child: Image.network(
                    story.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return ColoredBox(
                        color: Colors.white.withValues(alpha: 0.18),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMediumSemiBold.copyWith(
                        color: AppColors.textOnPrimary,
                        fontSize: 14 * scale,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      story.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmallMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12 * scale,
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

class _HomeStoryCard {
  const _HomeStoryCard({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.category,
    required this.episodeCountLabel,
    this.storyCard,
  });

  factory _HomeStoryCard.cms(StoryCardModel storyCard) {
    return _HomeStoryCard(
      id: storyCard.id,
      title: storyCard.title,
      thumbnailUrl: storyCard.thumbnailUrl,
      category: storyCard.category,
      episodeCountLabel: storyCard.category,
      storyCard: storyCard,
    );
  }

  final String id;
  final String title;
  final String thumbnailUrl;
  final String category;
  final String episodeCountLabel;
  final StoryCardModel? storyCard;
}

class _ComingSoonTab extends StatefulWidget {
  const _ComingSoonTab({required this.scale, required this.onBack});

  final double scale;
  final VoidCallback onBack;

  @override
  State<_ComingSoonTab> createState() => _ComingSoonTabState();
}

class _ComingSoonTabState extends State<_ComingSoonTab> {
  final Set<String> _likedStoryIds = {};
  final Set<String> _dislikedStoryIds = {};

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final bottomPadding = 118 * scale + MediaQuery.paddingOf(context).bottom;

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _TabHeader(
            title: 'Coming Soon',
            scale: scale,
            onBack: widget.onBack,
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            16 * scale,
            0,
            16 * scale,
            bottomPadding,
          ),
          sliver: _comingSoonStories.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: _TabEmptyState(
                    scale: scale,
                    icon: Icons.upcoming_rounded,
                    title: 'New stories are on the way.',
                    subtitle:
                        'Upcoming CMS stories will appear here for preview voting.',
                  ),
                )
              : SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final maxContentWidth = 358 * scale;
                    final availableWidth = constraints.crossAxisExtent;
                    final contentWidth = availableWidth < maxContentWidth
                        ? availableWidth
                        : maxContentWidth;
                    final gap = 16 * scale;
                    final cardWidth = (contentWidth - gap) / 2;

                    return SliverToBoxAdapter(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: contentWidth,
                          child: Wrap(
                            spacing: gap,
                            runSpacing: 16 * scale,
                            children: [
                              for (final story in _comingSoonStories)
                                ComingSoonStoryCard(
                                  title: story.title,
                                  imageUrl: story.imageUrl,
                                  width: cardWidth,
                                  scale: scale,
                                  isLiked: _likedStoryIds.contains(story.id),
                                  isDisliked: _dislikedStoryIds.contains(
                                    story.id,
                                  ),
                                  onLikeTap: () {
                                    setState(() {
                                      if (!_likedStoryIds.add(story.id)) {
                                        _likedStoryIds.remove(story.id);
                                      }
                                      _dislikedStoryIds.remove(story.id);
                                    });
                                  },
                                  onDislikeTap: () {
                                    setState(() {
                                      if (!_dislikedStoryIds.add(story.id)) {
                                        _dislikedStoryIds.remove(story.id);
                                      }
                                      _likedStoryIds.remove(story.id);
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _TabHeader extends StatelessWidget {
  const _TabHeader({
    required this.title,
    required this.scale,
    required this.onBack,
  });

  final String title;
  final double scale;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56 * scale,
      child: Padding(
        padding: EdgeInsets.all(16 * scale),
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBack,
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textOnPrimary,
                size: 24 * scale,
              ),
            ),
            SizedBox(width: 12 * scale),
            Text(
              title,
              style: AppTypography.heading3SemiBold.copyWith(
                color: AppColors.textOnPrimary,
                fontSize: 20 * scale,
                height: 24 / 20,
                letterSpacing: -0.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabEmptyState extends StatelessWidget {
  const _TabEmptyState({
    required this.scale,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final double scale;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.backgroundGlass,
          borderRadius: BorderRadius.circular(16 * scale),
          border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        ),
        child: Padding(
          padding: EdgeInsets.all(20 * scale),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.textOnPrimary, size: 34 * scale),
              SizedBox(height: 12 * scale),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMediumSemiBold.copyWith(
                  color: AppColors.textOnPrimary,
                  fontSize: 14 * scale,
                ),
              ),
              SizedBox(height: 6 * scale),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmallMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 12 * scale,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeBannerData {
  const _HomeBannerData({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
  });

  final String imageUrl;
  final String title;
  final String subtitle;
}

String _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
  }

  return '';
}

Future<void> _toggleFavoriteStoryCard(
  BuildContext context,
  WidgetRef ref,
  StoryCardModel storyCard, {
  required String source,
}) async {
  try {
    await ref
        .read(favoriteStoryCardsProvider.notifier)
        .toggleStoryCard(storyCard, source: source);
  } on StoryRepositoryException catch (error) {
    if (!context.mounted) return;
    _showFavoriteError(context, error.message);
  }
}

void _showFavoriteError(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String _comingSoonPreviewUrl(String fileName) {
  return SupabaseConfig.appAssetsPublicUrl('story_thumbnails/$fileName');
}

class _ComingSoonStoryPreview {
  const _ComingSoonStoryPreview({
    required this.id,
    required this.title,
    required this.imageUrl,
  });

  final String id;
  final String title;
  final String imageUrl;
}

final _comingSoonStories = [
  _ComingSoonStoryPreview(
    id: 'coming-soon-nanha-sapno',
    title: 'Nanha Sapno Ka Safar',
    imageUrl: _comingSoonPreviewUrl('Frame_1.png'),
  ),
  _ComingSoonStoryPreview(
    id: 'coming-soon-ghar-ki-pyari',
    title: 'Ghar Ki Pyari Kahani',
    imageUrl: _comingSoonPreviewUrl('Frame_2.png'),
  ),
  _ComingSoonStoryPreview(
    id: 'coming-soon-nadi-kinare',
    title: 'Nadi Kinare Ka Safar',
    imageUrl: _comingSoonPreviewUrl('Frame_3.png'),
  ),
  _ComingSoonStoryPreview(
    id: 'coming-soon-mitti-mahal',
    title: 'Mitti Ka Mahal',
    imageUrl: _comingSoonPreviewUrl('Frame_4.png'),
  ),
  _ComingSoonStoryPreview(
    id: 'coming-soon-ratri-kahani',
    title: 'Ratri Ki Pyari Kahani',
    imageUrl: _comingSoonPreviewUrl('Frame_5.png'),
  ),
  _ComingSoonStoryPreview(
    id: 'coming-soon-hansi-safar',
    title: 'Hansi Ka Jadui Safar',
    imageUrl: _comingSoonPreviewUrl('Frame_6.png'),
  ),
];
