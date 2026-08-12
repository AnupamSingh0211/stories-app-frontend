import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/widgets/app_bottom_navigation.dart';
import '../../shared/widgets/app_screen_background.dart';
import '../auth/assets_provider.dart';
import '../auth/companion_notifier.dart';
import '../auth/companions_provider.dart';
import '../auth/profile_notifier.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../storytime/models/story_model.dart';
import '../storytime/providers/continue_listening_provider.dart';
import '../storytime/providers/favorite_stories_provider.dart';
import '../storytime/screens/episodes_screen.dart';
import '../storytime/screens/story_player_screen.dart';
import '../storytime/widgets/story_image_view.dart';

const _favoritesEmptyAsset =
    'assets/icons/new_boopi/State=Default, Icon=Heart.svg';
const _searchAsset = 'assets/icons/new_boopi/State=Default, Icon=Search.svg';
const _sparkAsset = 'assets/icons/new_boopi/State=Default, Icon=Sparkle.svg';
const _playAsset = 'assets/icons/new_boopi/State=Default, Icon=Play.svg';
const _downloadAsset =
    'assets/icons/new_boopi/State=Default, Icon=Download.svg';
const _storyTextColor = Color(0xFF001033);
const _emptyTitleColor = Color(0xFF29609B);
const _tabBorderColor = AppColors.gray400;
const _figmaWidth = 390.0;
const _favoriteMascotFallbackUrl =
    'https://ozdvhjcumeujfxodiawc.supabase.co/storage/v1/object/public/app-assets/backgrounds/mascot_character_favorites.png';

enum LibrarySection {
  favourites(
    label: 'My favourites',
    emptyTitle: 'No Favorites Yet',
    emptySubtitle: 'Start adding stories you love!',
    actionLabel: 'Explore',
    action: LibraryEmptyAction.explore,
  ),
  recents(
    label: 'Recents',
    emptyTitle: 'No Recent Stories',
    emptySubtitle: 'Start reading to see your history.',
    actionLabel: 'Start Listen',
    action: LibraryEmptyAction.listen,
  ),
  continueListening(
    label: 'Continue',
    emptyTitle: 'Nothing to Continue',
    emptySubtitle: 'Start a story and continue it anytime.',
    actionLabel: 'Start Listen',
    action: LibraryEmptyAction.listen,
  ),
  downloaded(
    label: 'Downloaded',
    emptyTitle: 'No Downloads Yet',
    emptySubtitle: 'Download stories to enjoy them offline.',
    actionLabel: 'Download',
    action: LibraryEmptyAction.download,
  );

  const LibrarySection({
    required this.label,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.actionLabel,
    required this.action,
  });

  final String label;
  final String emptyTitle;
  final String emptySubtitle;
  final String actionLabel;
  final LibraryEmptyAction action;
}

enum LibraryEmptyAction { explore, listen, download }

class LibrarySectionsScreen extends ConsumerStatefulWidget {
  const LibrarySectionsScreen({
    super.key,
    this.initialSection = LibrarySection.favourites,
  });

  final LibrarySection initialSection;

  @override
  ConsumerState<LibrarySectionsScreen> createState() =>
      _LibrarySectionsScreenState();
}

