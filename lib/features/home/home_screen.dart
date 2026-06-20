import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/widgets/app_bottom_navigation.dart';
import '../../shared/widgets/app_player_control_icon.dart';
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

const _notificationAsset = 'assets/icons/notifications/circle_notification.svg';

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
    final appAssets = ref.watch(appAssetsProvider);
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
    final heroImageUrl =
        featuredStory?.coverUrl ??
        featuredStory?.imageUrl ??
        featuredStory?.thumbnailUrl ??
        storyCardImageUrl;

    return Scaffold(
      backgroundColor: AppColors.blue25,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(
                        childName: effectiveChildName,
                        avatarImageUrl: companion?.imageUrl,
                      ),
                      const SizedBox(height: 28),
                      _IntroCopy(),
                      const SizedBox(height: 28),
                      _HeroStoryCard(
                        story: featuredStory,
                        backgroundImageUrl: heroImageUrl,
                        childName: effectiveChildName,
                        age: effectiveChildAge,
                      ),
                      const SizedBox(height: 17),
                      const _StoryTraits(),
                      const SizedBox(height: 28),
                      _ContinueListeningCard(story: featuredStory),
                      const SizedBox(height: 32),
                      _LessonCard(category: featuredStory?.category),
                      const SizedBox(height: 32),
                      _CompanionSection(
                        imageUrl: companion?.imageUrl,
                        description: companion?.shortDescription,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AppPrimaryBottomNavigation(
                selectedIndex: 0,
                onItemSelected: (index) {
                  switch (index) {
                    case 1:
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const StorytimeScreen(),
                        ),
                      );
                    case 2:
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const LibraryScreen(),
                        ),
                      );
                    case 3:
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => ProfileScreen(
                            fallbackChildName: effectiveChildName,
                            fallbackChildAge: effectiveChildAge,
                          ),
                        ),
                      );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.childName, this.avatarImageUrl});

  final String childName;
  final String? avatarImageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          _Avatar(imageUrl: avatarImageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()},',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyLargeRegular.copyWith(
                    color: AppColors.gray600,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  childName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.heading3Bold.copyWith(
                    color: AppColors.gray900,
                    fontSize: 20,
                    height: 24 / 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const _CircleNotificationButton(),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.blue500, width: 2.8),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.auto_stories_rounded,
                    color: AppColors.blue500,
                    size: 24,
                  );
                },
              )
            : const Icon(
                Icons.auto_stories_rounded,
                color: AppColors.blue500,
                size: 24,
              ),
      ),
    );
  }
}

class _CircleNotificationButton extends StatelessWidget {
  const _CircleNotificationButton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Notifications',
      child: InkResponse(
        onTap: () {},
        radius: 28,
        child: SizedBox(
          width: 48,
          height: 48,
          child: SvgPicture.asset(
            _notificationAsset,
            width: 48,
            height: 48,
            semanticsLabel: 'Notifications',
          ),
        ),
      ),
    );
  }
}

