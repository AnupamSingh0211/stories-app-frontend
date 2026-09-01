import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/analytics_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_tokens.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/widgets/app_screen_background.dart';
import 'membership_plans_screen.dart';
import 'membership_side_banner.dart';

class MembershipScreen extends ConsumerStatefulWidget {
  const MembershipScreen({super.key, this.onUnlock, this.onSeeAllPlans});

  final VoidCallback? onUnlock;
  final VoidCallback? onSeeAllPlans;

  @override
  ConsumerState<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends ConsumerState<MembershipScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(
      PostHogAnalytics.instance.screenOpened(
        'membership_screen',
        properties: {'source': 'subscription_flow'},
      ),
    );
    unawaited(
      PostHogAnalytics.instance.capture(
        'subscription_page_viewed',
        properties: {
          'screen_name': 'membership_screen',
          'source': 'subscription_flow',
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokenColors = AppTokenColors.of(ref);
    final contentColor = tokenColors.homeCardTextPrimary;

    return MediaQuery.withNoTextScaling(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: _MembershipSystemUi.style,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: AppScreenBackground(
            child: Stack(
              children: [
                _MembershipTokenScope(
                  contentColor: contentColor,
                  cardBackgroundColor: tokenColors.subscriptionCardBackground,
                  cardBorderColor: tokenColors.subscriptionCardBorder,
                  ctaBackgroundColor: tokenColors.subscriptionCtaBackground,
                  ctaBorderColor: tokenColors.subscriptionCtaBorder,
                  child: SafeArea(
                    left: false,
                    right: false,
                    bottom: false,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final contentWidth = constraints.maxWidth;
                        final scale =
                            contentWidth / _MembershipLayout.designWidth;
                        final canvasHeight = math.max(
                          constraints.maxHeight / scale,
                          _MembershipLayout.designHeight,
                        );

                        return Stack(
                          children: [
                            SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              child: Center(
                                child: SizedBox(
                                  width: contentWidth,
                                  height: canvasHeight * scale,
                                  child: FittedBox(
                                    fit: BoxFit.fill,
                                    alignment: Alignment.topCenter,
                                    child: SizedBox(
                                      width: _MembershipLayout.designWidth,
                                      height: canvasHeight,
                                      child: ClipRect(
                                        child: Stack(
                                          clipBehavior: Clip.hardEdge,
                                          children: [
                                            const Positioned.fill(
                                              child: _MembershipBackground(),
                                            ),
                                            const _HeroArtwork(),
                                            const Positioned(
                                              top: _MembershipLayout.offerTop,
                                              left: 0,
                                              right: 0,
                                              child: _OfferDetails(),
                                            ),
                                            const Positioned(
                                              top:
                                                  _MembershipLayout.benefitsTop,
                                              left: 0,
                                              right: 0,
                                              child: _MembershipBenefits(),
                                            ),
                                            Positioned(
                                              top:
                                                  canvasHeight -
                                                  _MembershipLayout.ctaGap,
                                              left: _MembershipLayout.ctaLeft,
                                              child: _MembershipCta(
                                                onPressed: () {
                                                  unawaited(
                                                    PostHogAnalytics.instance.capture(
                                                      'subscription_started',
                                                      properties: {
                                                        'screen_name':
                                                            'membership_screen',
                                                        'source':
                                                            'membership_cta',
                                                      },
                                                    ),
                                                  );
                                                  unawaited(
                                                    PostHogAnalytics.instance
                                                        .buttonClicked(
                                                          buttonName:
                                                              'unlock_membership',
                                                          screenName:
                                                              'membership_screen',
                                                          properties: {
                                                            'source':
                                                                'membership_cta',
                                                          },
                                                        ),
                                                  );
                                                  widget.onUnlock?.call();
                                                },
                                              ),
                                            ),
                                            Positioned(
                                              top:
                                                  canvasHeight -
                                                  _MembershipLayout.plansGap,
                                              left: 0,
                                              right: 0,
                                              child: _SeeAllPlansButton(
                                                onPressed:
                                                    widget.onSeeAllPlans ??
                                                    () {
                                                      unawaited(
                                                        PostHogAnalytics
                                                            .instance
                                                            .buttonClicked(
                                                              buttonName:
                                                                  'see_all_plans',
                                                              screenName:
                                                                  'membership_screen',
                                                              properties: {
                                                                'source':
                                                                    'membership_footer',
                                                              },
                                                            ),
                                                      );
                                                      Navigator.of(
                                                        context,
                                                      ).push(
                                                        MaterialPageRoute<void>(
                                                          builder: (_) =>
                                                              const MembershipPlansScreen(),
                                                        ),
                                                      );
                                                    },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: _MembershipTokenScope(
                    contentColor: contentColor,
                    cardBackgroundColor: tokenColors.subscriptionCardBackground,
                    cardBorderColor: tokenColors.subscriptionCardBorder,
                    ctaBackgroundColor: tokenColors.subscriptionCtaBackground,
                    ctaBorderColor: tokenColors.subscriptionCtaBorder,
                    child: const _MembershipHeader(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MembershipBackground extends StatelessWidget {
  const _MembershipBackground();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand();
  }
}

class _MembershipTokenScope extends InheritedWidget {
  const _MembershipTokenScope({
    required this.contentColor,
    required this.cardBackgroundColor,
    required this.cardBorderColor,
    required this.ctaBackgroundColor,
    required this.ctaBorderColor,
    required super.child,
  });

  final Color contentColor;
  final Color cardBackgroundColor;
  final Color cardBorderColor;
  final Color ctaBackgroundColor;
  final Color ctaBorderColor;

  Color get secondaryColor => contentColor.withAlpha(217);

  static _MembershipTokenScope of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<_MembershipTokenScope>() ??
        const _MembershipTokenScope(
          contentColor: AppColors.textOnPrimary,
          cardBackgroundColor: _MembershipColors.glass,
          cardBorderColor: _MembershipColors.glassBorder,
          ctaBackgroundColor: _MembershipColors.glass,
          ctaBorderColor: _MembershipColors.glassBorder,
          child: SizedBox.shrink(),
        );
  }

  @override
  bool updateShouldNotify(_MembershipTokenScope oldWidget) {
    return contentColor != oldWidget.contentColor ||
        cardBackgroundColor != oldWidget.cardBackgroundColor ||
        cardBorderColor != oldWidget.cardBorderColor ||
        ctaBackgroundColor != oldWidget.ctaBackgroundColor ||
        ctaBorderColor != oldWidget.ctaBorderColor;
  }
}

class _MembershipHeader extends StatelessWidget {
  const _MembershipHeader();

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final contentColor = _MembershipTokenScope.of(context).contentColor;

    return Container(
      height: statusBarHeight + _MembershipLayout.headerHeight,
      color: _MembershipColors.headerOverlay,
      padding: EdgeInsets.only(top: statusBarHeight),
      child: SizedBox(
        height: _MembershipLayout.headerHeight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: 'Back',
                child: InkResponse(
                  key: const ValueKey('membershipBackButton'),
                  onTap: () {
                    unawaited(
                      PostHogAnalytics.instance.capture(
                        'back_clicked',
                        properties: {
                          'screen_name': 'membership_screen',
                          'source': 'membership_header',
                        },
                      ),
                    );
                    unawaited(
                      PostHogAnalytics.instance.buttonClicked(
                        buttonName: 'back',
                        screenName: 'membership_screen',
                        properties: {'source': 'membership_header'},
                      ),
                    );
                    Navigator.of(context).maybePop();
                  },
                  radius: 24,
                  child: SizedBox.square(
                    dimension: 24,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: contentColor,
                      size: 24,
                      applyTextScaling: false,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Premium Membership',
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 20,
                      height: 24 / 20,
                      letterSpacing: -0.25,
                      fontWeight: FontWeight.w600,
                      color: contentColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroArtwork extends StatelessWidget {
  const _HeroArtwork();

  @override
  Widget build(BuildContext context) {
    final mascotUrl = _membershipMascotUrl();

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          left: _MembershipLayout.sideArtworkLeft,
          top: _MembershipLayout.sideArtworkTop,
          child: const MembershipSideBanner(),
        ),
        Positioned(
          left: _MembershipLayout.mascotLeft,
          top: _MembershipLayout.mascotTop,
          child: mascotUrl == null
              ? const SizedBox(
                  key: ValueKey('membershipHeroImage'),
                  width: _MembershipLayout.mascotWidth,
                  height: _MembershipLayout.mascotHeight,
                )
              : Image.network(
                  mascotUrl,
                  key: const ValueKey('membershipHeroImage'),
                  width: _MembershipLayout.mascotWidth,
                  height: _MembershipLayout.mascotHeight,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    width: _MembershipLayout.mascotWidth,
                    height: _MembershipLayout.mascotHeight,
                  ),
                ),
        ),
      ],
    );
  }

  String? _membershipMascotUrl() {
    try {
      return Supabase.instance.client.storage
          .from('app-assets')
          .getPublicUrl('backgrounds/membership_mascot_character.png');
    } catch (_) {
      return null;
    }
  }
}

class _OfferDetails extends ConsumerWidget {
  const _OfferDetails();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenScope = _MembershipTokenScope.of(context);
    final tokenTextStyles = AppTokenTextStyles.of(ref);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _PlusMemberBadge(),
        const SizedBox(height: 16),
        Text(
          'Unlock the Magic',
          textAlign: TextAlign.center,
          style: tokenTextStyles.subscriptionHeroTitle.copyWith(
            color: tokenScope.secondaryColor,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Premium Access for 5 Days',
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
          style: tokenTextStyles.subscriptionHeroTitle.copyWith(
            color: tokenScope.contentColor,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '₹1',
          style: tokenTextStyles.subscriptionPlanPrice.copyWith(
            color: tokenScope.contentColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Then ₹149/month. Cancel anytime.',
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
          style: tokenTextStyles.subscriptionHeroSubtitle.copyWith(
            color: tokenScope.secondaryColor,
          ),
        ),
      ],
    );
  }
}

class _PlusMemberBadge extends ConsumerWidget {
  const _PlusMemberBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenScope = _MembershipTokenScope.of(context);
    final contentColor = tokenScope.contentColor;
    final tokenTextStyles = AppTokenTextStyles.of(ref);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: tokenScope.cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokenScope.cardBorderColor),
      ),
      child: Text(
        'PLUS MEMBER',
        style: tokenTextStyles.subscriptionBadgeLabel.copyWith(
          color: contentColor,
        ),
      ),
    );
  }
}

class _MembershipBenefits extends ConsumerWidget {
  const _MembershipBenefits();

  static const _benefits = [
    _BenefitData(
      label: 'New\nReleases',
      iconAsset: 'assets/icons/new_boopi/qlementine-icons_new-multiple-16.svg',
    ),
    _BenefitData(
      label: 'Offline\nListening',
      iconAsset: 'assets/icons/new_boopi/ri_headphone-fill.svg',
    ),
    _BenefitData(
      label: 'Ad-Free\nAccess',
      iconAsset: 'assets/icons/new_boopi/boxicons_block.svg',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenScope = _MembershipTokenScope.of(context);
    final tokenTextStyles = AppTokenTextStyles.of(ref);

    return Column(
      children: [
        Text(
          'Your Membership Includes',
          textAlign: TextAlign.center,
          style: tokenTextStyles.subscriptionBenefitsHeading.copyWith(
            color: tokenScope.secondaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < _benefits.length; index += 1) ...[
              _BenefitCard(data: _benefits[index]),
              if (index < _benefits.length - 1)
                const SizedBox(width: _MembershipLayout.benefitGap),
            ],
          ],
        ),
      ],
    );
  }
}

class _BenefitCard extends ConsumerWidget {
  const _BenefitCard({required this.data});

  final _BenefitData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenScope = _MembershipTokenScope.of(context);
    final contentColor = tokenScope.contentColor;
    final tokenTextStyles = AppTokenTextStyles.of(ref);

    return Container(
      width: _MembershipLayout.benefitCardWidth,
      padding: const EdgeInsets.all(12.738),
      decoration: BoxDecoration(
        color: tokenScope.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16.985),
        border: Border.all(color: tokenScope.cardBorderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 2.123),
            blurRadius: 12.738,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            data.iconAsset,
            width: 33.969,
            height: 33.969,
            colorFilter: ColorFilter.mode(contentColor, BlendMode.srcIn),
          ),
          const SizedBox(height: 4.246),
          Text(
            data.label,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: tokenTextStyles.subscriptionBenefitsLabel.copyWith(
              color: contentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitData {
  const _BenefitData({required this.label, required this.iconAsset});

  final String label;
  final String iconAsset;
}

class _MembershipCta extends ConsumerWidget {
  const _MembershipCta({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenScope = _MembershipTokenScope.of(context);
    final contentColor = tokenScope.contentColor;
    final tokenTextStyles = AppTokenTextStyles.of(ref);

    return Semantics(
      key: const ValueKey('membershipUnlockButton'),
      button: true,
      label: 'Unlock membership for ₹1',
      child: Material(
        color: Colors.transparent,
        child: Ink(
          width: _MembershipLayout.ctaWidth,
          height: _MembershipLayout.ctaHeight,
          decoration: BoxDecoration(
            color: tokenScope.ctaBackgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: tokenScope.ctaBorderColor),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2E000000),
                offset: Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(24),
            child: Center(
              child: Text(
                'Unlock for ₹1',
                style: tokenTextStyles.subscriptionCtaLabel.copyWith(
                  color: contentColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeeAllPlansButton extends ConsumerWidget {
  const _SeeAllPlansButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secondaryColor = _MembershipTokenScope.of(context).secondaryColor;
    final tokenTextStyles = AppTokenTextStyles.of(ref);

    return Center(
      child: Semantics(
        button: true,
        child: InkWell(
          key: const ValueKey('membershipSeeAllPlansButton'),
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              'See All Plans',
              style: tokenTextStyles.subscriptionPlanLabel.copyWith(
                color: secondaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

abstract final class _MembershipLayout {
  static const designWidth = 390.0;
  static const designHeight = 868.0;
  static const headerHeight = 56.0;

  static const sideArtworkLeft = -71.0;
  static const sideArtworkTop = 154.0;

  static const mascotLeft = 136.0;
  static const mascotTop = 98.0;
  static const mascotWidth = 116.614;
  static const mascotHeight = 152.0;

  static const offerTop = 270.0;
  static const benefitsTop = 538.0;

  static const benefitCardWidth = 106.154;
  static const benefitGap = 16.985;

  static const ctaLeft = 16.0;
  static const ctaWidth = 358.0;
  static const ctaHeight = 52.0;
  static const ctaGap = 123.0;
  static const plansGap = 49.0;
}

abstract final class _MembershipColors {
  static const headerOverlay = AppColors.backgroundGradientStart;
  static const glass = Color(0x2EFFFFFF);
  static const glassBorder = Color(0x66FFFFFF);
}

abstract final class _MembershipSystemUi {
  static const style = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: Colors.transparent,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
  );
}
