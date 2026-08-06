import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import 'membership_side_banner.dart';
import 'membership_verification_screen.dart';

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

  void _continue(BuildContext context) {
    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(_selectedPlan);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MembershipVerificationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withNoTextScaling(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: _PlansSystemUi.style,
        child: Scaffold(
          backgroundColor: _PlansColors.topBlue,
          body: SafeArea(
            left: false,
            right: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final contentWidth = constraints.maxWidth;
                final scale = contentWidth / _PlansLayout.designWidth;
                final canvasHeight = math.max(
                  constraints.maxHeight / scale,
                  _PlansLayout.designHeight,
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
                              width: _PlansLayout.designWidth,
                              height: canvasHeight,
                              child: ClipRect(
                                child: Stack(
                                  clipBehavior: Clip.hardEdge,
                                  children: [
                                    const Positioned.fill(
                                      child: _PlansBackground(),
                                    ),
                                    const _PlansArtwork(),
                                    const Positioned(
                                      top: _PlansLayout.heroGroupTop,
                                      left: 0,
                                      right: 0,
                                      child: _PlansHeroCopy(),
                                    ),
                                    const Positioned(
                                      top: _PlansLayout.benefitsTop,
                                      left: 0,
                                      right: 0,
                                      child: _MembershipBenefits(),
                                    ),
                                    Positioned(
                                      top: _PlansLayout.planSelectorTop,
                                      left: _PlansLayout.planSelectorLeft,
                                      child: _PlanSelector(
                                        selectedPlan: _selectedPlan,
                                        onSelected: _selectPlan,
                                        onPromoCode:
                                            widget.onPromoCode ?? () {},
                                      ),
                                    ),
                                    Positioned(
                                      top: canvasHeight - _PlansLayout.ctaGap,
                                      left: _PlansLayout.ctaLeft,
                                      child: _SubscribeButton(
                                        plan: _selectedPlan,
                                        onPressed: () => _continue(context),
                                      ),
                                    ),
                                    Positioned(
                                      top: canvasHeight - _PlansLayout.trustGap,
                                      left: 0,
                                      right: 0,
                                      child: const _TrustIndicators(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: _PlansHeader(),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PlansBackground extends StatelessWidget {
  const _PlansBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _PlansColors.topBlue,
            _PlansColors.midBlue,
            _PlansColors.bottomBlue,
          ],
          stops: [0, 0.54, 1],
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
      color: _PlansColors.headerOverlay,
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
                  color: AppColors.textOnPrimary,
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
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlansArtwork extends StatelessWidget {
  const _PlansArtwork();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: _PlansLayout.sideArtworkLeft,
            top: _PlansLayout.sideArtworkTop,
            child: const MembershipSideBanner(),
          ),
        ],
      ),
    );
  }
}

class _PlansHeroCopy extends StatelessWidget {
  const _PlansHeroCopy();

  @override
  Widget build(BuildContext context) {
    final mascotUrl = _membershipMascotUrl();

    return Column(
      key: const ValueKey('membershipPlansIntro'),
      mainAxisSize: MainAxisSize.min,
      children: [
        mascotUrl == null
            ? const SizedBox(
                key: ValueKey('membershipPlansHero'),
                width: _PlansLayout.mascotWidth,
                height: _PlansLayout.mascotHeight,
              )
            : Image.network(
                mascotUrl,
                key: const ValueKey('membershipPlansHero'),
                width: _PlansLayout.mascotWidth,
                height: _PlansLayout.mascotHeight,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  width: _PlansLayout.mascotWidth,
                  height: _PlansLayout.mascotHeight,
                ),
              ),
        const SizedBox(height: 20),
        const _PlusMemberBadge(),
        const SizedBox(height: 12),
        const Text(
          'Unlock the Magic',
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
          style: _PlansTextStyles.heroTitle,
        ),
        const SizedBox(height: 8),
        const Text(
          'Unlimited stories to inspire, learn, and dream.',
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
          style: _PlansTextStyles.heroSubtitle,
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

class _PlusMemberBadge extends StatelessWidget {
  const _PlusMemberBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _PlansColors.glass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _PlansColors.glassBorder),
      ),
      child: const Text('PLUS MEMBER', style: _PlansTextStyles.badge),
    );
  }
}

class _MembershipBenefits extends StatelessWidget {
  const _MembershipBenefits();

  static const _benefits = [
    _BenefitData(
      label: 'New\nReleases',
      iconAsset: 'assets/icons/membership/new_releases.svg',
    ),
    _BenefitData(
      label: 'Offline\nListening',
      iconAsset: 'assets/icons/membership/offline_listening.svg',
    ),
    _BenefitData(
      label: 'Ad-Free\nAccess',
      iconAsset: 'assets/icons/membership/Ad-free_access.svg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Your Membership Includes',
          key: ValueKey('membershipPlansBenefits'),
          textAlign: TextAlign.center,
          style: _PlansTextStyles.benefitsHeading,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < _benefits.length; index += 1) ...[
              _BenefitCard(data: _benefits[index]),
              if (index < _benefits.length - 1)
                const SizedBox(width: _PlansLayout.benefitGap),
            ],
          ],
        ),
      ],
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({required this.data});

  final _BenefitData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _PlansLayout.benefitCardWidth,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _PlansColors.glass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _PlansColors.glassBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 2),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            data.iconAsset,
            width: 32,
            height: 32,
            colorFilter: const ColorFilter.mode(
              AppColors.textOnPrimary,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.label,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: _PlansTextStyles.benefitLabel,
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

class _PlanSelector extends StatelessWidget {
  const _PlanSelector({
    required this.selectedPlan,
    required this.onSelected,
    required this.onPromoCode,
  });

  final MembershipPlan selectedPlan;
  final ValueChanged<MembershipPlan> onSelected;
  final VoidCallback onPromoCode;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _PlansLayout.planSelectorWidth,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PlanOptionCard(
                semanticKey: const ValueKey('monthlyPlanCard'),
                label: 'Monthly',
                price: '\u20B9149/month',
                semanticPrice: '149 rupees per month',
                selected: selectedPlan == MembershipPlan.monthly,
                onTap: () => onSelected(MembershipPlan.monthly),
              ),
              _PlanOptionCard(
                semanticKey: const ValueKey('annualPlanCard'),
                label: 'Annually',
                price: '\u20B9999/year',
                semanticPrice: '999 rupees per year',
                selected: selectedPlan == MembershipPlan.annual,
                onTap: () => onSelected(MembershipPlan.annual),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _PromoCodeAction(onPressed: onPromoCode),
        ],
      ),
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
          width: _PlansLayout.planCardWidth,
          height: _PlansLayout.planCardHeight,
          decoration: BoxDecoration(
            color: _PlansColors.glass,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? _PlansColors.selectedBorder : _PlansColors.glassBorder,
            ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PlanTextLine(text: label, style: _PlansTextStyles.planLabel),
                      const SizedBox(height: 4),
                      _PlanTextLine(text: price, style: _PlansTextStyles.planPrice),
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

class _PlanTextLine extends StatelessWidget {
  const _PlanTextLine({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _PlansLayout.planTextWidth,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: style,
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
    if (!selected) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _PlansColors.glassBorder, width: 2),
        ),
      );
    }

    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: AppColors.textOnPrimary,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_rounded,
        color: AppColors.blue500,
        size: 18,
        applyTextScaling: false,
      ),
    );
  }
}

