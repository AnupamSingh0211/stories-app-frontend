import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/analytics_service.dart';
import '../../core/supabase_config.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_tokens.dart';
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
    final tokenColors = AppTokenColors.of(ref);
    final tokenTextStyles = AppTokenTextStyles.of(ref);
    final contentColor = tokenColors.homeCardTextPrimary;

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
                              contentColor: contentColor,
                              actionBackgroundColor:
                                  tokenColors.homeActionBackground,
                              actionBorderColor: tokenColors.homeActionBorder,
                              greetingLabelStyle:
                                  tokenTextStyles.homeGreetingLabel,
                              greetingNameStyle:
                                  tokenTextStyles.homeGreetingName,
                              onFavoritesTap: () => _openFavorites(context),
                            ),
                            SizedBox(height: 24 * scale),
                            CustomSearchBar(
                              focusNode: _searchFocusNode,
                              contentColor: contentColor,
                              backgroundColor: tokenColors.homeSearchBackground,
                              borderColor: tokenColors.homeSearchBorder,
                              inputTextStyle: tokenTextStyles.homeSearchInput,
                            ),
                            SizedBox(height: 20 * scale),
                            if (banner != null) ...[
                              _HeroBanner(
                                banner: banner,
                                scale: scale,
                                width: heroWidth,
                                height: _homeHeroBannerHeight * scale,
                                contentColor: contentColor,
                                overlayStartColor:
                                    tokenColors.homeHeroOverlayStart,
                                overlayMiddleColor:
                                    tokenColors.homeHeroOverlayMiddle,
                                overlayEndColor: tokenColors.homeHeroOverlayEnd,
                                borderColor: tokenColors.homeHeroBorder,
                                shadowColor: tokenColors.homeHeroShadow,
                                eyebrowStyle: tokenTextStyles.homeHeroEyebrow,
                                titleStyle: tokenTextStyles.homeHeroTitle,
                              ),
                              SizedBox(height: 22 * scale),
                            ],
                            _SectionTitle(
                              'Top Picks for You',
                              scale: scale,
                              contentColor: contentColor,
                              textStyle: tokenTextStyles.homeSectionTitle,
                            ),
                            SizedBox(height: 12 * scale),
                            _TwoColumnStoryGrid(
                              scale: scale,
                              stories: homeStories.take(2).toList(),
                              contentColor: contentColor,
                              titleStyle: tokenTextStyles.homeStoryCardTitle,
                              metaStyle: tokenTextStyles.homeStoryCardMeta,
                              favoriteStoryIds: {
                                for (final card in favoriteStoryCards) card.id,
                              },
                            ),
                            if (homeStories.length > 2) ...[
                              SizedBox(height: 22 * scale),
                              _SectionTitle(
                                'Made for You',
                                scale: scale,
                                contentColor: contentColor,
                                textStyle: tokenTextStyles.homeSectionTitle,
                              ),
                              SizedBox(height: 12 * scale),
                              _TwoColumnStoryGrid(
                                scale: scale,
                                stories: homeStories.skip(2).toList(),
                                contentColor: contentColor,
                                titleStyle: tokenTextStyles.homeStoryCardTitle,
                                metaStyle: tokenTextStyles.homeStoryCardMeta,
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
                                  color: contentColor.withValues(alpha: 0.72),
                                ),
                              ),
                            ],
                            if (contentState.hasError) ...[
                              SizedBox(height: 16 * scale),
                              Text(
                                'Stories could not be refreshed.',
                                style: AppTypography.bodySmallMedium.copyWith(
                                  color: contentColor.withValues(alpha: 0.72),
                                ),
                              ),
                            ],
                            if (storyCardsState.hasError) ...[
                              SizedBox(height: 16 * scale),
                              Text(
                                'Story cards could not be refreshed.',
                                style: AppTypography.bodySmallMedium.copyWith(
                                  color: contentColor.withValues(alpha: 0.72),
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
                  contentColor: contentColor,
                  backgroundColor: tokenColors.homeNavBackground,
                  borderColor: tokenColors.homeNavBorder,
                  activeBackgroundColor: tokenColors.homeNavActiveBackground,
                  activeBorderColor: tokenColors.homeNavActiveBorder,
                  defaultIconColor: tokenColors.homeNavIconDefault,
                  selectedIconColor: tokenColors.homeNavIconSelected,
                  defaultLabelColor: tokenColors.homeNavLabelDefault,
                  selectedLabelColor: tokenColors.homeNavLabelSelected,
                  defaultLabelStyle: tokenTextStyles.homeNavLabelDefault,
                  selectedLabelStyle: tokenTextStyles.homeNavLabelSelected,
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
    required this.contentColor,
    required this.actionBackgroundColor,
    required this.actionBorderColor,
    required this.greetingLabelStyle,
    required this.greetingNameStyle,
    required this.onFavoritesTap,
  });

  final String name;
  final double scale;
  final Color contentColor;
  final Color actionBackgroundColor;
  final Color actionBorderColor;
  final TextStyle greetingLabelStyle;
  final TextStyle greetingNameStyle;
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
                style: greetingLabelStyle.copyWith(
                  color: contentColor,
                  fontSize: 12 * scale,
                ),
              ),
              SizedBox(height: 2 * scale),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: greetingNameStyle.copyWith(
                  color: contentColor,
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
              contentColor: contentColor,
              backgroundColor: actionBackgroundColor,
              borderColor: actionBorderColor,
              onTap: onFavoritesTap,
            ),
            SizedBox(width: 10 * scale),
            _GlassyActionButton(
              label: 'Notifications',
              iconPath:
                  'assets/icons/new_boopi/State=Default, Icon=Notification.svg',
              size: 42 * scale,
              contentColor: contentColor,
              backgroundColor: actionBackgroundColor,
              borderColor: actionBorderColor,
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
    required this.contentColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
  final String iconPath;
  final double size;
  final Color contentColor;
  final Color backgroundColor;
  final Color borderColor;
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
                color: backgroundColor,
                border: Border.all(color: borderColor),
              ),
              child: SvgPicture.asset(
                iconPath,
                width: size * 0.48,
                height: size * 0.48,
                colorFilter: ColorFilter.mode(contentColor, BlendMode.srcIn),
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
    required this.contentColor,
    required this.overlayStartColor,
    required this.overlayMiddleColor,
    required this.overlayEndColor,
    required this.borderColor,
    required this.shadowColor,
    required this.eyebrowStyle,
    required this.titleStyle,
  });

  final _HomeBannerData banner;
  final double scale;
  final double width;
  final double height;
  final Color contentColor;
  final Color overlayStartColor;
  final Color overlayMiddleColor;
  final Color overlayEndColor;
  final Color borderColor;
  final Color shadowColor;
  final TextStyle eyebrowStyle;
  final TextStyle titleStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('homeHeroBanner'),
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16 * scale),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
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
                      overlayStartColor,
                      overlayMiddleColor,
                      overlayEndColor,
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
                            style: eyebrowStyle.copyWith(
                              color: contentColor,
                              fontSize: 10 * scale,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(height: 4 * scale),
                          Text(
                            banner.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: titleStyle.copyWith(
                              color: contentColor,
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
  const _SectionTitle(
    this.text, {
    required this.scale,
    required this.contentColor,
    required this.textStyle,
  });

  final String text;
  final double scale;
  final Color contentColor;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: textStyle.copyWith(color: contentColor, fontSize: 16 * scale),
    );
  }
}

