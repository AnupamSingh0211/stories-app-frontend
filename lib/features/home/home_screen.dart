import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
import '../storytime/screens/episodes_screen.dart';

const String _supabaseAssetBase =
    'https://ozdvhjcumeujfxodiawc.supabase.co/storage/v1/object/public/app-assets/';
const double _figmaWidth = 390;
const double _homeHeroBannerWidth = 359;
const double _homeHeroBannerHeight = 202;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.childName, this.childAge});

  final String? childName;
  final int? childAge;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _bottomNavIndex = 0;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
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
    final favoriteStories = ref.watch(favoriteStoriesProvider);

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

                      if (_bottomNavIndex == 2) {
                        return _ComingSoonTab(
                          scale: scale,
                          onBack: () => setState(() => _bottomNavIndex = 0),
                        );
                      }

                      return SingleChildScrollView(
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
                            _HeroBanner(
                              banner: banner,
                              scale: scale,
                              width: heroWidth,
                              height: _homeHeroBannerHeight * scale,
                            ),
                            SizedBox(height: 22 * scale),
                            _SectionTitle('Top Picks for You', scale: scale),
                            SizedBox(height: 12 * scale),
                            _TwoColumnStoryGrid(
                              scale: scale,
                              stories: _topPickStories,
                              favoriteStoryIds: {
                                for (final story in favoriteStories) story.id,
                              },
                            ),
                            SizedBox(height: 22 * scale),
                            _SectionTitle('Made for You', scale: scale),
                            SizedBox(height: 12 * scale),
                            _TwoColumnStoryGrid(
                              scale: scale,
                              stories: _madeForYouStories,
                              favoriteStoryIds: {
                                for (final story in favoriteStories) story.id,
                              },
                            ),
                            if (contentState.hasError) ...[
                              SizedBox(height: 16 * scale),
                              Text(
                                'Stories could not be refreshed.',
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

  _HomeBannerData _resolveBanner(StorytimeContent? content) {
    final banner = content?.featuredBanners.firstOrNull;
    return _HomeBannerData(
      imageUrl:
          banner?.imageUrl ??
          '${_supabaseAssetBase}featured_banners/krishna ki sunheri subah.webp',
      title: 'Kanha Ki Sunheri Subah',
      subtitle: 'TONIGHT',
    );
  }

  void _openFavorites(BuildContext context) {
    _dismissSearchFocus();
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

  final List<StoryModel> stories;
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
                      episodeCount: 'Ep 3 of 7',
                      imageHeight: 184 * scale,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const EpisodesScreen(),
                        ),
                      ),
                      isFavorite: favoriteStoryIds.contains(story.id),
                      onFavoriteTap: () {
                        ref
                            .read(favoriteStoriesProvider.notifier)
                            .toggleStory(story);
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
          child: SizedBox(
            height: 56 * scale,
            child: Padding(
              padding: EdgeInsets.all(16 * scale),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onBack,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textOnPrimary,
                      size: 24 * scale,
                    ),
                  ),
                  SizedBox(width: 12 * scale),
                  Text(
                    'Coming Soon',
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
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            16 * scale,
            0,
            16 * scale,
            bottomPadding,
          ),
          sliver: SliverLayoutBuilder(
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
                            imageUrl: story.thumbnailUrl,
                            width: cardWidth,
                            scale: scale,
                            isLiked: _likedStoryIds.contains(story.id),
                            isDisliked: _dislikedStoryIds.contains(story.id),
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

String _storyThumbnailUrl(String fileName) {
  return Uri.encodeFull('${_supabaseAssetBase}story_thumbnails/$fileName');
}

final _topPickStories = [
  StoryModel(
    id: 'top-pick-shararati-krishna',
    title: 'Shararati Krishna ke karname',
    thumbnailUrl: _storyThumbnailUrl('Shararati krishna ke karname.webp'),
    category: 'Krishna Stories',
    durationMinutes: 3,
  ),
  StoryModel(
    id: 'top-pick-bal-ganesh',
    title: 'Bal Ganesh Aur Laddo',
    thumbnailUrl: _storyThumbnailUrl('Bal Ganesh aur laddu.webp'),
    category: 'Ganesh Stories',
    durationMinutes: 3,
  ),
];

final _madeForYouStories = [
  StoryModel(
    id: 'made-for-you-arjun',
    title: 'Veer Bal Arjun',
    thumbnailUrl: _storyThumbnailUrl('Veer Bal Arjun.webp'),
    category: 'Mahabharata',
    durationMinutes: 3,
  ),
  StoryModel(
    id: 'made-for-you-makhan',
    title: 'Krishna aur makhan',
    thumbnailUrl: _storyThumbnailUrl('krishna aur makhan.webp'),
    category: 'Krishna Stories',
    durationMinutes: 3,
  ),
  StoryModel(
    id: 'made-for-you-handi',
    title: 'Krishna aur handi',
    thumbnailUrl: _storyThumbnailUrl('krishna aur handi.webp'),
    category: 'Krishna Stories',
    durationMinutes: 3,
  ),
  StoryModel(
    id: 'made-for-you-ganesh-masti',
    title: 'Bal Ganesh ki Masti',
    thumbnailUrl: _storyThumbnailUrl('Bal Ganesh ki masti.webp'),
    category: 'Ganesh Stories',
    durationMinutes: 3,
  ),
];

final _comingSoonStories = [
  StoryModel(
    id: 'coming-soon-nanha-sapno',
    title: 'Nanha Sapno Ka Safar',
    thumbnailUrl: _storyThumbnailUrl('Frame_1.png'),
    category: 'Coming Soon',
    durationMinutes: 3,
  ),
  StoryModel(
    id: 'coming-soon-ghar-ki-pyari',
    title: 'Ghar Ki Pyari Kahani',
    thumbnailUrl: _storyThumbnailUrl('Frame_2.png'),
    category: 'Coming Soon',
    durationMinutes: 3,
  ),
  StoryModel(
    id: 'coming-soon-nadi-kinare',
    title: 'Nadi Kinare Ka Safar',
    thumbnailUrl: _storyThumbnailUrl('Frame_3.png'),
    category: 'Coming Soon',
    durationMinutes: 3,
  ),
  StoryModel(
    id: 'coming-soon-mitti-mahal',
    title: 'Mitti Ka Mahal',
    thumbnailUrl: _storyThumbnailUrl('Frame_4.png'),
    category: 'Coming Soon',
    durationMinutes: 3,
  ),
  StoryModel(
    id: 'coming-soon-ratri-kahani',
    title: 'Ratri Ki Pyari Kahani',
    thumbnailUrl: _storyThumbnailUrl('Frame_5.png'),
    category: 'Coming Soon',
    durationMinutes: 3,
  ),
  StoryModel(
    id: 'coming-soon-hansi-safar',
    title: 'Hansi Ka Jadui Safar',
    thumbnailUrl: _storyThumbnailUrl('Frame_6.png'),
    category: 'Coming Soon',
    durationMinutes: 3,
  ),
];
