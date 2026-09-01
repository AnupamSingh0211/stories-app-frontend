import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/analytics_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_tokens.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/widgets/app_screen_background.dart';
import '../../shared/widgets/glassy_bottom_nav_bar.dart';
import '../auth/auth_provider.dart';
import '../auth/profile_notifier.dart';
import '../auth/profile_repository.dart';
import '../auth/profile_setup_screen.dart';
import '../home/home_screen.dart';
import '../library/library_sections_screen.dart';
import '../membership/membership_screen.dart';
import '../storytime/providers/continue_listening_provider.dart';
import '../storytime/providers/favorite_stories_provider.dart';
import 'help_and_support_screen.dart';
import 'privacy_policy_screen.dart';
import 'story_language_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({
    super.key,
    this.fallbackChildName,
    this.fallbackChildAge,
  });

  final String? fallbackChildName;
  final int? fallbackChildAge;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final Map<String, Uint8List> _selectedAvatarBytes = {};
  bool _isAutoPlayNextStoryEnabled = true;

  @override
  void initState() {
    super.initState();
    unawaited(
      PostHogAnalytics.instance.screenOpened(
        'profile_screen',
        properties: {'source': 'app_navigation'},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final childProfiles = profileState.valueOrNull;
    final profile = childProfiles?.selectedChild;
    final email =
        Supabase.instance.client.auth.currentUser?.email ?? 'Email not set';

    return MediaQuery.withNoTextScaling(
      child: Scaffold(
        extendBody: true,
        body: AppScreenBackground(
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
                                      widget.fallbackChildName,
                                    ),
                                  ),
                                  age: _ageValue(profile.age),
                                  rawAge: profile.age,
                                  avatarBytes: _selectedAvatarBytes[profile.id],
                                  onAvatarCameraTap: () =>
                                      _pickProfileAvatar(profile),
                                  onEditTap: () =>
                                      _editChildProfile(context, profile),
                                ),
                              const SizedBox(height: 24),
                              _ProfileSection(
                                title: 'APP SETTINGS',
                                children: [
                                  _ProfileMenuRow(
                                    iconAsset:
                                        'assets/icons/new_boopi/streamline-sharp_star-badge.svg',
                                    title: 'Subscription',
                                    subtitle: 'For yawns and cuddles.',
                                    onTap: () => _openMembership(context),
                                  ),
                                  _ProfileMenuRow(
                                    iconAsset:
                                        'assets/icons/new_boopi/State=Default, Icon=Website.svg',
                                    title: 'Story Language',
                                    subtitle:
                                        "Tonight's stories in ${profile == null ? 'English' : profileLocaleLabel(profile.locale)}.",
                                    onTap: () => _openStoryLanguage(context),
                                  ),
                                  const _ProfileMenuRow(
                                    iconAsset:
                                        'assets/icons/new_boopi/State=Default, Icon=Notification.svg',
                                    title: 'Notification',
                                    subtitle:
                                        "To nudge you when it's story time.",
                                    trailing: _ProfileSwitch(value: false),
                                  ),
                                  _ProfileMenuRow(
                                    iconAsset:
                                        'assets/icons/new_boopi/State=Default, Icon=Heart.svg',
                                    title: 'Favourites',
                                    subtitle:
                                        'They just loved this. \u2764\uFE0F',
                                    onTap: () => _openLibrary(context),
                                  ),
                                  _ProfileMenuRow(
                                    iconAsset:
                                        'assets/icons/new_boopi/State=Default, Icon=Play.svg',
                                    title: 'Auto-play next story',
                                    trailing: _ProfileSwitch(
                                      value: _isAutoPlayNextStoryEnabled,
                                      onChanged: _toggleAutoPlayNextStory,
                                    ),
                                    onTap: _toggleAutoPlayNextStory,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _ProfileSection(
                                title: 'SUPPORT AND SOCIALS',
                                children: [
                                  _ProfileMenuRow(
                                    iconAsset:
                                        'assets/icons/new_boopi/State=Default, Icon=Danger Circle.svg',
                                    title: 'Help & Support',
                                    subtitle: "We're here to help.",
                                    onTap: () => _openHelpAndSupport(context),
                                  ),
                                  _ProfileMenuRow(
                                    iconAsset:
                                        'assets/icons/new_boopi/clarity_share-line.svg',
                                    title: 'Share Boopi',
                                    subtitle: 'Spread the bedtime magic.',
                                    onTap: () => _shareBoopi(context),
                                  ),
                                  _ProfileMenuRow(
                                    iconAsset:
                                        'assets/icons/new_boopi/State=Default, Icon=Shield Done.svg',
                                    title: 'Privacy Policy',
                                    subtitle: 'View our privacy policy',
                                    showDivider: false,
                                    onTap: () => _openPrivacyPolicy(context),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _LogoutButton(onTap: _logout),
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
                    unawaited(
                      PostHogAnalytics.instance.buttonClicked(
                        buttonName: 'bottom_nav_item',
                        screenName: 'profile_screen',
                        properties: {
                          'source': 'bottom_nav',
                          'target_index': index,
                        },
                      ),
                    );
                    switch (index) {
                      case 0:
                        _openHome(context, profile);
                        break;
                      case 1:
                        _openHome(context, profile, initialTab: 1);
                        break;
                      case 2:
                        _openHome(context, profile, initialTab: 2);
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
    unawaited(
      PostHogAnalytics.instance.buttonClicked(
        buttonName: 'add_child_profile',
        screenName: 'profile_screen',
        properties: {'source': 'profile_switcher'},
      ),
    );
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

  Future<void> _editChildProfile(
    BuildContext context,
    ChildProfileModel profile,
  ) async {
    unawaited(
      PostHogAnalytics.instance.buttonClicked(
        buttonName: 'edit_child_profile',
        screenName: 'profile_screen',
        properties: {'source': 'child_profile_card'},
      ),
    );

    await Navigator.of(context).push<ChildProfileModel>(
      MaterialPageRoute(
        builder: (context) => ProfileSetupScreen.edit(child: profile),
      ),
    );
  }

  Future<void> _logout() async {
    unawaited(
      PostHogAnalytics.instance.capture(
        'logout_clicked',
        properties: {'screen_name': 'profile_screen', 'source': 'profile_menu'},
      ),
    );
    unawaited(
      PostHogAnalytics.instance.buttonClicked(
        buttonName: 'logout',
        screenName: 'profile_screen',
        properties: {'source': 'profile_menu'},
      ),
    );
    await ref.read(appAuthServiceProvider).signOut();
    ref.invalidate(authSessionProvider);
    ref.invalidate(profileNotifierProvider);
    ref.invalidate(sessionStoryHistoryProvider);
    ref.invalidate(continueListeningProvider);
    ref.invalidate(favoriteStoryCardsProvider);
    ref.invalidate(favoriteStoriesProvider);

    if (!mounted) {
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openHome(
    BuildContext context,
    ChildProfileModel? profile, {
    int initialTab = 0,
  }) {
    final navigator = Navigator.of(context);
    if (initialTab == 0 && navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => HomeScreen(
          childName: _displayValue(
            _firstNonEmpty(profile?.childName, widget.fallbackChildName),
          ),
          childAge: profile?.age != null && profile!.age > 0
              ? profile.age
              : widget.fallbackChildAge ?? 2,
          initialTab: initialTab,
        ),
      ),
    );
  }

  void _openLibrary(BuildContext context) {
    unawaited(
      PostHogAnalytics.instance.capture(
        'favorites_clicked',
        properties: {'screen_name': 'profile_screen', 'source': 'profile_menu'},
      ),
    );
    unawaited(
      PostHogAnalytics.instance.buttonClicked(
        buttonName: 'favorites',
        screenName: 'profile_screen',
        properties: {'source': 'profile_menu'},
      ),
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const LibrarySectionsScreen(),
      ),
    );
  }

  void _openStoryLanguage(BuildContext context) {
    unawaited(
      PostHogAnalytics.instance.buttonClicked(
        buttonName: 'story_language',
        screenName: 'profile_screen',
        properties: {'source': 'profile_menu'},
      ),
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const StoryLanguageScreen(),
      ),
    );
  }

  void _openPrivacyPolicy(BuildContext context) {
    unawaited(
      PostHogAnalytics.instance.buttonClicked(
        buttonName: 'privacy_policy',
        screenName: 'profile_screen',
        properties: {'source': 'profile_menu'},
      ),
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const PrivacyPolicyScreen(),
      ),
    );
  }

  void _openHelpAndSupport(BuildContext context) {
    unawaited(
      PostHogAnalytics.instance.buttonClicked(
        buttonName: 'help_and_support',
        screenName: 'profile_screen',
        properties: {'source': 'profile_menu'},
      ),
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const HelpAndSupportScreen(),
      ),
    );
  }

  void _toggleAutoPlayNextStory() {
    unawaited(
      PostHogAnalytics.instance.buttonClicked(
        buttonName: 'auto_play_next_story',
        screenName: 'profile_screen',
        properties: {
          'source': 'profile_menu',
          'enabled_after_click': !_isAutoPlayNextStoryEnabled,
        },
      ),
    );
    setState(() {
      _isAutoPlayNextStoryEnabled = !_isAutoPlayNextStoryEnabled;
    });
  }

  Future<void> _shareBoopi(BuildContext context) async {
    unawaited(
      PostHogAnalytics.instance.buttonClicked(
        buttonName: 'share_boopi',
        screenName: 'profile_screen',
        properties: {'source': 'profile_menu'},
      ),
    );
    const message = 'Check out Boopi, a magical bedtime stories app for kids.';

    try {
      final box = context.findRenderObject() as RenderBox?;
      await Share.share(
        message,
        subject: 'Boopi',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Unable to open sharing options.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _pickProfileAvatar(ChildProfileModel profile) async {
    unawaited(
      PostHogAnalytics.instance.buttonClicked(
        buttonName: 'profile_avatar',
        screenName: 'profile_screen',
        properties: {'source': 'child_profile_card'},
      ),
    );
    final selectedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (selectedImage == null) {
      return;
    }

    final bytes = await selectedImage.readAsBytes();
    if (!mounted) {
      return;
    }

    if (bytes.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Unable to load the selected photo.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    setState(() {
      _selectedAvatarBytes[profile.id] = bytes;
    });
  }

  void _openMembership(BuildContext context) {
    unawaited(
      PostHogAnalytics.instance.capture(
        'subscription_page_viewed',
        properties: {'screen_name': 'profile_screen', 'source': 'profile_menu'},
      ),
    );
    unawaited(
      PostHogAnalytics.instance.buttonClicked(
        buttonName: 'subscription',
        screenName: 'profile_screen',
        properties: {'source': 'profile_menu'},
      ),
    );
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const MembershipScreen()));
  }
}

class _ProfileHeaderBar extends ConsumerWidget {
  const _ProfileHeaderBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentColor = AppTokenColors.of(ref).profileTextPrimary;
    final tokenTextStyles = AppTokenTextStyles.of(ref);

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
              child: Icon(
                Icons.arrow_back_rounded,
                color: contentColor,
                size: 24,
                applyTextScaling: false,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 74,
            child: Text(
              'Profile',
              maxLines: 1,
              overflow: TextOverflow.visible,
              textScaler: TextScaler.noScaling,
              style: tokenTextStyles.profileHeaderTitle.copyWith(
                color: contentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildProfileCard extends ConsumerWidget {
  const _ChildProfileCard({
    required this.name,
    required this.age,
    required this.rawAge,
    this.avatarBytes,
    this.onAvatarCameraTap,
    this.onEditTap,
  });

  final String name;
  final String age;
  final int? rawAge;
  final Uint8List? avatarBytes;
  final VoidCallback? onAvatarCameraTap;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenColors = AppTokenColors.of(ref);
    final contentColor = tokenColors.profileTextPrimary;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        _ProfileCard(
          height: 121.996,
          padding: const EdgeInsets.fromLTRB(17, 21, 17, 21),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(
                avatarBytes: avatarBytes,
                onCameraTap: onAvatarCameraTap,
                contentColor: contentColor,
              ),
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
                        style: _ProfileTextStyles.profileName.copyWith(
                          color: contentColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        age,
                        style: _ProfileTextStyles.profileAge.copyWith(
                          color: tokenColors.profileTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Edit child profile',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onEditTap,
                  child: SizedBox.square(
                    dimension: 44,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/new_boopi/State=Default, Icon=Edit Square.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          contentColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
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
  const _Avatar({
    this.avatarBytes,
    this.onCameraTap,
    required this.contentColor,
  });

  final Uint8List? avatarBytes;
  final VoidCallback? onCameraTap;
  final Color contentColor;

  @override
  Widget build(BuildContext context) {
    final hasSelectedAvatar = avatarBytes != null && avatarBytes!.isNotEmpty;

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
              child: hasSelectedAvatar
                  ? Image.memory(avatarBytes!, fit: BoxFit.cover)
                  : const _AvatarFallback(),
            ),
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onCameraTap,
              child: SizedBox.square(
                dimension: 32,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/new_boopi/majesticons_camera.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      contentColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
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

class _ProfileSection extends ConsumerWidget {
  const _ProfileSection({required this.title, required this.children});

  final String title;
  final List<_ProfileMenuRow> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentColor = AppTokenColors.of(ref).profileTextPrimary;
    final tokenTextStyles = AppTokenTextStyles.of(ref);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: tokenTextStyles.profileSectionLabel.copyWith(
            color: contentColor,
          ),
        ),
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

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentColor = AppTokenColors.of(ref).profileTextPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Log Out',
              style: _ProfileTextStyles.logoutLabel.copyWith(
                color: contentColor,
              ),
            ),
            const SizedBox(width: 4),
            SizedBox.square(
              dimension: 24,
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/new_boopi/Iconly/Light/Arrow - Right.svg',
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(contentColor, BlendMode.srcIn),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuRow extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenColors = AppTokenColors.of(ref);
    final tokenTextStyles = AppTokenTextStyles.of(ref);
    final contentColor = tokenColors.profileTextPrimary;
    final effectiveTitleStyle = titleStyle == _ProfileTextStyles.rowTitle
        ? tokenTextStyles.profileRowTitle
        : titleStyle;
    final child = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 72.993),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: tokenColors.profileRowDivider))
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              _MenuIcon(asset: iconAsset, color: contentColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: effectiveTitleStyle.copyWith(color: contentColor),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tokenTextStyles.profileRowSubtitle.copyWith(
                          color: tokenColors.profileTextSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: contentColor,
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

class _MenuIcon extends ConsumerWidget {
  const _MenuIcon({required this.asset, required this.color});

  final String asset;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 39.993,
      height: 39.993,
      decoration: BoxDecoration(
        color: AppTokenColors.of(ref).profileIconBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        asset,
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}

class _ProfileSwitch extends ConsumerWidget {
  const _ProfileSwitch({required this.value, this.onChanged});

  final bool value;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenColors = AppTokenColors.of(ref);
    final switchControl = Container(
      width: 44,
      height: 24,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: tokenColors.profileSwitchTrack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokenColors.profileCardBorder),
      ),
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: value
              ? tokenColors.profileSwitchThumbActive
              : tokenColors.profileIconBackground,
          shape: BoxShape.circle,
        ),
      ),
    );

    if (onChanged == null) {
      return switchControl;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged,
      child: switchControl,
    );
  }
}

class _EmptyChildrenCard extends ConsumerWidget {
  const _EmptyChildrenCard({required this.onAddChild});

  final VoidCallback onAddChild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenColors = AppTokenColors.of(ref);
    final tokenTextStyles = AppTokenTextStyles.of(ref);
    final contentColor = tokenColors.profileTextPrimary;

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
          Text(
            'No child profiles yet',
            style: tokenTextStyles.profileRowTitle.copyWith(
              color: contentColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a child to personalize stories, lessons, and companions.',
            textAlign: TextAlign.center,
            style: tokenTextStyles.profileRowSubtitle.copyWith(
              height: 1.45,
              color: tokenColors.profileTextSecondary,
            ),
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

class _ShimmerLine extends ConsumerWidget {
  const _ShimmerLine({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 18,
        decoration: BoxDecoration(
          color: AppTokenColors.of(ref).profileLoadingPlaceholder,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({
    required this.child,
    this.height,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final double? height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenColors = AppTokenColors.of(ref);
    return Container(
      width: double.infinity,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: tokenColors.profileCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokenColors.profileCardBorder),
      ),
      child: child,
    );
  }
}

abstract final class _ProfileTextStyles {
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

  static const rowTitle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );

  static const logoutLabel = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );
}
