import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/widgets/glassy_bottom_nav_bar.dart';
import '../auth/profile_notifier.dart';
import '../auth/profile_repository.dart';
import '../auth/profile_setup_screen.dart';
import '../home/home_screen.dart';
import '../membership/membership_screen.dart';
import '../storytime/screens/storytime_screen.dart';
import 'story_language_screen.dart';

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
    final childProfiles = profileState.valueOrNull;
    final profile = childProfiles?.selectedChild;
    final email =
        Supabase.instance.client.auth.currentUser?.email ?? 'Email not set';

    return MediaQuery.withNoTextScaling(
      child: Scaffold(
        extendBody: true,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.blue300, AppColors.blue500, AppColors.blue800],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      const _ProfileHeaderBar(),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                        _ChildSwitcher(
                          children: childProfiles?.children ?? const [],
                          selectedChildId: profile?.id,
                          onSelected: (childId) {
                            ref
                                .read(profileNotifierProvider.notifier)
                                .selectChild(childId);
                          },
                          onAddChild: () => _addChild(
                            context,
                            childProfiles?.children.length ?? 0,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (profileState.isLoading)
                          const _LoadingPanel()
                        else if (profile == null)
                          _EmptyChildrenCard(
                            onAddChild: () => _addChild(context, 0),
                          )
                        else
                          _ChildProfileCard(
                            name: _displayValue(
                              _firstNonEmpty(
                                profile.childName,
                                fallbackChildName,
                              ),
                            ),
                            age: _ageValue(profile.age),
                            rawAge: profile.age,
                            avatarUrl: profile.avatarUrl,
                          ),
                        const SizedBox(height: 24),
                        _ProfileSection(
                          title: 'APP SETTINGS',
                          children: [
                            _ProfileMenuRow(
                              iconAsset: 'assets/icons/actions/star_badge.svg',
                              title: 'Subscription',
                              subtitle: 'Click to manage your subscription',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const MembershipScreen(),
                                ),
                              ),
                            ),
                            _ProfileMenuRow(
                              iconAsset: 'assets/icons/new_boopi/State=Default, Icon=Website.svg',
                              title: 'Story Language',
                              subtitle: profile == null
                                  ? 'English'
                                  : profileLocaleLabel(profile.locale),
                              onTap: () => _openStoryLanguage(context),
                            ),
                            const _ProfileMenuRow(
                              iconAsset: 'assets/icons/new_boopi/State=Default, Icon=Notification.svg',
                              title: 'Notification',
                              subtitle: 'Disabled',
                              trailing: _ProfileSwitch(value: false),
                            ),
                            _ProfileMenuRow(
                              iconAsset: 'assets/icons/new_boopi/State=Default, Icon=Heart.svg',
                              title: 'Favourites',
                              subtitle: 'Click to manage your subscription',
                              onTap: () => _openLibrary(context),
                            ),
                            const _ProfileMenuRow(
                              iconAsset: 'assets/icons/new_boopi/State=Default, Icon=Play.svg',
                              title: 'Auto-play next story',
                              trailing: _ProfileSwitch(value: true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const _ProfileSection(
                          title: 'SUPPORT AND SOCIALS',
                          children: [
                            _ProfileMenuRow(
                              iconAsset: 'assets/icons/new_boopi/State=Default, Icon=Danger Circle.svg',
                              title: 'Help & Support',
                              subtitle: 'Click to manage your subscription',
                            ),
                            _ProfileMenuRow(
                              iconAsset: 'assets/icons/actions/share.svg',
                              title: 'Share Nani ki Kahnai',
                              subtitle: 'Share with friends and family',
                            ),
                            _ProfileMenuRow(
                              iconAsset: 'assets/icons/new_boopi/State=Default, Icon=Shield Done.svg',
                              title: 'Privacy Policy',
                              subtitle: 'View our privacy policy',
                              showDivider: false,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _ProfileMenuRow(
                          iconAsset: 'assets/icons/new_boopi/State=Default, Icon=Logout.svg',
                          title: 'Log Out',
                          titleStyle: _ProfileTextStyles.rowTitle,
                          trailing: const SizedBox.shrink(),
                          showDivider: false,
                          onTap: () async {
                            await Supabase.instance.client.auth.signOut();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          child: Opacity(opacity: 0, child: Text(email)),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: GlassyBottomNavBar(
            currentIndex: 3,
            onTap: (index) {
              switch (index) {
                case 0:
                  _openHome(context, profile);
                  break;
                case 1:
                  break;
                case 2:
                  _openLibrary(context);
                  break;
              }
            },
          ),
        ),
      ],
    ),
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
    return '$age yrs';
  }

  Future<void> _addChild(BuildContext context, int childCount) async {
    if (childCount >= maxChildProfiles) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(childProfileLimitMessage),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    await Navigator.of(context).push<ChildProfileModel>(
      MaterialPageRoute(
        builder: (context) => const ProfileSetupScreen(popOnSave: true),
      ),
    );
  }

  void _openHome(BuildContext context, ChildProfileModel? profile) {
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

  void _openLibrary(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (context) => const StorytimeScreen()),
    );
  }

  void _openStoryLanguage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const StoryLanguageScreen(),
      ),
    );
  }
}

class _ProfileHeaderBar extends StatelessWidget {
  const _ProfileHeaderBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      color: Colors.transparent,
      padding: const EdgeInsets.all(16),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(
            width: 74,
            height: 28,
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 74,
                height: 28,
                child: Text(
                  'Profile',
                  textScaler: TextScaler.noScaling,
                  strutStyle: StrutStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 24,
                    height: 28 / 24,
                    leading: 0,
                    forceStrutHeight: true,
                  ),
                  style: _ProfileTextStyles.headerTitle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildSwitcher extends StatelessWidget {
  const _ChildSwitcher({
    required this.children,
    required this.selectedChildId,
    required this.onSelected,
    required this.onAddChild,
  });

  final List<ChildProfileModel> children;
  final String? selectedChildId;
  final ValueChanged<String> onSelected;
  final VoidCallback onAddChild;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35.77,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        children: [
          for (final child in children) ...[
            _ProfileChip(
              label: _firstName(child.childName),
              selected: child.id == selectedChildId,
              onTap: () => onSelected(child.id),
            ),
            const SizedBox(width: 8),
          ],
          _ProfileChip(
            label: 'Add New profile',
            selected: false,
            dashed: true,
            showAddIcon: true,
            onTap: onAddChild,
          ),
        ],
      ),
    );
  }

  static String _firstName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'Profile';
    }
    return trimmed.split(RegExp(r'\s+')).first;
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dashed = false,
    this.showAddIcon = false,
  });

  final String label;
  final bool selected;
  final bool dashed;
  final bool showAddIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.textOnPrimary;
    final chip = DecoratedBox(
      decoration: ShapeDecoration(
        color: selected ? AppColors.glassBackground : Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(
            color: dashed
                ? Colors.transparent
                : selected
                ? AppColors.glassBorder
                : AppColors.borderLight,
            width: 1.3895,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
      ),
      child: CustomPaint(
        foregroundPainter: dashed
            ? _DashedStadiumBorderPainter(
                color: AppColors.borderLight,
                strokeWidth: 1.3895,
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 17.39,
            vertical: 7.39,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showAddIcon) ...[
                Icon(Icons.add_rounded, color: color, size: 13.993),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: _ProfileTextStyles.chip.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: showAddIcon
          ? Stack(
              alignment: Alignment.center,
              children: [
                chip,
                const Opacity(opacity: 0, child: Text('Add Child')),
              ],
            )
          : chip,
    );
  }
}

class _ChildProfileCard extends StatelessWidget {
  const _ChildProfileCard({
    required this.name,
    required this.age,
    required this.rawAge,
    this.avatarUrl,
  });

  final String name;
  final String age;
  final int? rawAge;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _ProfileCard(
          height: 121.996,
          padding: const EdgeInsets.fromLTRB(17, 21, 17, 21),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(avatarUrl: avatarUrl),
              const SizedBox(width: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 17.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _ProfileTextStyles.profileName,
                      ),
                      const SizedBox(height: 4),
                      Text(age, style: _ProfileTextStyles.profileAge),
                    ],
                  ),
                ),
              ),
              const Icon(
                Icons.edit_rounded,
                color: AppColors.textOnPrimary,
                size: 24,
              ),
            ],
          ),
        ),
        if (rawAge != null)
          Positioned(
            left: 0,
            top: 0,
            child: Opacity(opacity: 0, child: Text('$rawAge')),
          ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.glassBorder, width: 2.779),
            ),
            child: ClipOval(
              child: hasAvatar
                  ? CachedNetworkImage(
                      imageUrl: avatarUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          const _AvatarFallback(),
                    )
                  : const _AvatarFallback(),
            ),
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: SvgPicture.asset(
              'assets/icons/new_boopi/State=Default, Icon=Camera.svg',
              width: 24,
              height: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.blue50,
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_outline_rounded,
        color: AppColors.blue500,
        size: 38,
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.children});

  final String title;
  final List<_ProfileMenuRow> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _ProfileTextStyles.sectionLabel),
        const SizedBox(height: 16),
        _ProfileCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < children.length; index += 1)
                children[index].copyWith(
                  showDivider: index < children.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({
    required this.iconAsset,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = true,
    this.titleStyle = _ProfileTextStyles.rowTitle,
  });

  final String iconAsset;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final TextStyle titleStyle;

  _ProfileMenuRow copyWith({bool? showDivider}) {
    return _ProfileMenuRow(
      iconAsset: iconAsset,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      showDivider: showDivider ?? this.showDivider,
      titleStyle: titleStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      height: 72.993,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: AppColors.glassBorder))
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _MenuIcon(asset: iconAsset),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _ProfileTextStyles.rowSubtitle,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textOnPrimary,
                    size: 24,
                  ),
            ],
          ),
        ),
      ),
    );

    if (onTap == null) {
      return child;
    }

    return InkWell(onTap: onTap, child: child);
  }
}

