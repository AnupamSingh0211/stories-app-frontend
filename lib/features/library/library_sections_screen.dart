import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/widgets/app_bottom_navigation.dart';
import '../auth/companion_notifier.dart';
import '../auth/companions_provider.dart';
import '../auth/profile_notifier.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../storytime/models/story_model.dart';
import '../storytime/providers/continue_listening_provider.dart';
import '../storytime/screens/story_player_screen.dart';
import '../storytime/widgets/story_image_view.dart';

const _favoritesEmptyAsset = 'assets/icons/favorites_empty.svg';
const _searchAsset = 'assets/icons/search_rounded.svg';
const _sparkAsset = 'assets/icons/actions/sparks.svg';
const _playAsset = 'assets/icons/player/play_small.svg';
const _downloadAsset = 'assets/icons/download_icon.svg';
const _storyTextColor = Color(0xFF001033);
const _emptyTitleColor = Color(0xFF29609B);
const _tabBorderColor = AppColors.gray400;

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

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider).valueOrNull;
    final selectedChild = profileState?.selectedChild;
    final childName = selectedChild?.childName ?? 'Svayudh';
    final companionUrl = _companionImageUrl(ref, selectedChild?.companionId);
    final history = ref.watch(sessionStoryHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.blue25,
      body: Stack(
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
    );
  }
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
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
