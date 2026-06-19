import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/theme/app_border_radius.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_gradients.dart';
import '../../shared/theme/app_shadows.dart';
import '../../shared/layout/responsive_layout.dart';
import '../../shared/widgets/pill_button.dart';
import '../auth/assets_provider.dart';
import '../auth/companions_provider.dart';
import '../auth/companion_notifier.dart';
import '../auth/profile_notifier.dart';
import '../library/library_screen.dart';
import '../profile/profile_screen.dart';
import '../storytime/models/story_model.dart';
import '../storytime/providers/continue_listening_provider.dart';
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
  const HomeScreen({this.childName, this.childAge, super.key});

  final String? childName;
  final int? childAge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appAssets = ref.watch(appAssetsProvider);
    final backgroundImageUrl = appAssets['home_screen_story'];
    final storyCardImageUrl = appAssets['home_screen_story_portrait'];
    final storytimeContent = ref.watch(storytimeContentProvider);
    final childProfiles = ref.watch(profileNotifierProvider);
    final selectedChild = childProfiles.valueOrNull?.selectedChild;
    final effectiveChildName =
        selectedChild?.childName ?? childName ?? 'Little Dreamer';
    final effectiveChildAge = selectedChild?.age ?? childAge ?? 2;
    final selectedCompanion = ref.watch(companionNotifierProvider);
    final companions = ref.watch(companionsProvider).valueOrNull;
    final companionId = selectedChild?.companionId;
    final companion = selectedChild == null
        ? selectedCompanion
        : companions?.where((item) => item.id == companionId).firstOrNull;
    final stories = storytimeContent.valueOrNull?.sections
        .expand((section) => section.stories)
        .toList(growable: false);
    final featuredStory = stories?.isNotEmpty == true ? stories!.first : null;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: Stack(
          children: [
            if (backgroundImageUrl != null)
              _HomeBackground(imageUrl: backgroundImageUrl),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = pageHorizontalPadding(context);
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      18,
                      horizontalPadding,
                      floatingNavigationScrollPadding(context),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            constraints.maxHeight -
                            floatingNavigationScrollPadding(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Header(childName: effectiveChildName),
                          const SizedBox(height: 24),
                          _HeroStoryCard(
                            childName: effectiveChildName,
                            age: effectiveChildAge,
                            story: featuredStory,
                            backgroundImageUrl: storyCardImageUrl,
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
              left: pageHorizontalPadding(context),
              right: pageHorizontalPadding(context),
              bottom: floatingNavigationBottom(context),
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
                      fallbackChildName: effectiveChildName,
                      fallbackChildAge: effectiveChildAge,
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

class _HomeBackground extends StatelessWidget {
  const _HomeBackground({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                opacity: const AlwaysStoppedAnimation(0.35),
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.surfaceDark.withValues(alpha: 0.12),
                      AppColors.surfaceDark.withValues(alpha: 0.46),
                      AppColors.surfaceDark.withValues(alpha: 0.78),
                    ],
                    stops: const [0, 0.48, 1],
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

class _Header extends StatelessWidget {
  const _Header({required this.childName});

  final String childName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final titleSize = responsiveValue(width: width, compact: 25, regular: 28);

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
                "Ready for tonight's bedtime story?",
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colors.onSurface,
                  fontSize: titleSize,
                  height: 1.16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Let's create a calm and magical storytime for your little one.",
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
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
    this.backgroundImageUrl,
  });

  final String childName;
  final int age;
  final StoryModel? story;
  final String? backgroundImageUrl;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackButtons = constraints.maxWidth < 340;
        final cardPadding = constraints.maxWidth < 340 ? 16.0 : 20.0;

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppBorderRadius.panel,
            boxShadow: const [AppShadows.elevation2],
          ),
          child: ClipRRect(
            borderRadius: AppBorderRadius.panel,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppGradients.heroCard,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Stack(
                children: [
                  if (backgroundImageUrl != null &&
                      backgroundImageUrl!.isNotEmpty)
                    Positioned.fill(
                      child: Image.network(
                        backgroundImageUrl!,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        opacity: const AlwaysStoppedAnimation(0.78),
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppColors.surfaceCard.withValues(alpha: 0.72),
                            AppColors.surfaceCard.withValues(alpha: 0.5),
                            AppColors.surfaceCard.withValues(alpha: 0.28),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentPrimary.withValues(
                              alpha: 0.24,
                            ),
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
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colors.onSurface,
                            fontSize: constraints.maxWidth < 340 ? 21 : 23,
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
                        _HeroActions(
                          stackButtons: stackButtons,
                          colors: colors,
                          theme: theme,
                          onStorytimeTap: () => _openStorytime(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroActions extends StatelessWidget {
  const _HeroActions({
    required this.stackButtons,
    required this.colors,
    required this.theme,
    required this.onStorytimeTap,
  });

  final bool stackButtons;
  final ColorScheme colors;
  final ThemeData theme;
  final VoidCallback onStorytimeTap;

  @override
  Widget build(BuildContext context) {
    final primary = _HeroActionButton(
      onTap: onStorytimeTap,
      gradient: AppGradients.primaryButton,
      icon: const Icon(
        Icons.play_arrow_rounded,
        color: AppColors.textOnAccent,
        size: 28,
      ),
      label: 'Storytime',
      textColor: AppColors.textOnAccentSoft,
      theme: theme,
    );
    final secondary = _HeroActionButton(
      onTap: null,
      color: AppColors.surfaceWhite08,
      border: Border.all(color: AppColors.borderMedium),
      icon: Icon(Icons.auto_awesome_rounded, color: colors.primary, size: 18),
      label: 'Surprise Me',
      textColor: colors.onSurface.withValues(alpha: 0.8),
      theme: theme,
    );

    if (stackButtons) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [primary, const SizedBox(height: 10), secondary],
      );
    }

    return Row(
      children: [
        Expanded(child: primary),
        const SizedBox(width: 14),
        Expanded(child: secondary),
      ],
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.textColor,
    required this.theme,
    this.gradient,
    this.color,
    this.border,
  });

  final VoidCallback? onTap;
  final Widget icon;
  final String label;
  final Color textColor;
  final ThemeData theme;
  final Gradient? gradient;
  final Color? color;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    return PillButton(
      onTap: onTap,
      height: 56,
      gradient: gradient,
      color: color,
      border: border,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
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

class _ContinueListeningCard extends ConsumerWidget {
  const _ContinueListeningCard({this.story});

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

  void _openStoryPlayer(BuildContext context, StoryModel? selectedStory) {
    if (selectedStory == null) {
      _openStorytime(context);
      return;
    }

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return StoryPlayerScreen(
            storyId: selectedStory.id,
            title: selectedStory.title,
            story: selectedStory,
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final continueEntry = ref.watch(continueListeningProvider);
    final selectedStory = continueEntry?.story ?? story;
    final imageUrl =
        selectedStory?.coverUrl ??
        selectedStory?.imageUrl ??
        selectedStory?.thumbnailUrl;
    final progress = continueEntry?.progress ?? 0.0;

    return _HomePanel(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openStoryPlayer(context, selectedStory),
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
                            onTap: () =>
                                _openStoryPlayer(context, selectedStory),
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
                          Flexible(
                            child: Text(
                              selectedStory == null
                                  ? 'No story selected'
                                  : selectedStory.durationLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.onSurface.withValues(alpha: 0.58),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              selectedStory?.category ?? 'Storytime',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.onSurface.withValues(alpha: 0.58),
                                fontSize: 12,
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
