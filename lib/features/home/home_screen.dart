import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/theme/app_border_radius.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_gradients.dart';
import '../../shared/theme/app_shadows.dart';
import '../../shared/widgets/pill_button.dart';
import '../auth/companion_notifier.dart';
import '../library/library_screen.dart';
import '../profile/profile_screen.dart';
import '../storytime/models/story_model.dart';
import '../storytime/providers/story_player_provider.dart';
import '../storytime/screens/story_player_screen.dart';
import '../storytime/screens/storytime_screen.dart';

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    required this.childName,
    required this.childAge,
    super.key,
  });

  final String childName;
  final int childAge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final storytimeContent = ref.watch(storytimeContentProvider);
    final companion = ref.watch(companionNotifierProvider);
    final stories = storytimeContent.valueOrNull?.sections
        .expand((section) => section.stories)
        .toList(growable: false);
    final featuredStory = stories?.isNotEmpty == true ? stories!.first : null;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: Stack(
          children: [
            const _NightGlow(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 114),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 132,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Header(childName: childName),
                          const SizedBox(height: 24),
                          _HeroStoryCard(
                            childName: childName,
                            age: childAge,
                            story: featuredStory,
                          ),
                          const SizedBox(height: 12),
                          _StoryTraits(colors: theme.colorScheme, theme: theme),
                          const SizedBox(height: 24),
                          _ContinueListeningCard(story: featuredStory),
                          const SizedBox(height: 12),
                          _LessonCard(category: featuredStory?.category),
                          const SizedBox(height: 12),
                          _CompanionCard(
                            name: companion?.displayName,
                            description: companion?.shortDescription,
                            imageUrl: companion?.imageUrl,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 18,
              child: _BottomNavigation(
                onStoriesTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const StorytimeScreen(),
                  ),
                ),
                onLibraryTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const LibraryScreen(),
                  ),
                ),
                onProfileTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => ProfileScreen(
                      fallbackChildName: childName,
                      fallbackChildAge: childAge,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NightGlow extends StatelessWidget {
  const _NightGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 58,
            right: 34,
            child: Icon(
              Icons.nightlight_round,
              color: AppColors.emotionalWarmthSoft.withValues(alpha: 0.88),
              size: 92,
            ),
          ),
          ...const [
            _Star(top: 44, left: 184, size: 3),
            _Star(top: 96, left: 318, size: 4),
            _Star(top: 152, left: 42, size: 3),
            _Star(top: 210, left: 282, size: 3),
          ],
          const Positioned(
            left: -76,
            top: 122,
            child: _GlowBall(
              size: 210,
              color: AppColors.accentPrimary,
              opacity: 0.13,
            ),
          ),
          const Positioned(
            right: -94,
            top: 282,
            child: _GlowBall(
              size: 250,
              color: AppColors.emotionalWarmth,
              opacity: 0.08,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBall extends StatelessWidget {
  const _GlowBall({
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
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({required this.top, required this.left, required this.size});

  final double top;
  final double left;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.emotionalWarmthSoft.withValues(alpha: 0.78),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.emotionalWarmthSoft.withValues(alpha: 0.48),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.childName});

  final String childName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting()}, $childName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.76),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Ready for tonight's\nbedtime story?",
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colors.onSurface,
                  fontSize: 28,
                  height: 1.16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Let's create a calm and magical\nstorytime for your little one.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.68),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        _BellButton(colors: colors),
      ],
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 42,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite08,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderMedium),
            ),
            child: Center(
              child: Icon(
                Icons.notifications_none_rounded,
                color: colors.onSurface,
                size: 23,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStoryCard extends StatelessWidget {
  const _HeroStoryCard({
    required this.childName,
    required this.age,
    this.story,
  });

  final String childName;
  final int age;
  final StoryModel? story;

  void _openStorytime(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const StorytimeScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: AppBorderRadius.panel,
        gradient: AppGradients.heroCard,
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [AppShadows.elevation2],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accentPrimary.withValues(alpha: 0.24),
              borderRadius: AppBorderRadius.card,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: colors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  "Tonight's Story",
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            story?.title ?? 'Choose a bedtime story',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colors.onSurface,
              fontSize: 23,
              height: 1.28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Personalized for $childName - Age $age',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.64),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: PillButton(
                  onTap: () => _openStorytime(context),
                  height: 56,
                  gradient: AppGradients.primaryButton,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.play_arrow_rounded,
                        color: AppColors.textOnAccent,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Storytime',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.textOnAccentSoft,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: PillButton(
                  onTap: null,
                  height: 56,
                  color: AppColors.surfaceWhite08,
                  border: Border.all(color: AppColors.borderMedium),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: colors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Surprise Me',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoryTraits extends StatelessWidget {
  const _StoryTraits({required this.colors, required this.theme});

  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.verified_user_outlined,
          color: colors.primary.withValues(alpha: 0.8),
          size: 14,
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            'Calm stories  -  Positive lessons  -  Sleep friendly',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _ContinueListeningCard extends ConsumerStatefulWidget {
  const _ContinueListeningCard({this.story});

  final StoryModel? story;

  @override
  ConsumerState<_ContinueListeningCard> createState() =>
      _ContinueListeningCardState();
}

class _ContinueListeningCardState
    extends ConsumerState<_ContinueListeningCard> {
  bool _hasOpenedStory = false;

  void _openStorytime(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const StorytimeScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _openStoryPlayer(BuildContext context) {
    final selectedStory = widget.story;
    if (selectedStory == null) {
      _openStorytime(context);
      return;
    }

    if (!_hasOpenedStory) {
      setState(() => _hasOpenedStory = true);
    }

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return StoryPlayerScreen(
            storyId: selectedStory.id,
            title: selectedStory.title,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final selectedStory = widget.story;
    final imageUrl =
        selectedStory?.coverUrl ??
        selectedStory?.imageUrl ??
        selectedStory?.thumbnailUrl;
    final playerPosition = selectedStory != null && _hasOpenedStory
        ? ref.watch(
            storyPlayerProvider(selectedStory.id).select(
              (state) => (
                pageIndex: state.currentPageIndex,
                pageCount: state.pageCount,
                isComplete: state.isComplete,
              ),
            ),
          )
        : null;
    final progress = playerPosition == null || playerPosition.pageCount == 0
        ? 0.0
        : playerPosition.isComplete
        ? 1.0
        : playerPosition.pageIndex / playerPosition.pageCount;

    return _HomePanel(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openStoryPlayer(context),
        child: Column(
          children: [
            _SectionTitle(
              icon: Icons.headphones_rounded,
              title: 'Continue Listening',
              trailing: 'View all',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      AppBorderRadius.radiusLg,
                    ),
                    gradient: AppGradients.storyCoverFallback,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AppBorderRadius.radiusLg,
                    ),
                    child: Stack(
                      children: [
                        if (imageUrl != null && imageUrl.isNotEmpty)
                          Positioned.fill(
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        Positioned(
                          right: 7,
                          bottom: 7,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _openStoryPlayer(context),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated.withValues(
                                  alpha: 0.92,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.borderStrong,
                                ),
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: AppColors.textPrimary,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedStory?.title ??
                            'Open Storytime to choose a tale',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: AppColors.borderMedium,
                          valueColor: AlwaysStoppedAnimation(colors.primary),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            selectedStory == null
                                ? 'No story selected'
                                : selectedStory.durationLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.58),
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            selectedStory?.category ?? 'Storytime',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.58),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({this.category});

  final String? category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _HomePanel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _SquareIcon(icon: Icons.spa_rounded, color: colors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tonight's Lesson",
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.58),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  category?.isNotEmpty == true ? category! : 'Bedtime Story',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.emotionalWarmthBright,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: colors.onSurface.withValues(alpha: 0.44),
          ),
        ],
      ),
    );
  }
}

class _CompanionCard extends StatelessWidget {
  const _CompanionCard({this.name, this.description, this.imageUrl});

  final String? name;
  final String? description;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _HomePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            icon: Icons.favorite_border_rounded,
            title: 'Your Companion',
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.companion,
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.18),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.auto_stories_rounded,
                              color: colors.primary,
                              size: 36,
                            );
                          },
                        )
                      : Icon(
                          Icons.auto_stories_rounded,
                          color: colors.primary,
                          size: 36,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            name ?? 'Choose Companion',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.emotionalWarmth.withValues(
                              alpha: 0.14,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.lock_outline_rounded,
                                color: AppColors.emotionalWarmth,
                                size: 11,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Locked',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.emotionalWarmth,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description ??
                          "Your little one's guide for all bedtime adventures",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.62),
                        fontSize: 12,
                        height: 1.42,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.onSurface.withValues(alpha: 0.44),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomePanel extends StatelessWidget {
  const _HomePanel({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withValues(alpha: 0.84),
        borderRadius: AppBorderRadius.card,
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title, this.trailing});

  final IconData icon;
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, color: colors.primary, size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        if (trailing != null) ...[
          Text(
            trailing!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.62),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: colors.onSurface.withValues(alpha: 0.52),
            size: 18,
          ),
        ],
      ],
    );
  }
}

class _SquareIcon extends StatelessWidget {
  const _SquareIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: Icon(icon, color: color, size: 28)),
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.onStoriesTap,
    required this.onLibraryTap,
    required this.onProfileTap,
  });

  final VoidCallback onStoriesTap;
  final VoidCallback onLibraryTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceNavigation.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [AppShadows.elevation3],
      ),
      child: Row(
        children: [
          const Expanded(
            child: _NavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              selected: true,
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.auto_stories_rounded,
              label: 'Stories',
              onTap: onStoriesTap,
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.menu_book_outlined,
              label: 'Library',
              onTap: onLibraryTap,
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.account_circle_outlined,
              label: 'Profile',
              onTap: onProfileTap,
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
    this.selected = false,
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
          Icon(icon, color: selected ? activeColor : inactiveColor, size: 25),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? colors.onSurface : inactiveColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