class _PromoCodeAction extends StatelessWidget {
  const _PromoCodeAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        key: const ValueKey('membershipPromoCodeButton'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: const SizedBox(
          height: _PlansLayout.minimumTouchTarget,
          child: Center(
            child: Text(
              'Have a promo code?',
              key: ValueKey('membershipPromoCodeText'),
              style: _PlansTextStyles.promo,
            ),
          ),
        ),
      ),
    );
  }
}

class _SubscribeButton extends StatelessWidget {
  const _SubscribeButton({required this.plan, required this.onPressed});

  final MembershipPlan plan;
  final VoidCallback onPressed;

  String get _label => switch (plan) {
    MembershipPlan.monthly => 'Subscribe Monthly',
    MembershipPlan.annual => 'Subscribe Yearly',
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
          width: _PlansLayout.ctaWidth,
          height: _PlansLayout.ctaHeight,
          decoration: BoxDecoration(
            color: _PlansColors.glass,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _PlansColors.glassBorder),
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
              child: Text(_label, style: _PlansTextStyles.cta),
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
    return const SizedBox(
      key: ValueKey('membershipTrustIndicators'),
      height: _PlansLayout.trustHeight,
      child: Center(
        child: SizedBox(
          width: _PlansLayout.trustWidth,
          height: _PlansLayout.trustHeight,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TrustIndicator(
                  iconAsset: 'assets/icons/membership/secure.svg',
                  iconWidth: 10.5,
                  iconHeight: 14,
                  label: 'Secure Payment',
                ),
                SizedBox(width: 24),
                _TrustIndicator(
                  iconAsset: 'assets/icons/membership/cancel.svg',
                  iconWidth: 13.417,
                  iconHeight: 14,
                  label: 'Cancel anytime',
                ),
                SizedBox(width: 24),
                _TrustIndicator(
                  iconAsset: 'assets/icons/membership/family.svg',
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
        SvgPicture.asset(
          iconAsset,
          width: iconWidth,
          height: iconHeight,
          colorFilter: const ColorFilter.mode(
            AppColors.textOnPrimary,
            BlendMode.srcIn,
          ),
        ),
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
            color: _PlansColors.textSecondaryOpacity,
          ),
        ),
      ],
    );
  }
}

