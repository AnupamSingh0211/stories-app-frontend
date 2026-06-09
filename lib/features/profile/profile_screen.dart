import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/theme/app_border_radius.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_gradients.dart';
import '../../shared/theme/app_shadows.dart';
import '../auth/companion_model.dart';
import '../auth/companion_notifier.dart';
import '../auth/companions_provider.dart';
import '../auth/profile_notifier.dart';
import '../auth/profile_repository.dart';
import '../home/home_screen.dart';
import '../library/library_screen.dart';
import '../storytime/screens/storytime_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({
    super.key,
    this.fallbackChildName,
    this.fallbackChildAge,
  });

  final String? fallbackChildName;
  final int? fallbackChildAge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileNotifierProvider);
    final profile = profileState.valueOrNull;
    final companionsState = ref.watch(companionsProvider);
    final selectedCompanion = ref.watch(companionNotifierProvider);
    final companionName = _companionName(
      profile: profile,
      selectedCompanion: selectedCompanion,
      companions: companionsState.valueOrNull,
    );
    final email =
        Supabase.instance.client.auth.currentUser?.email ?? 'Email not set';

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: Stack(
          children: [
            const _ProfileGlow(),
            SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 118),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Profile',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 22),
                    _ProfileHeader(email: email, avatarUrl: profile?.avatarUrl),
                    const SizedBox(height: 20),
                    profileState.isLoading
                        ? const _LoadingPanel()
                        : _ProfileDetailsCard(
                            name: _displayValue(
                              _firstNonEmpty(
                                profile?.childName,
                                fallbackChildName,
                              ),
                            ),
                            age: _ageValue(profile?.age ?? fallbackChildAge),
                            companion: companionName,
                          ),
                    const SizedBox(height: 16),
                    const _ProfileMenuCard(),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 18,
              child: _ProfileBottomNavigation(
                onHomeTap: () => _openHome(context, profile),
                onStoriesTap: () => _openStories(context),
                onLibraryTap: () => _openLibrary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _displayValue(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return 'Not set';
    }
    return trimmed;
  }

  static String? _firstNonEmpty(String? primary, String? fallback) {
    final primaryTrimmed = primary?.trim();
    if (primaryTrimmed != null && primaryTrimmed.isNotEmpty) {
      return primaryTrimmed;
    }

    final fallbackTrimmed = fallback?.trim();
    if (fallbackTrimmed != null && fallbackTrimmed.isNotEmpty) {
      return fallbackTrimmed;
    }

    return null;
  }

  static String _ageValue(int? age) {
    if (age == null || age <= 0) {
      return 'Not set';
    }
    return '$age';
  }

  static String _companionName({
    required ProfileModel? profile,
    required CompanionModel? selectedCompanion,
    required List<CompanionModel>? companions,
  }) {
    if (selectedCompanion != null) {
      return selectedCompanion.displayName;
    }

    final companionId = profile?.companionId;
    if (companionId == null || companionId.isEmpty || companions == null) {
      return 'Not set';
    }

    for (final companion in companions) {
      if (companion.id == companionId) {
        return companion.displayName;
      }
    }

    return 'Not set';
  }

  void _openHome(BuildContext context, ProfileModel? profile) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => HomeScreen(
          childName: _displayValue(
            _firstNonEmpty(profile?.childName, fallbackChildName),
          ),
          childAge: profile?.age != null && profile!.age > 0
              ? profile.age
              : fallbackChildAge ?? 2,
        ),
      ),
    );
  }

  void _openStories(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (context) => const StorytimeScreen()),
    );
  }

  void _openLibrary(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (context) => const LibraryScreen()),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.email, this.avatarUrl});

  final String email;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _ProfilePanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            children: [
              _Avatar(avatarUrl: avatarUrl),
              const SizedBox(height: 8),
              Text(
                'Change pic',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 40,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite08,
                      borderRadius: AppBorderRadius.button,
                      border: Border.all(color: AppColors.borderMedium),
                    ),
                    child: Center(
                      child: Text(
                        'Edit Profile',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.companion,
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPrimary.withValues(alpha: 0.22),
            blurRadius: 22,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: ClipOval(
          child: hasAvatar
              ? CachedNetworkImage(
                  imageUrl: avatarUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const _AvatarFallback(),
                )
              : const _AvatarFallback(),
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.imageFallback),
      child: Icon(
        Icons.person_outline_rounded,
        color: Theme.of(context).colorScheme.primary,
        size: 46,
      ),
    );
  }
}