class _LibrarySectionsScreenState extends ConsumerState<LibrarySectionsScreen> {
  late LibrarySection _selectedSection = widget.initialSection;
  bool _showSearch = false;
  bool _didPrecacheFavoriteMascot = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheFavoriteMascot) {
      return;
    }

    _didPrecacheFavoriteMascot = true;
    final favoriteMascotUrl =
        ref.read(appAssetsProvider)['mascot_character_favorite'] ??
        _favoriteMascotFallbackUrl;
    unawaited(
      precacheImage(
        CachedNetworkImageProvider(favoriteMascotUrl),
        context,
      ).catchError((_) {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider).valueOrNull;
    final selectedChild = profileState?.selectedChild;
    final childName = selectedChild?.childName ?? 'Svayudh';
    final favoriteMascotUrl =
        ref.watch(appAssetsProvider)['mascot_character_favorite'] ??
        _favoriteMascotFallbackUrl;

    if (_selectedSection == LibrarySection.favourites) {
      final favoriteStories = ref.watch(favoriteStoriesProvider);
      final favoriteEpisodes = ref.watch(favoriteEpisodesProvider);
      if (favoriteStories.isNotEmpty || favoriteEpisodes.isNotEmpty) {
        return _FavouritesScreen(
          stories: favoriteStories,
          episodes: favoriteEpisodes,
        );
      }

      return _NoFavouritesScreen(
        childName: childName,
        childAge: selectedChild?.age,
        mascotUrl: favoriteMascotUrl,
      );
    }

    final companionUrl = _companionImageUrl(ref);
    final history = ref.watch(sessionStoryHistoryProvider);

    return Scaffold(
      body: AppScreenBackground(
        child: Stack(
          children: [
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _LibraryTopAppBar(
                      childName: childName,
                      avatarUrl: companionUrl,
                      searchVisible: _showSearch,
                      onProfileTap: () =>
                          _openProfile(context, childName, selectedChild?.age),
                      onSearchTap: () {
                        setState(() => _showSearch = !_showSearch);
                      },
                      onFavoritesTap: () {
                        setState(() {
                          _selectedSection = LibrarySection.favourites;
                        });
                      },
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _showSearch
                          ? const Padding(
                              key: ValueKey('search'),
                              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                              child: _LibrarySearchBar(),
                            )
                          : const SizedBox.shrink(key: ValueKey('empty')),
                    ),
                    _LibrarySectionTabs(
                      selectedSection: _selectedSection,
                      onSelected: (section) {
                        setState(() => _selectedSection = section);
                      },
                    ),
                    Expanded(
                      child: _LibrarySectionContent(
                        section: _selectedSection,
                        companionImageUrl: companionUrl,
                        history: history,
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
              child: AppPrimaryBottomNavigation(
                selectedIndex: 2,
                onItemSelected: (index) {
                  switch (index) {
                    case 0:
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute<void>(
                          builder: (context) => HomeScreen(
                            childName: childName,
                            childAge: selectedChild?.age,
                          ),
                        ),
                        (route) => false,
                      );
                      break;
                    case 1:
                    case 2:
                      break;
                    case 3:
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (context) => ProfileScreen(
                            fallbackChildName: childName,
                            fallbackChildAge: selectedChild?.age,
                          ),
                        ),
                      );
                      break;
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavouritesScreen extends ConsumerWidget {
  const _FavouritesScreen({required this.stories, required this.episodes});

  final List<StoryModel> stories;
  final List<StoryModel> episodes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MediaQuery.withNoTextScaling(
      child: Scaffold(
        body: AppScreenBackground(
          child: SizedBox.expand(
            child: SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final rawScale = constraints.maxWidth / _figmaWidth;
                  final scale = rawScale < 0.88 ? 0.88 : rawScale;
                  final sideInset = 16.0 * scale;
                  final itemGap = 16.0 * scale;
                  final sectionGap = 24.0 * scale;

                  return Stack(
                    children: [
                      const _FavouritesHeader(),
                      Positioned.fill(
                        top: 56 * scale,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            sideInset,
                            0,
                            sideInset,
                            0,
                          ),
                          child: CustomScrollView(
                            physics: const ClampingScrollPhysics(),
                            slivers: [
                              if (stories.isNotEmpty) ...[
                                SliverToBoxAdapter(
                                  child: _FavouritesSectionHeader(
                                    title: 'Your Favourites Stories',
                                    scale: scale,
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: SizedBox(height: 12 * scale),
                                ),
                                SliverGrid(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: itemGap,
                                        mainAxisSpacing: itemGap,
                                        mainAxisExtent: 253 * scale,
                                      ),
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final story = stories[index];
                                    return _FavouriteStoryCard(
                                      story: story,
                                      scale: scale,
                                      onFavoriteTap: () {
                                        ref
                                            .read(
                                              favoriteStoriesProvider.notifier,
                                            )
                                            .removeStory(story.id);
                                      },
                                    );
                                  }, childCount: stories.length),
                                ),
                              ],
                              if (stories.isNotEmpty && episodes.isNotEmpty)
                                SliverToBoxAdapter(
                                  child: SizedBox(height: sectionGap),
                                ),
                              if (episodes.isNotEmpty) ...[
                                SliverToBoxAdapter(
                                  child: _FavouritesSectionHeader(
                                    title: 'Your Favourites Episodes',
                                    scale: scale,
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: SizedBox(height: 12 * scale),
                                ),
                                SliverGrid(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: itemGap,
                                        mainAxisSpacing: itemGap,
                                        mainAxisExtent: 253 * scale,
                                      ),
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final episode = episodes[index];
                                    return _FavouriteStoryCard(
                                      story: episode,
                                      scale: scale,
                                      opensDirectly: true,
                                      onFavoriteTap: () {
                                        ref
                                            .read(
                                              favoriteEpisodesProvider.notifier,
                                            )
                                            .removeEpisode(episode.id);
                                      },
                                    );
                                  }, childCount: episodes.length),
                                ),
                              ],
                              SliverToBoxAdapter(
                                child: SizedBox(height: 24 * scale),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FavouritesSectionHeader extends StatelessWidget {
  const _FavouritesSectionHeader({required this.title, required this.scale});

  final String title;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20 * scale,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _FavouritesTextStyles.sectionTitle.copyWith(
                fontSize: 16 * scale,
              ),
            ),
          ),
          SizedBox(width: 12 * scale),
          Text(
            'See all',
            style: _FavouritesTextStyles.seeAll.copyWith(fontSize: 14 * scale),
          ),
        ],
      ),
    );
  }
}

class _FavouritesHeader extends StatelessWidget {
  const _FavouritesHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 24,
              child: InkResponse(
                onTap: () => Navigator.of(context).maybePop(),
                radius: 24,
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textOnPrimary,
                  size: 24,
                  applyTextScaling: false,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Favourites', style: _FavouritesTextStyles.headerTitle),
          ],
        ),
      ),
    );
  }
}

class _FavouriteStoryCard extends StatelessWidget {
  const _FavouriteStoryCard({
    required this.story,
    required this.scale,
    required this.onFavoriteTap,
    this.opensDirectly = false,
  });

  final StoryModel story;
  final double scale;
  final VoidCallback onFavoriteTap;
  final bool opensDirectly;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openFavouriteItem(context),
      child: Container(
        padding: EdgeInsets.all(12 * scale),
        decoration: BoxDecoration(
          color: AppColors.backgroundGlass,
          borderRadius: BorderRadius.circular(8 * scale),
          border: Border.all(color: AppColors.borderLight, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              offset: const Offset(0, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FavouriteStoryImage(
              story: story,
              scale: scale,
              onFavoriteTap: onFavoriteTap,
            ),
            SizedBox(height: 8 * scale),
            Expanded(
              child: Text(
                story.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _FavouritesTextStyles.cardTitle.copyWith(
                  fontSize: 14 * scale,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFavouriteItem(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          if (!opensDirectly) {
            return const EpisodesScreen();
          }

          return StoryPlayerScreen(
            storyId: story.id,
            title: story.title,
            story: story,
            openDirectly: true,
            playerImageUrl:
                story.coverUrl ?? story.imageUrl ?? story.thumbnailUrl,
          );
        },
      ),
    );
  }
}

class _FavouriteStoryImage extends StatelessWidget {
  const _FavouriteStoryImage({
    required this.story,
    required this.scale,
    required this.onFavoriteTap,
  });

  final StoryModel story;
  final double scale;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 147 * scale,
      height: 181 * scale,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4 * scale),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              story.thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const ColoredBox(color: AppColors.backgroundGlass),
            ),
            Positioned(
              top: 8 * scale,
              right: 8 * scale,
              child: _FavouriteHeartButton(scale: scale, onTap: onFavoriteTap),
            ),
            Positioned(
              right: 8 * scale,
              bottom: 8 * scale,
              child: const _EpisodeBadge(label: 'Ep 3 of 7'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavouriteHeartButton extends StatelessWidget {
  const _FavouriteHeartButton({required this.scale, required this.onTap});

  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Remove from favorites',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 28 * scale,
          height: 28 * scale,
          padding: EdgeInsets.all(6.36 * scale),
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            shape: BoxShape.circle,
          ),
          child: SvgPicture.asset(
            'assets/icons/new_boopi/State=Bold, Icon=Heart.svg',
            colorFilter: const ColorFilter.mode(
              AppColors.textOnPrimary,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}

class _EpisodeBadge extends StatelessWidget {
  const _EpisodeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.glassShadow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: _FavouritesTextStyles.episode),
    );
  }
}

abstract final class _FavouritesTextStyles {
  static const headerTitle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 20,
    height: 24 / 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );

  static const sectionTitle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 16,
    height: 20 / 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
  );

  static const seeAll = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textOnPrimary,
  );

  static const cardTitle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );

  static const episode = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 10,
    height: 12 / 10,
    letterSpacing: 1,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
  );
}

class _NoFavouritesScreen extends StatelessWidget {
  const _NoFavouritesScreen({
    required this.childName,
    required this.childAge,
    required this.mascotUrl,
  });

  final String childName;
  final int? childAge;
  final String mascotUrl;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withNoTextScaling(
      child: Scaffold(
        body: AppScreenBackground(
          child: SizedBox.expand(
            child: SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scale = (constraints.maxWidth / _figmaWidth)
                      .clamp(0.88, 1.18)
                      .toDouble();
                  final horizontal = 16.0 * scale;

                  return Stack(
                    children: [
                      const _NoFavouritesHeader(),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 163 * scale,
                        child: _NoFavouritesContent(
                          mascotUrl: mascotUrl,
                          scale: scale,
                        ),
                      ),
                      Positioned(
                        left: horizontal,
                        right: horizontal,
                        bottom: 38 * scale,
                        child: _ExploreStoriesButton(
                          onTap: () => _openHome(context),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (context) =>
            HomeScreen(childName: childName, childAge: childAge),
      ),
      (route) => false,
    );
  }
}

class _NoFavouritesHeader extends StatelessWidget {
  const _NoFavouritesHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 24,
              child: InkResponse(
                onTap: () => Navigator.of(context).maybePop(),
                radius: 24,
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textOnPrimary,
                  size: 24,
                  applyTextScaling: false,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Favourites',
              style: _NoFavouritesTextStyles.headerTitle,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoFavouritesContent extends StatelessWidget {
  const _NoFavouritesContent({required this.mascotUrl, required this.scale});

  final String mascotUrl;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 179 * scale,
          height: 221 * scale,
          child: CachedNetworkImage(
            imageUrl: mascotUrl,
            fit: BoxFit.contain,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholder: (context, url) => const _FavoriteMascotFallback(),
            errorWidget: (context, url, error) =>
                const _FavoriteMascotFallback(),
          ),
        ),
        SizedBox(height: 16 * scale),
        SizedBox(
          width: 341 * scale,
          child: Column(
            children: [
              const Text(
                'No Favourites Yet',
                textAlign: TextAlign.center,
                style: _NoFavouritesTextStyles.title,
              ),
              const SizedBox(height: 0),
              Text(
                'Save the stories you love and find them\nhere anytime.',
                textAlign: TextAlign.center,
                style: _NoFavouritesTextStyles.subtitle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FavoriteMascotFallback extends StatelessWidget {
  const _FavoriteMascotFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.backgroundGlass,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: const Center(
        child: Icon(
          Icons.favorite_border_rounded,
          color: AppColors.textOnPrimary,
          size: 56,
        ),
      ),
    );
  }
}

class _ExploreStoriesButton extends StatelessWidget {
  const _ExploreStoriesButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Explore Stories',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.backgroundGlass,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderLight, width: 0.8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2E000000),
                offset: Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Text(
            'Explore Stories',
            style: _NoFavouritesTextStyles.button,
          ),
        ),
      ),
    );
  }
}

abstract final class _NoFavouritesTextStyles {
  static const headerTitle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 20,
    height: 24 / 20,
    letterSpacing: -0.25,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );

  static const title = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 20,
    height: 24 / 20,
    letterSpacing: -0.25,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
  );

  static const subtitle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    color: Color(0xD9FFFFFF),
  );

  static const button = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 16,
    height: 20 / 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
  );
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
}

String? _companionImageUrl(WidgetRef ref) {
  final selectedCompanion = ref.watch(companionNotifierProvider);
  return selectedCompanion?.imageUrl ??
      ref.watch(companionsProvider).valueOrNull?.firstOrNull?.imageUrl;
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

class _LibraryTopAppBar extends StatelessWidget {
  const _LibraryTopAppBar({
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

class _LibrarySearchBar extends StatelessWidget {
  const _LibrarySearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _LibrarySectionTabs extends StatelessWidget {
  const _LibrarySectionTabs({
    required this.selectedSection,
    required this.onSelected,
  });

  final LibrarySection selectedSection;
  final ValueChanged<LibrarySection> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 17),
        child: Row(
          children: [
            for (final section in LibrarySection.values) ...[
              _LibrarySectionPill(
                section: section,
                selected: section == selectedSection,
                onTap: () => onSelected(section),
              ),
              if (section != LibrarySection.values.last)
                const SizedBox(width: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _LibrarySectionPill extends StatelessWidget {
  const _LibrarySectionPill({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final LibrarySection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: section.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.blue500 : AppColors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: selected ? null : Border.all(color: _tabBorderColor),
          ),
          child: Text(
            section.label,
            textScaler: TextScaler.noScaling,
            maxLines: 1,
            style: AppTypography.bodySmallSemiBold.copyWith(
              color: selected ? AppColors.blue25 : _tabBorderColor,
              height: 16 / 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryEmptyState extends StatelessWidget {
  const _LibraryEmptyState({
    required this.section,
    required this.companionImageUrl,
  });

  final LibrarySection section;
  final String? companionImageUrl;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final topSpacing = availableHeight < 560 ? 24.0 : 33.0;
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20, topSpacing, 20, 104),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (availableHeight - topSpacing - 104).clamp(
                0,
                double.infinity,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _EmptyCompanionImage(imageUrl: companionImageUrl),
                const SizedBox(height: 14.67),
                Text(
                  section.emptyTitle,
                  textAlign: TextAlign.center,
                  textScaler: TextScaler.noScaling,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.heading3Bold.copyWith(
                    color: _emptyTitleColor,
                    fontSize: 20,
                    height: 24 / 20,
                    letterSpacing: -0.25,
                  ),
                ),
                Text(
                  section.emptySubtitle,
                  textAlign: TextAlign.center,
                  textScaler: TextScaler.noScaling,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMediumMedium.copyWith(
                    color: AppColors.gray500,
                    height: 20 / 14,
                  ),
                ),
                const SizedBox(height: 19),
                _EmptyActionButton(section: section),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LibrarySectionContent extends StatelessWidget {
  const _LibrarySectionContent({
    required this.section,
    required this.companionImageUrl,
    required this.history,
  });

  final LibrarySection section;
  final String? companionImageUrl;
  final SessionStoryHistoryState history;

  @override
  Widget build(BuildContext context) {
    if (section != LibrarySection.recents &&
        section != LibrarySection.continueListening) {
      return _LibraryEmptyState(
        section: section,
        companionImageUrl: companionImageUrl,
      );
    }

    if (history.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.blue500,
        ),
      );
    }

    if (history.errorMessage case final message?) {
      return _HistoryErrorState(message: message);
    }

    if (section == LibrarySection.recents) {
      if (history.recents.isEmpty) {
        return _LibraryEmptyState(
          section: section,
          companionImageUrl: companionImageUrl,
        );
      }

      return _HistoryStoryList(
        entries: [
          for (final recent in history.recents)
            _HistoryCardData(story: recent.story),
        ],
      );
    }

    final continueEntry = history.continueListening;
    if (continueEntry == null) {
      return _LibraryEmptyState(
        section: section,
        companionImageUrl: companionImageUrl,
      );
    }

    return _HistoryStoryList(
      entries: [
        _HistoryCardData(
          story: continueEntry.story,
          progress: continueEntry.progress,
        ),
      ],
    );
  }
}

class _HistoryCardData {
  const _HistoryCardData({required this.story, this.progress});

  final StoryModel story;
  final double? progress;
}

class _HistoryStoryList extends StatelessWidget {
  const _HistoryStoryList({required this.entries});

  final List<_HistoryCardData> entries;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 112),
      itemCount: entries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _HistoryStoryCard(story: entry.story, progress: entry.progress);
      },
    );
  }
}

class _HistoryStoryCard extends StatelessWidget {
  const _HistoryStoryCard({required this.story, this.progress});

  final StoryModel story;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: progress == null
          ? 'Play ${story.title}'
          : 'Continue ${story.title}',
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => StoryPlayerScreen(
              storyId: story.id,
              title: story.title,
              story: story,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.gray100),
            boxShadow: [
              BoxShadow(
                color: AppColors.surfaceBlack.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: StoryImageView(imageUrl: story.thumbnailUrl),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyLargeBold.copyWith(
                        color: _storyTextColor,
                        height: 20 / 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${story.category} • ${story.durationLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmallSemiBold.copyWith(
                        color: AppColors.gray500,
                        height: 16 / 12,
                      ),
                    ),
                    if (progress case final value?) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: value.clamp(0, 1),
                          minHeight: 5,
                          backgroundColor: AppColors.gray100,
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.blue500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.play_circle_fill_rounded,
                color: AppColors.blue500,
                size: 34,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryErrorState extends StatelessWidget {
  const _HistoryErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 112),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history_toggle_off_rounded,
              color: AppColors.gray400,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMediumSemiBold.copyWith(
                color: AppColors.gray600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCompanionImage extends StatelessWidget {
  const _EmptyCompanionImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final image = imageUrl != null && imageUrl!.isNotEmpty
        ? Image.network(
            imageUrl!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const _EmptyCompanionFallback(),
          )
        : const _EmptyCompanionFallback();

    return SizedBox(width: 118, height: 176.33, child: image);
  }
}

class _EmptyCompanionFallback extends StatelessWidget {
  const _EmptyCompanionFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.blue50,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Center(
        child: Icon(
          Icons.auto_stories_rounded,
          color: AppColors.blue500,
          size: 54,
        ),
      ),
    );
  }
}

class _EmptyActionButton extends StatelessWidget {
  const _EmptyActionButton({required this.section});

  final LibrarySection section;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: section.actionLabel,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          color: AppColors.blue500,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionIcon(action: section.action),
            const SizedBox(width: 8),
            Text(
              section.actionLabel,
              textScaler: TextScaler.noScaling,
              maxLines: 1,
              style: AppTypography.bodyLargeBold.copyWith(
                color: AppColors.surfaceWhite,
                height: 20 / 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.action});

  final LibraryEmptyAction action;

  @override
  Widget build(BuildContext context) {
    switch (action) {
      case LibraryEmptyAction.explore:
        return SvgPicture.asset(
          _sparkAsset,
          width: 16,
          height: 16,
          colorFilter: const ColorFilter.mode(
            AppColors.surfaceWhite,
            BlendMode.srcIn,
          ),
        );
      case LibraryEmptyAction.listen:
        return SvgPicture.asset(_playAsset, width: 16, height: 16);
      case LibraryEmptyAction.download:
        return SvgPicture.asset(_downloadAsset, width: 16, height: 16);
    }
  }
}
