import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/profile_notifier.dart';
import '../profile/profile_screen.dart';
import '../storytime/models/story_model.dart';
import '../storytime/providers/saved_library_provider.dart';
import '../storytime/repositories/story_repository.dart';
import '../storytime/screens/story_player_screen.dart';
import '../storytime/screens/storytime_screen.dart';
import '../storytime/widgets/story_image_view.dart';

const _libraryBackgroundGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF11184A), Color(0xFF0C1230), Color(0xFF080D1D)],
);

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(savedLibraryProvider.notifier).loadLibrary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(savedLibraryProvider);
    final profile = ref
        .watch(profileNotifierProvider)
        .valueOrNull
        ?.selectedChild;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: _libraryBackgroundGradient),
        child: Stack(
          children: [
            const _LibraryGlow(),
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LibraryHeader(savedCount: library.savedCount),
                          if (library.errorMessage != null) ...[
                            const SizedBox(height: 14),
                            _ErrorBanner(message: library.errorMessage!),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (library.isLoading)
                    const SliverFillRemaining(child: _LoadingLibrary())
                  else if (library.stories.isEmpty)
                    const SliverFillRemaining(child: _EmptyLibrary())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 118),
                      sliver: SliverList.separated(
                        itemCount: library.stories.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          return _SavedStoryCard(
                            story: library.stories[index],
                            onRemove: () => ref
                                .read(savedLibraryProvider.notifier)
                                .removeStory(library.stories[index].id),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 18,
              child: _LibraryBottomNavigation(
                onHomeTap: () => Navigator.maybePop(context),
                onStoriesTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (context) => const StorytimeScreen(),
                  ),
                ),
                onProfileTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (context) => ProfileScreen(
                      fallbackChildName: profile?.childName,
                      fallbackChildAge: profile?.age,
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

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({required this.savedCount});

  final int savedCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Library',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colors.onSurface,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Replay the stories your child loves most.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.66),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF7A5CFF).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Text(
              '$savedCount/${StoryRepository.savedStoryLimit} Saved',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SavedStoryCard extends StatelessWidget {
  const _SavedStoryCard({required this.story, required this.onRemove});

  final StoryModel story;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => StoryPlayerScreen(
            storyId: story.id,
            title: story.title,
            story: story,
          ),
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF121936).withValues(alpha: 0.84),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              SizedBox(
                width: 82,
                height: 82,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
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
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${story.durationLabel} - ${story.category}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.62),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: colors.onSurface.withValues(alpha: 0.66),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 40, 36, 132),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: const Color(0xFF7A5CFF).withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.library_books_outlined,
              color: colors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            "Start adding your child's favorite stories and listen to them anytime.",
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.74),
              fontSize: 16,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingLibrary extends StatelessWidget {
  const _LoadingLibrary();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Color(0xFFA9A7FF),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B6B).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: const Color(0xFFFFE6A4),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _LibraryGlow extends StatelessWidget {
  const _LibraryGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            right: -96,
            top: 260,
            child: _GlowBall(
              size: 240,
              color: const Color(0xFFFFD96B),
              opacity: 0.08,
            ),
          ),
          Positioned(
            left: -76,
            top: 110,
            child: _GlowBall(
              size: 210,
              color: const Color(0xFF756BFF),
              opacity: 0.13,
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

class _LibraryBottomNavigation extends StatelessWidget {
  const _LibraryBottomNavigation({
    required this.onHomeTap,
    required this.onStoriesTap,
    required this.onProfileTap,
  });

  final VoidCallback onHomeTap;
  final VoidCallback onStoriesTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 10),
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
              selected: false,
              onTap: onHomeTap,
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.auto_stories_rounded,
              label: 'Stories',
              selected: false,
              onTap: onStoriesTap,
            ),
          ),
          const Expanded(
            child: _NavItem(
              icon: Icons.menu_book_outlined,
              label: 'Library',
              selected: true,
            ),
          ),
          Expanded(
            child: _NavItem(
              icon: Icons.account_circle_outlined,
              label: 'Profile',
              selected: false,
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