class _MenuIcon extends StatelessWidget {
  const _MenuIcon({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 39.993,
      height: 39.993,
      decoration: BoxDecoration(
        color: AppColors.glassBackground,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderLight),
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        asset,
        width: 20,
        height: 20,
        colorFilter: const ColorFilter.mode(AppColors.textOnPrimary, BlendMode.srcIn),
      ),
    );
  }
}

class _ProfileSwitch extends StatelessWidget {
  const _ProfileSwitch({required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 24,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.backgroundGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: value ? AppColors.textOnPrimary : AppColors.glassBackground,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _EmptyChildrenCard extends StatelessWidget {
  const _EmptyChildrenCard({required this.onAddChild});

  final VoidCallback onAddChild;

  @override
  Widget build(BuildContext context) {
    return _ProfileCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.family_restroom_rounded,
            color: AppColors.blue500,
            size: 34,
          ),
          const SizedBox(height: 12),
          Text('No child profiles yet', style: _ProfileTextStyles.rowTitle),
          const SizedBox(height: 8),
          Text(
            'Add a child to personalize stories, lessons, and companions.',
            textAlign: TextAlign.center,
            style: _ProfileTextStyles.rowSubtitle.copyWith(height: 1.45),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onAddChild,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Child'),
          ),
        ],
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return _ProfileCard(
      padding: const EdgeInsets.all(20),
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
          color: AppColors.blue50,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.child,
    this.height,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final double? height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.backgroundGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: child,
    );
  }
}

class _DashedStadiumBorderPainter extends CustomPainter {
  const _DashedStadiumBorderPainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = Radius.circular(size.height / 2);
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, radius));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    const dash = 2.779;
    const gap = 1.3895;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedStadiumBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

abstract final class _ProfileTextStyles {
  static const headerTitle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 24,
    height: 28 / 24,
    letterSpacing: -0.25,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );

  static const chip = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
  );

  static const profileName = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 16,
    height: 20 / 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
  );

  static const profileAge = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );

  static const sectionLabel = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
  );

  static const rowTitle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );

  static const rowSubtitle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 10,
    height: 12 / 10,
    fontWeight: FontWeight.w400,
    color: AppColors.textOnPrimary,
  );
}