class _IntroCopy extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Ready for tonight's\nbedtime story?",
          style: AppTypography.heading2Bold.copyWith(
            color: AppColors.gray900,
            height: 32 / 28,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Let's create a calm and magical storytime for\nyour little one.",
          style: AppTypography.bodyLargeRegular.copyWith(
            color: AppColors.gray600,
            height: 20 / 16,
          ),
        ),
      ],
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
    return Container(
      height: 218.5,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray50),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (backgroundImageUrl != null && backgroundImageUrl!.isNotEmpty)
            Image.network(
              backgroundImageUrl!,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                return const ColoredBox(color: AppColors.blue200);
              },
            )
          else
            const ColoredBox(color: AppColors.blue200),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.surfaceBlack.withValues(alpha: 0.1),
                  AppColors.surfaceBlack.withValues(alpha: 0.08),
                  AppColors.surfaceBlack.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
          Positioned(
            left: 25,
            top: 25,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gray800.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.surfaceWhite,
                    size: 16.5,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "TONIGHT'S STORY",
                    style: AppTypography.bodySmallBold.copyWith(
                      color: AppColors.surfaceWhite,
                      height: 16 / 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 25,
            right: 25,
            top: 65.5,
            child: Text(
              story?.title ?? 'Choose a bedtime story',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.heading3Bold.copyWith(
                color: AppColors.surfaceWhite,
                height: 32 / 24,
                letterSpacing: 0,
              ),
            ),
          ),
          Positioned(
            left: 25,
            right: 25,
            bottom: 25,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stackButtons = constraints.maxWidth < 304;
                final storyButton = _HeroStoryButton.primary(
                  label: 'Story Time',
                  onPressed: () => _openStorytime(context),
                  icon: const _HeroPlayIcon(),
                );
                final surpriseButton = _HeroStoryButton.secondary(
                  label: 'Surprise Me',
                  onPressed: () {},
                  icon: SvgPicture.asset(
                    'assets/icons/actions/sparks.svg',
                    width: 21,
                    height: 20,
                    semanticsLabel: 'Surprise',
                  ),
                );

                if (stackButtons) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      storyButton,
                      const SizedBox(height: 10),
                      surpriseButton,
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    storyButton,
                    const SizedBox(width: 12),
                    surpriseButton,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStoryButton extends StatelessWidget {
  const _HeroStoryButton.primary({
    required this.label,
    required this.icon,
    required this.onPressed,
  }) : secondary = false;

  const _HeroStoryButton.secondary({
    required this.label,
    required this.icon,
    required this.onPressed,
  }) : secondary = true;

  final String label;
  final Widget icon;
  final VoidCallback onPressed;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = secondary
        ? AppColors.blue500
        : AppColors.surfaceWhite;

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          width: 146,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: secondary ? AppColors.surfaceWhite : AppColors.blue500,
            borderRadius: BorderRadius.circular(9999),
            border: secondary
                ? Border.all(color: AppColors.blue500, width: 2)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: AppTypography.bodyLargeBold.copyWith(
                  color: foregroundColor,
                  height: 20 / 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPlayIcon extends StatelessWidget {
  const _HeroPlayIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 11,
      height: 14,
      child: OverflowBox(
        maxWidth: 24,
        maxHeight: 24,
        child: SvgPicture.asset(
          'assets/icons/player/play_small.svg',
          width: 24,
          height: 24,
          semanticsLabel: 'Play',
        ),
      ),
    );
  }
}

class _StoryTraits extends StatelessWidget {
  const _StoryTraits();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.verified_user_outlined,
          color: AppColors.gray600,
          size: 13,
        ),
        const SizedBox(width: 6),
        _TraitText('CALM STORIES'),
        const _TraitDot(),
        _TraitText('POSITIVE LESSONS'),
        const _TraitDot(),
        _TraitText('SLEEP FRIENDLY'),
      ],
    );
  }
}

