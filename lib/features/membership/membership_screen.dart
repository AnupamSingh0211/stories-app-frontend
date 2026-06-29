import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../auth/assets_provider.dart';
import 'membership_benefits.dart';
import 'membership_plans_screen.dart';

class MembershipScreen extends StatelessWidget {
  const MembershipScreen({super.key, this.onUnlock, this.onSeeAllPlans});

  final VoidCallback? onUnlock;
  final VoidCallback? onSeeAllPlans;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withNoTextScaling(
      child: Scaffold(
        backgroundColor: _MembershipColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = math.min(
                constraints.maxWidth,
                _MembershipLayout.maxContentWidth,
              );
              final canvasHeight = math.max(
                constraints.maxHeight,
                _MembershipLayout.minimumCanvasHeight,
              );
              final ctaTop = canvasHeight - _MembershipLayout.ctaBottomOffset;
              final benefitsTop = math.max(
                _MembershipLayout.minimumBenefitsTop,
                ctaTop - _MembershipLayout.benefitsToCtaOffset,
              );

              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Center(
                  child: SizedBox(
                    width: contentWidth,
                    height: canvasHeight,
                    child: ClipRect(
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          const _HeroArtwork(),
                          const _MembershipHeader(),
                          const Positioned(
                            top: _MembershipLayout.offerTop,
                            left: 0,
                            right: 0,
                            child: _OfferDetails(),
                          ),
                          Positioned(
                            top: benefitsTop,
                            left: 0,
                            right: 0,
                            child: const MembershipBenefitsStrip(
                              heading: 'Your Membership Includes',
                              headingGap: 16,
                            ),
                          ),
                          Positioned(
                            top: ctaTop,
                            left: _MembershipLayout.horizontalPagePadding,
                            right: _MembershipLayout.horizontalPagePadding,
                            child: _MembershipCta(onPressed: onUnlock ?? () {}),
                          ),
                          Positioned(
                            top:
                                canvasHeight -
                                _MembershipLayout.plansBottomOffset,
                            left: 0,
                            right: 0,
                            child: _SeeAllPlansButton(
                              onPressed:
                                  onSeeAllPlans ??
                                  () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const MembershipPlansScreen(),
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MembershipHeader extends StatelessWidget {
  const _MembershipHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _MembershipLayout.headerHeight,
      color: _MembershipColors.background,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Back',
            child: InkResponse(
              key: const ValueKey('membershipBackButton'),
              onTap: () => Navigator.of(context).maybePop(),
              radius: 24,
              child: const SizedBox.square(
                dimension: 24,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: _MembershipColors.indigo800,
                  size: 24,
                  applyTextScaling: false,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
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
                  color: _MembershipColors.indigo800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroArtwork extends StatelessWidget {
  const _HeroArtwork();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final heroLeft =
            (constraints.maxWidth / 2) +
            _MembershipLayout.heroCenterOffset -
            (_MembershipLayout.heroWidth / 2);

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: _MembershipLayout.sideArtworkLeft,
              top: _MembershipLayout.sideArtworkTop,
              child: SizedBox(
                width: _MembershipLayout.sideArtworkWidth,
                height: _MembershipLayout.sideArtworkHeight,
                child: Image.asset(
                  membershipSideFrameAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.topLeft,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            Positioned(
              left: heroLeft,
              top: _MembershipLayout.heroTop,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  _MembershipLayout.heroRadius,
                ),
                child: Image.asset(
                  membershipHeroImageAsset,
                  key: const ValueKey('membershipHeroImage'),
                  width: _MembershipLayout.heroWidth,
                  height: _MembershipLayout.heroHeight,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OfferDetails extends StatelessWidget {
  const _OfferDetails();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: _MembershipLayout.offerHeight,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          _PlusMemberBadge(),
          Positioned(
            top: 40,
            child: Text(
              'Unlock All Stories',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 20,
                height: 24 / 20,
                letterSpacing: -0.25,
                fontWeight: FontWeight.w700,
                color: AppColors.blue800,
              ),
            ),
          ),
          Positioned(
            top: 84,
            child: Text(
              'Premium Access for 5 Days',
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 24,
                height: 28 / 24,
                letterSpacing: -0.25,
                fontWeight: FontWeight.w700,
                color: _MembershipColors.indigo800,
              ),
            ),
          ),
          Positioned(top: 126, child: _GradientPrice()),
          Positioned(
            top: 213,
            child: Text(
              'Then ₹149/month. Cancel anytime.',
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w600,
                color: _MembershipColors.indigo800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlusMemberBadge extends StatelessWidget {
  const _PlusMemberBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blue500, AppColors.purple700],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blue500),
      ),
      child: const Text(
        'PLUS MEMBER',
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 14,
          height: 16 / 14,
          letterSpacing: 0.2,
          fontWeight: FontWeight.w700,
          color: _MembershipColors.background,
        ),
      ),
    );
  }
}

class _GradientPrice extends StatelessWidget {
  const _GradientPrice();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.blue500, AppColors.purple700],
      ).createShader(bounds),
      child: const Text(
        '₹1',
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 56,
          height: 75 / 56,
          letterSpacing: -0.9375,
          fontWeight: FontWeight.w700,
          color: AppColors.surfaceWhite,
        ),
      ),
    );
  }
}

class _MembershipCta extends StatelessWidget {
  const _MembershipCta({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('membershipUnlockButton'),
      button: true,
      label: 'Unlock membership for ₹1',
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: _MembershipLayout.ctaHeight,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.blue500, AppColors.blue400, AppColors.blue500],
              stops: [0, 0.51442, 1],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.blue600),
            boxShadow: const [
              BoxShadow(
                color: AppColors.blue700,
                offset: Offset(0, 2),
                blurRadius: 2,
              ),
            ],
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(24),
            child: const Center(
              child: Text(
                'Unlock for ₹1',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 16,
                  height: 20 / 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.surfaceWhite,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeeAllPlansButton extends StatelessWidget {
  const _SeeAllPlansButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        button: true,
        child: InkWell(
          key: const ValueKey('membershipSeeAllPlansButton'),
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              'See All Plans',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 16,
                height: 20 / 16,
                fontWeight: FontWeight.w500,
                color: AppColors.gray500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

abstract final class _MembershipLayout {
  static const maxContentWidth = 600.0;
  static const minimumCanvasHeight = 780.0;
  static const headerHeight = 56.0;

  static const sideArtworkLeft = -156.0;
  static const sideArtworkTop = -35.0;
  static const sideArtworkWidth = 403.238;
  static const sideArtworkHeight = 297.154;

  static const heroCenterOffset = 7.7835;
  static const heroTop = 75.0;
  static const heroWidth = 209.567;
  static const heroHeight = 176.0;
  static const heroRadius = 14.515;

  static const offerTop = 270.0;
  static const offerHeight = 233.0;
  static const minimumBenefitsTop = 515.0;
  static const benefitsToCtaOffset = 188.0;
  static const horizontalPagePadding = 20.0;
  static const ctaBottomOffset = 127.0;
  static const ctaHeight = 52.0;
  static const plansBottomOffset = 67.0;
}

abstract final class _MembershipColors {
  static const background = AppColors.blue25;
  static const indigo800 = Color(0xFF001033);
}