class _TwoColumnStoryGrid extends StatelessWidget {
  const _TwoColumnStoryGrid({
    required this.stories,
    required this.scale,
    required this.contentColor,
    required this.titleStyle,
    required this.metaStyle,
    required this.favoriteStoryIds,
  });

  final List<_HomeStoryCard> stories;
  final double scale;
  final Color contentColor;
  final TextStyle titleStyle;
  final TextStyle metaStyle;
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
                    final tokenColors = AppTokenColors.of(ref);
                    return StoryCard(
                      title: story.title,
                      imageUrl: story.thumbnailUrl,
                      episodeCount: story.episodeCountLabel,
                      imageHeight: 184 * scale,
                      contentColor: contentColor,
                      backgroundColor: tokenColors.homeCardBackground,
                      shadowColor: tokenColors.homeCardShadow,
                      imagePlaceholderColor:
                          tokenColors.homeStoryCardImagePlaceholder,
                      favoriteBackgroundColor:
                          tokenColors.homeStoryCardFavoriteBackground,
                      favoriteBorderColor:
                          tokenColors.homeStoryCardFavoriteBorder,
                      badgeBackgroundColor:
                          tokenColors.homeStoryCardBadgeBackground,
                      badgeBorderColor: tokenColors.homeStoryCardBadgeBorder,
                      titleStyle: titleStyle,
                      metaStyle: metaStyle,
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

class _PopularStoryTile extends ConsumerWidget {
  const _PopularStoryTile({required this.story, required this.scale});

  final StoryModel story;
  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenColors = AppTokenColors.of(ref);
    final tokenTextStyles = AppTokenTextStyles.of(ref);

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
          color: tokenColors.homeCardBackground,
          borderRadius: BorderRadius.circular(12 * scale),
          border: Border.all(color: tokenColors.homeCardBorder),
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
                        color: tokenColors.homeStoryCardImagePlaceholder,
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
                      style: tokenTextStyles.homeStoryCardTitle.copyWith(
                        color: tokenColors.homeCardTextPrimary,
                        fontSize: 14 * scale,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      story.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tokenTextStyles.homeStoryCardMeta.copyWith(
                        color: tokenColors.homeCardTextPrimary.withValues(
                          alpha: 0.72,
                        ),
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

class _ComingSoonTab extends ConsumerStatefulWidget {
  const _ComingSoonTab({required this.scale, required this.onBack});

  final double scale;
  final VoidCallback onBack;

  @override
  ConsumerState<_ComingSoonTab> createState() => _ComingSoonTabState();
}

class _ComingSoonTabState extends ConsumerState<_ComingSoonTab> {
  final Set<String> _likedStoryIds = {};
  final Set<String> _dislikedStoryIds = {};

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final bottomPadding = 118 * scale + MediaQuery.paddingOf(context).bottom;
    final tokenColors = AppTokenColors.of(ref);
    final tokenTextStyles = AppTokenTextStyles.of(ref);
    final contentColor = tokenColors.homeCardTextPrimary;

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _TabHeader(
            title: 'Coming Soon',
            scale: scale,
            onBack: widget.onBack,
            contentColor: contentColor,
            textStyle: tokenTextStyles.soonHeaderTitle,
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
                    contentColor: contentColor,
                    titleStyle: tokenTextStyles.soonEmptyTitle,
                    subtitleStyle: tokenTextStyles.soonEmptySubtitle,
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
                                  contentColor: contentColor,
                                  backgroundColor:
                                      tokenColors.soonCardBackground,
                                  borderColor: tokenColors.soonCardBorder,
                                  shadowColor: tokenColors.soonCardShadow,
                                  imagePlaceholderColor:
                                      tokenColors.soonImagePlaceholder,
                                  badgeBackgroundStart:
                                      tokenColors.soonBadgeBackgroundStart,
                                  badgeBackgroundEnd:
                                      tokenColors.soonBadgeBackgroundEnd,
                                  badgeTextColor: tokenColors.soonBadgeText,
                                  voteIconDefaultColor:
                                      tokenColors.soonVoteIconDefault,
                                  voteIconSelectedColor:
                                      tokenColors.soonVoteIconSelected,
                                  voteIconDisabledColor:
                                      tokenColors.soonVoteIconDisabled,
                                  titleStyle: tokenTextStyles.soonCardTitle,
                                  badgeStyle: tokenTextStyles.soonBadgeLabel,
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
    this.textStyle,
    this.contentColor = AppColors.textOnPrimary,
  });

  final String title;
  final double scale;
  final VoidCallback onBack;
  final TextStyle? textStyle;
  final Color contentColor;

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
                color: contentColor,
                size: 24 * scale,
              ),
            ),
            SizedBox(width: 12 * scale),
            Text(
              title,
              style: (textStyle ?? AppTypography.heading3SemiBold).copyWith(
                color: contentColor,
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

class _TabEmptyState extends ConsumerWidget {
  const _TabEmptyState({
    required this.scale,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.titleStyle,
    this.subtitleStyle,
    this.contentColor = AppColors.textOnPrimary,
  });

  final double scale;
  final IconData icon;
  final String title;
  final String subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final Color contentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenColors = AppTokenColors.of(ref);

    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokenColors.soonCardBackground,
          borderRadius: BorderRadius.circular(16 * scale),
          border: Border.all(color: tokenColors.soonCardBorder),
        ),
        child: Padding(
          padding: EdgeInsets.all(20 * scale),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: contentColor, size: 34 * scale),
              SizedBox(height: 12 * scale),
              Text(
                title,
                textAlign: TextAlign.center,
                style: (titleStyle ?? AppTypography.bodyMediumSemiBold)
                    .copyWith(color: contentColor, fontSize: 14 * scale),
              ),
              SizedBox(height: 6 * scale),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: (subtitleStyle ?? AppTypography.bodySmallMedium)
                    .copyWith(
                      color: contentColor.withValues(alpha: 0.72),
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