class _ProfileDetailsCard extends StatelessWidget {
  const _ProfileDetailsCard({
    required this.name,
    required this.age,
    required this.companion,
  });

  final String name;
  final String age;
  final String companion;

  @override
  Widget build(BuildContext context) {
    return _ProfilePanel(
      child: Column(
        children: [
          _DetailRow(label: 'Name', value: name),
          const _DividerLine(),
          _DetailRow(label: 'Age', value: age),
          const _DividerLine(),
          _DetailRow(label: 'Companion', value: companion),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.64),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuCard extends StatelessWidget {
  const _ProfileMenuCard();

  static const _items = [
    _MenuItem(Icons.favorite_border_rounded, 'Favourites'),
    _MenuItem(Icons.download_rounded, 'Downloads'),
    _MenuItem(Icons.language_rounded, 'Language'),
    _MenuItem(Icons.settings_outlined, 'Settings'),
    _MenuItem(Icons.workspace_premium_outlined, 'Subscriptions'),
  ];

  @override
  Widget build(BuildContext context) {
    return _ProfilePanel(
      child: Column(
        children: [
          for (final entry in _items.asMap().entries) ...[
            _MenuRow(item: entry.value),
            if (entry.key != _items.length - 1) const _DividerLine(),
          ],
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item});

  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.accentPrimary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: colors.primary, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              item.label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
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

class _MenuItem {
  const _MenuItem(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return _ProfilePanel(
      child: Column(
        children: const [
          _ShimmerLine(widthFactor: 0.92),
          SizedBox(height: 18),
          _ShimmerLine(widthFactor: 0.72),
          SizedBox(height: 18),
          _ShimmerLine(widthFactor: 0.82),
        ],
      ),
    );
  }
}

class _ShimmerLine extends StatelessWidget {
  const _ShimmerLine({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 18,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite12,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withValues(alpha: 0.84),
        borderRadius: AppBorderRadius.card,
        border: Border.all(color: AppColors.borderDark),
        boxShadow: const [AppShadows.elevation2],
      ),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.borderDark);
  }
}

class _ProfileGlow extends StatelessWidget {
  const _ProfileGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 56,
            right: 30,
            child: Icon(
              Icons.nightlight_round,
              color: AppColors.emotionalWarmthSoft.withValues(alpha: 0.82),
              size: 86,
            ),
          ),
          Positioned(
            left: -72,
            top: 138,
            child: _GlowBall(
              size: 210,
              color: AppColors.accentPrimary,
              opacity: 0.12,
            ),
          ),
          Positioned(
            right: -96,
            top: 340,
            child: _GlowBall(
              size: 240,
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

class _ProfileBottomNavigation extends StatelessWidget {
  const _ProfileBottomNavigation({
    required this.onHomeTap,
    required this.onStoriesTap,
    required this.onLibraryTap,
  });

  final VoidCallback onHomeTap;
  final VoidCallback onStoriesTap;
  final VoidCallback onLibraryTap;

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
          Expanded(
            child: _NavItem(
              icon: Icons.menu_book_outlined,
              label: 'Library',
              selected: false,
              onTap: onLibraryTap,
            ),
          ),
          const Expanded(
            child: _NavItem(
              icon: Icons.account_circle_outlined,
              label: 'Profile',
              selected: true,
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