class _TraitText extends StatelessWidget {
  const _TraitText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.captionBold.copyWith(
          color: AppColors.gray900.withValues(alpha: 0.6),
          height: 12 / 10,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _TraitDot extends StatelessWidget {
  const _TraitDot();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '•',
        style: AppTypography.captionBold.copyWith(
          color: AppColors.gray400.withValues(alpha: 0.4),
          height: 12 / 10,
        ),
      ),
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
    final continueEntry = ref.watch(continueListeningProvider);
    final selectedStory = continueEntry?.story ?? story;
    final imageUrl =
        selectedStory?.coverUrl ??
        selectedStory?.imageUrl ??
        selectedStory?.thumbnailUrl;
    final progress = continueEntry?.progress ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          icon: Icons.headphones_rounded,
          title: 'Continue Listening',
          trailing: 'View all',
          onTrailingTap: () => _openStorytime(context),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openStoryPlayer(context, selectedStory),
          child: Container(
            height: 130,
            padding: const EdgeInsets.all(17),
            decoration: _cardDecoration(radius: 16, shadow: true),
            child: Row(
              children: [
                _StoryThumbnail(
                  imageUrl: imageUrl,
                  onTap: () => _openStoryPlayer(context, selectedStory),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedStory?.title ??
                            'Open Storytime to choose a tale',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyLargeBold.copyWith(
                          color: AppColors.gray900,
                          height: 24 / 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedStory?.category.toUpperCase() ?? 'STORYTIME',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmallBold.copyWith(
                          color: AppColors.gray600,
                          height: 16 / 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress.clamp(0, 1),
                                minHeight: 6,
                                backgroundColor: AppColors.gray100,
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.blue500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            selectedStory?.durationLabel ?? '',
                            style: AppTypography.captionBold.copyWith(
                              color: AppColors.gray600,
                              height: 15 / 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StoryThumbnail extends StatelessWidget {
  const _StoryThumbnail({required this.onTap, this.imageUrl});

  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.blue200,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: AppColors.surfaceBlack.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null && imageUrl!.isNotEmpty)
            Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.shrink();
              },
            ),
          Center(
            child: GestureDetector(
              onTap: onTap,
              child: const AppPlayerControlIcon(
                type: AppPlayerControlIconType.play,
                semanticLabel: 'Play story',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({this.category});

  final String? category;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.fromLTRB(22, 15, 14, 15),
      decoration: _cardDecoration(radius: 16, shadow: false),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.fuchsia50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_florist_rounded,
              color: AppColors.fuchsia500,
              size: 27,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TONIGHT'S LESSON",
                  style: AppTypography.captionBold.copyWith(
                    color: AppColors.gray600,
                    height: 12 / 10,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category?.isNotEmpty == true ? category! : 'Bedtime Story',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyLargeBold.copyWith(
                    color: AppColors.fuchsia500,
                    height: 20 / 16,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.gray600,
            size: 28,
          ),
        ],
      ),
    );
  }
}

class _CompanionSection extends StatelessWidget {
  const _CompanionSection({this.imageUrl, this.description});

  final String? imageUrl;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
          icon: Icons.favorite_border_rounded,
          title: 'Your Companion',
        ),
        const SizedBox(height: 21),
        Container(
          constraints: const BoxConstraints(minHeight: 132),
          padding: const EdgeInsets.fromLTRB(21, 21, 14, 21),
          decoration: _cardDecoration(radius: 16, shadow: false),
          child: Row(
            children: [
              _CompanionAvatar(imageUrl: imageUrl),
              const SizedBox(width: 21),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Choose\nCompanion',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyLargeBold.copyWith(
                              color: AppColors.gray900,
                              height: 20 / 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.fuchsia500,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lock_outline_rounded,
                                color: AppColors.surfaceWhite,
                                size: 13,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'LOCKED',
                                style: AppTypography.captionBold.copyWith(
                                  color: AppColors.surfaceWhite,
                                  height: 12 / 10,
                                  letterSpacing: 1,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMediumRegular.copyWith(
                        color: AppColors.gray600,
                        height: 20 / 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.gray600,
                size: 28,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompanionAvatar extends StatelessWidget {
  const _CompanionAvatar({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.blue50,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.blue500.withValues(alpha: 0.12),
            blurRadius: 16,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: ClipOval(
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const _CompanionFallback();
                  },
                )
              : const _CompanionFallback(),
        ),
      ),
    );
  }
}

class _CompanionFallback extends StatelessWidget {
  const _CompanionFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.blue400,
      child: Icon(
        Icons.menu_book_rounded,
        color: AppColors.surfaceWhite,
        size: 40,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTrailingTap,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gray900, size: 26),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleRegular.copyWith(
              color: AppColors.gray900,
              height: 20 / 18,
            ),
          ),
        ),
        if (trailing != null)
          InkWell(
            onTap: onTrailingTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trailing!,
                    style: AppTypography.bodyMediumBold.copyWith(
                      color: AppColors.blue500,
                      height: 20 / 14,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.blue500,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

BoxDecoration _cardDecoration({required double radius, required bool shadow}) {
  return BoxDecoration(
    color: AppColors.surfaceWhite,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.gray100),
    boxShadow: shadow
        ? [
            BoxShadow(
              color: AppColors.blue600.withValues(alpha: 0.12),
              blurRadius: 30,
              offset: const Offset(0, 10),
              spreadRadius: -5,
            ),
          ]
        : null,
  );
}