abstract final class _PlansLayout {
  static const designWidth = 390.0;
  static const designHeight = 868.0;
  static const headerHeight = 56.0;

  static const sideArtworkLeft = -71.0;
  static const sideArtworkTop = 154.0;

  static const heroGroupTop = 98.0;
  static const mascotWidth = 116.614;
  static const mascotHeight = 152.0;

  static const benefitsTop = 415.0;
  static const benefitCardWidth = 100.0;
  static const benefitGap = 16.0;

  static const planSelectorTop = 597.0;
  static const planSelectorLeft = 15.0;
  static const planSelectorWidth = 354.0;
  static const planCardWidth = 171.0;
  static const planCardHeight = 68.0;
  static const planTextWidth = 93.0;
  static const minimumTouchTarget = 44.0;

  static const ctaLeft = 16.0;
  static const ctaWidth = 358.0;
  static const ctaHeight = 52.0;
  static const ctaGap = 117.0;
  static const trustGap = 45.0;
  static const trustWidth = 325.339;
  static const trustHeight = 14.0;
}

abstract final class _PlansColors {
  static const topBlue = Color(0xFF49A7F4);
  static const midBlue = Color(0xFF2D86EA);
  static const bottomBlue = Color(0xFF0F4E9B);
  static const headerOverlay = Color(0xFF49A7F4);
  static const glass = Color(0x2EFFFFFF);
  static const glassBorder = Color(0x66FFFFFF);
  static const selectedBorder = Color(0xFF99E1FA);
  static const textSecondaryOpacity = Color(0xD9FFFFFF);
}

abstract final class _PlansSystemUi {
  static const style = SystemUiOverlayStyle(
    statusBarColor: _PlansColors.topBlue,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: _PlansColors.bottomBlue,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: Colors.transparent,
  );
}

abstract final class _PlansTextStyles {
  static const badge = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    height: 16 / 14,
    letterSpacing: 0.2,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
  );

  static const heroTitle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 24,
    height: 28 / 24,
    letterSpacing: -0.25,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
  );

  static const heroSubtitle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    color: _PlansColors.textSecondaryOpacity,
  );

  static const benefitsHeading = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 18,
    height: 20 / 18,
    fontWeight: FontWeight.w700,
    color: _PlansColors.textSecondaryOpacity,
  );

  static const benefitLabel = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );

  static const planLabel = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textOnPrimary,
  );

  static const planPrice = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 16,
    height: 20 / 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );

  static const promo = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );

  static const cta = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 16,
    height: 20 / 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
  );
}
