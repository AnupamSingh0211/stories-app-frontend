import 'package:flutter/material.dart';

import '../../core/notifications/notification_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/widgets/app_screen_background.dart';
import 'onboarding_store.dart';

class OnboardingPage {
  const OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

const onboardingPages = <OnboardingPage>[
  OnboardingPage(
    icon: Icons.auto_stories_rounded,
    title: 'Stories that end\nin sweet dreams',
    body:
        'Boopi plays calm audiobooks at bedtime. A parent presses play. A child listens.',
  ),
  OnboardingPage(
    icon: Icons.nightlight_round,
    title: 'A companion for\nevery night',
    body:
        'Choose a gentle guide, then pick stories by age. English and Hindi both belong here.',
  ),
  OnboardingPage(
    icon: Icons.notifications_active_outlined,
    title: 'May Boopi send\nnotifications?',
    body:
        'A quiet note when a new story is ready, or when it is time to wind down. You can change this later in phone settings.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    required this.onFinished,
    this.requestNotifications,
    this.initialPage = 0,
    super.key,
  }) : assert(initialPage >= 0);

  final VoidCallback onFinished;
  final Future<void> Function()? requestNotifications;
  final int initialPage;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController = PageController(
    initialPage: widget.initialPage,
  );
  late int _page = widget.initialPage;
  bool _saving = false;

  bool get _isNotificationPage => _page == onboardingPages.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goTo(int page) async {
    await _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish({required bool notificationsAllowed}) async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      if (notificationsAllowed) {
        final request =
            widget.requestNotifications ??
            NotificationService.instance.requestPermission;
        await request();
      }
      await OnboardingStore.complete(
        notificationsAllowed: notificationsAllowed,
      );
      if (!mounted) {
        return;
      }
      widget.onFinished();
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppScreenBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              children: [
                _OnboardingTopBar(
                  page: _page,
                  onBack: _page == 0 ? null : () => _goTo(_page - 1),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: onboardingPages.length,
                    onPageChanged: (page) => setState(() => _page = page),
                    itemBuilder: (context, index) {
                      return _OnboardingCopy(page: onboardingPages[index]);
                    },
                  ),
                ),
                if (_isNotificationPage) ...[
                  _OnboardingButton(
                    key: const Key('onboarding-allow'),
                    label: _saving ? 'One moment...' : 'Allow notifications',
                    filled: true,
                    onTap: _saving
                        ? null
                        : () => _finish(notificationsAllowed: true),
                  ),
                  const SizedBox(height: 8),
                  _OnboardingButton(
                    key: const Key('onboarding-skip'),
                    label: 'Not now',
                    filled: false,
                    onTap: _saving
                        ? null
                        : () => _finish(notificationsAllowed: false),
                  ),
                ] else
                  _OnboardingButton(
                    key: const Key('onboarding-next'),
                    label: 'Next',
                    filled: true,
                    onTap: () => _goTo(_page + 1),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingTopBar extends StatelessWidget {
  const _OnboardingTopBar({required this.page, required this.onBack});

  final int page;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          SizedBox.square(
            dimension: 40,
            child: onBack == null
                ? null
                : IconButton(
                    key: const Key('onboarding-back'),
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.textInverse,
                  ),
          ),
          Expanded(
            child: Row(
              key: const Key('onboarding-progress'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < onboardingPages.length; index++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: index == page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: index == page
                            ? AppColors.blue200
                            : AppColors.textInverse.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox.square(dimension: 40),
        ],
      ),
    );
  }
}

class _OnboardingCopy extends StatelessWidget {
  const _OnboardingCopy({required this.page});

  final OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.backgroundGlass,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.borderGlass),
          ),
          child: SizedBox.square(
            dimension: 112,
            child: Icon(page.icon, size: 52, color: AppColors.blue100),
          ),
        ),
        const SizedBox(height: 36),
        Text(
          page.title,
          key: Key('onboarding-title-${page.title}'),
          textAlign: TextAlign.center,
          style: AppTypography.heading1Bold.copyWith(
            color: AppColors.textInverse,
            fontSize: 32,
            height: 38 / 32,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          page.body,
          textAlign: TextAlign.center,
          style: AppTypography.bodyLargeRegular.copyWith(
            color: AppColors.textInverse.withValues(alpha: 0.82),
          ),
        ),
      ],
    );
  }
}

class _OnboardingButton extends StatelessWidget {
  const _OnboardingButton({
    required this.label,
    required this.filled,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final background = filled ? AppColors.blue200 : Colors.transparent;
    final foreground = filled ? AppColors.neutral900 : AppColors.textInverse;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: filled
                  ? null
                  : Border.all(
                      color: AppColors.textInverse.withValues(alpha: 0.45),
                    ),
            ),
            child: Text(
              label,
              style: AppTypography.labelSemiBold.copyWith(color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}
