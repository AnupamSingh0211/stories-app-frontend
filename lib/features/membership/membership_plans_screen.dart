import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../auth/assets_provider.dart';
import 'membership_benefits.dart';

enum MembershipPlan { monthly, annual }

class MembershipPlansScreen extends StatefulWidget {
  const MembershipPlansScreen({
    super.key,
    this.initialPlan = MembershipPlan.monthly,
    this.onContinue,
    this.onPromoCode,
  });

  final MembershipPlan initialPlan;
  final ValueChanged<MembershipPlan>? onContinue;
  final VoidCallback? onPromoCode;

  @override
  State<MembershipPlansScreen> createState() => _MembershipPlansScreenState();
}

class _MembershipPlansScreenState extends State<MembershipPlansScreen> {
  late MembershipPlan _selectedPlan;

  @override
  void initState() {
    super.initState();
    _selectedPlan = widget.initialPlan;
  }

  void _selectPlan(MembershipPlan plan) {
    if (_selectedPlan == plan) return;
    setState(() => _selectedPlan = plan);
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withNoTextScaling(
      child: Scaffold(
        backgroundColor: _PlansColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = math.min(
                constraints.maxWidth,
                _PlansLayout.maxContentWidth,
              );
              final canvasHeight = math.max(
                constraints.maxHeight,
                _PlansLayout.minimumCanvasHeight,
              );
              final continueTop =
                  canvasHeight - _PlansLayout.continueBottomOffset;
              final trustTop = canvasHeight - _PlansLayout.trustBottomOffset;
              final promoTextTop = math.max(
                _PlansLayout.minimumPromoTextTop,
                continueTop - _PlansLayout.promoToContinueOffset,
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
                          const _PlanHero(),
                          const _PlansHeader(),
                          const Positioned(
                            top: _PlansLayout.introTop,
                            left: 12,
                            right: 12,
                            child: _PlansIntro(),
                          ),
                          const Positioned(
                            top: _PlansLayout.benefitsTop,
                            left: 0,
                            right: 0,
                            child: MembershipBenefitsStrip(
                              key: ValueKey('membershipPlansBenefits'),
                              heading: "Everything You'll Unlock",
                              headingGap: 12,
                            ),
                          ),
                          Positioned(
                            top: _PlansLayout.monthlyTop,
                            left: _PlansLayout.planHorizontalMargin,
                            right: _PlansLayout.planHorizontalMargin,
                            child: Transform.translate(
                              offset: const Offset(
                                _PlansLayout.planCenterOffset,
                                0,
                              ),
                              child: _PlanOptionCard(
                                semanticKey: const ValueKey('monthlyPlanCard'),
                                label: 'Monthly',
                                price: '₹149/month',
                                semanticPrice: '149 rupees per month',
                                selected:
                                    _selectedPlan == MembershipPlan.monthly,
                                onTap: () =>
                                    _selectPlan(MembershipPlan.monthly),
                              ),
                            ),
                          ),
                          Positioned(
                            top: _PlansLayout.annualTop,
                            left: _PlansLayout.planHorizontalMargin,
                            right: _PlansLayout.planHorizontalMargin,
                            child: Transform.translate(
                              offset: const Offset(
                                _PlansLayout.planCenterOffset,
                                0,
                              ),
                              child: _PlanOptionCard(
                                semanticKey: const ValueKey('annualPlanCard'),
                                label: 'Annually',
                                price: '₹999/year',
                                semanticPrice: '999 rupees per year',
                                selected:
                                    _selectedPlan == MembershipPlan.annual,
                                onTap: () => _selectPlan(MembershipPlan.annual),
                              ),
                            ),
                          ),
                          Positioned(
                            top:
                                promoTextTop -
                                _PlansLayout.promoTouchVerticalInset,
                            left: 0,
                            right: 0,
                            child: _PromoCodeAction(
                              onPressed: widget.onPromoCode ?? () {},
                            ),
                          ),
                          Positioned(
                            top: continueTop,
                            left: _PlansLayout.continueHorizontalMargin,
                            right: _PlansLayout.continueHorizontalMargin,
                            child: _ContinueButton(
                              plan: _selectedPlan,
                              onPressed: () =>
                                  widget.onContinue?.call(_selectedPlan),
                            ),
                          ),
                          Positioned(
                            top: trustTop,
                            left: 16,
                            right: 16,
                            child: const _TrustIndicators(),
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

class _PlansHeader extends StatelessWidget {
  const _PlansHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _PlansLayout.headerHeight,
      color: _PlansColors.background,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Back',
            child: InkResponse(
              key: const ValueKey('membershipPlansBackButton'),
              onTap: () => Navigator.of(context).maybePop(),
              radius: 24,
              child: const SizedBox.square(
                dimension: 24,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: _PlansColors.indigo800,
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
                  color: _PlansColors.indigo800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlansIntro extends StatelessWidget {
  const _PlansIntro();

  @override
  Widget build(BuildContext context) {
    return const Column(
      key: ValueKey('membershipPlansIntro'),
      children: [
        Text(
          'Unlock the Magic',
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 28,
            height: 32 / 28,
            letterSpacing: -0.5,
            fontWeight: FontWeight.w700,
            color: AppColors.blue800,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Unlimited stories to inspire, learn, and dream.',
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w600,
            color: AppColors.gray500,
          ),
        ),
      ],
    );
  }
}

class _PlanHero extends StatelessWidget {
  const _PlanHero();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final left =
            (constraints.maxWidth / 2) +
            _PlansLayout.heroCenterOffset -
            (_PlansLayout.heroWidth / 2);

        return Stack(
          children: [
            Positioned(
              left: left,
              top: _PlansLayout.heroTop,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_PlansLayout.heroRadius),
                child: Image.asset(
                  membershipHeroImageAsset,
                  key: const ValueKey('membershipPlansHero'),
                  width: _PlansLayout.heroWidth,
                  height: _PlansLayout.heroHeight,
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

class _PlanOptionCard extends StatelessWidget {
  const _PlanOptionCard({
    required this.label,
    required this.price,
    required this.semanticPrice,
    required this.semanticKey,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String price;
  final String semanticPrice;
  final Key semanticKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? AppColors.blue200 : AppColors.blue50;

    return Semantics(
      key: semanticKey,
      container: true,
      button: true,
      selected: selected,
      label: '$label plan, $semanticPrice',
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: _PlansLayout.planCardHeight,
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                offset: Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            excludeFromSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w400,
                          color: _PlansColors.indigo800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 16,
                          height: 20 / 16,
                          fontWeight: FontWeight.w600,
                          color: _PlansColors.indigo800,
                        ),
                      ),
                    ],
                  ),
                  _PlanRadio(selected: selected),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanRadio extends StatelessWidget {
  const _PlanRadio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: selected ? AppColors.blue500 : AppColors.transparent,
        shape: BoxShape.circle,
        border: selected
            ? null
            : Border.all(color: AppColors.gray600, width: 2),
      ),
    );
  }
}

class _PromoCodeAction extends StatelessWidget {
  const _PromoCodeAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        button: true,
        child: InkWell(
          key: const ValueKey('membershipPromoCodeButton'),
          onTap: onPressed,
          borderRadius: BorderRadius.circular(22),
          child: const SizedBox(
            height: _PlansLayout.minimumTouchTarget,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text(
                  'Have a promo code?',
                  key: ValueKey('membershipPromoCodeText'),
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w600,
                    color: _PlansColors.indigo800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.plan, required this.onPressed});

  final MembershipPlan plan;
  final VoidCallback onPressed;

  String get _label => switch (plan) {
    MembershipPlan.monthly => 'Continue with Monthly',
    MembershipPlan.annual => 'Continue with Annually',
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('membershipPlansContinueButton'),
      button: true,
      label: _label,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: _PlansLayout.continueHeight,
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
            child: Center(
              child: Text(
                _label,
                style: const TextStyle(
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

class _TrustIndicators extends StatelessWidget {
  const _TrustIndicators();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('membershipTrustIndicators'),
      height: _PlansLayout.trustHeight,
      child: Center(
        child: SizedBox(
          width: _PlansLayout.trustWidth,
          height: _PlansLayout.trustHeight,
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TrustIndicator(
                  iconAsset: 'assets/icons/membership/secure_payment.svg',
                  iconWidth: 10.5,
                  iconHeight: 14,
                  label: 'Secure Payment',
                ),
                SizedBox(width: 24),
                _TrustIndicator(
                  iconAsset: 'assets/icons/membership/cancel_anytime.svg',
                  iconWidth: 13.417,
                  iconHeight: 14,
                  label: 'Cancel anytime',
                ),
                SizedBox(width: 24),
                _TrustIndicator(
                  iconAsset: 'assets/icons/membership/family_friendly.svg',
                  iconWidth: 13.089,
                  iconHeight: 11.941,
                  iconGap: 4.333,
                  label: 'Family Friendly',
                  fontSize: 10.833,
                  lineHeight: 13,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustIndicator extends StatelessWidget {
  const _TrustIndicator({
    required this.iconAsset,
    required this.iconWidth,
    required this.iconHeight,
    required this.label,
    this.iconGap = 4,
    this.fontSize = 10,
    this.lineHeight = 12,
  });

  final String iconAsset;
  final double iconWidth;
  final double iconHeight;
  final double iconGap;
  final String label;
  final double fontSize;
  final double lineHeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(iconAsset, width: iconWidth, height: iconHeight),
        SizedBox(width: iconGap),
        Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: fontSize,
            height: lineHeight / fontSize,
            fontWeight: FontWeight.w400,
            color: _PlansColors.indigo800,
          ),
        ),
      ],
    );
  }
}

abstract final class _PlansLayout {
  static const maxContentWidth = 600.0;
  static const minimumCanvasHeight = 817.0;
  static const headerHeight = 56.0;
  static const introTop = 63.0;

  static const heroTop = 135.0;
  static const heroWidth = 209.567;
  static const heroHeight = 176.0;
  static const heroCenterOffset = 1.7835;
  static const heroRadius = 14.515;

  static const benefitsTop = 327.0;

  static const planHorizontalMargin = 20.0;
  static const planCenterOffset = 2.0;
  static const planCardHeight = 70.0;
  static const monthlyTop = 485.0;
  static const annualTop = 571.0;

  static const minimumPromoTextTop = 663.0;
  static const promoTouchVerticalInset = 12.0;
  static const promoToContinueOffset = 67.0;
  static const minimumTouchTarget = 44.0;

  static const continueHorizontalMargin = 20.0;
  static const continueBottomOffset = 114.0;
  static const continueHeight = 52.0;

  static const trustBottomOffset = 43.0;
  static const trustWidth = 325.339;
  static const trustHeight = 14.0;
}

abstract final class _PlansColors {
  static const background = AppColors.blue25;
  static const indigo800 = Color(0xFF001033);
}
