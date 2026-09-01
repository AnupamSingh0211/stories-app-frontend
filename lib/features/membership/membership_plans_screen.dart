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
import 'membership_side_banner.dart';
import 'membership_verification_screen.dart';

enum MembershipPlan { monthly, annual }

class MembershipPlansScreen extends ConsumerStatefulWidget {
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
  ConsumerState<MembershipPlansScreen> createState() =>
      _MembershipPlansScreenState();
}

class _MembershipPlansScreenState extends ConsumerState<MembershipPlansScreen> {
  late MembershipPlan _selectedPlan;

  @override
  void initState() {
    super.initState();
    _selectedPlan = widget.initialPlan;
    unawaited(
      PostHogAnalytics.instance.screenOpened(
        'subscription_page',
        properties: {
          'source': 'membership_screen',
          'subscription_plan_id': _selectedPlan.name,
        },
      ),
    );
    unawaited(
      PostHogAnalytics.instance.capture(
        'subscription_page_viewed',
        properties: {
          'screen_name': 'subscription_page',
          'source': 'membership_screen',
          'subscription_plan_id': _selectedPlan.name,
        },
      ),
    );
  }

  void _selectPlan(MembershipPlan plan) {
    if (_selectedPlan == plan) return;
    unawaited(
      PostHogAnalytics.instance.buttonClicked(
        buttonName: 'select_subscription_plan',
        screenName: 'subscription_page',
        properties: {
          'source': 'plan_selector',
          'subscription_plan_id': plan.name,
        },
      ),
    );
    setState(() => _selectedPlan = plan);
  }

  void _continue(BuildContext context) {
    unawaited(
      PostHogAnalytics.instance.capture(
        'subscription_started',
        properties: {
          'screen_name': 'subscription_page',
          'source': 'subscription_continue',
          'subscription_plan_id': _selectedPlan.name,
        },
      ),
    );
    unawaited(
      PostHogAnalytics.instance.buttonClicked(
        buttonName: 'continue_subscription',
        screenName: 'subscription_page',
        properties: {
          'source': 'subscription_continue',
          'subscription_plan_id': _selectedPlan.name,
        },
      ),
    );
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
    final tokenColors = AppTokenColors.of(ref);
    final contentColor = tokenColors.homeCardTextPrimary;

    return MediaQuery.withNoTextScaling(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: _PlansSystemUi.style,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: AppScreenBackground(
            child: _PlansTokenScope(
              contentColor: contentColor,
              cardBackgroundColor: tokenColors.subscriptionCardBackground,
              cardBorderColor: tokenColors.subscriptionCardBorder,
              ctaBackgroundColor: tokenColors.subscriptionCtaBackground,
              ctaBorderColor: tokenColors.subscriptionCtaBorder,
              selectedBorderColor: tokenColors.subscriptionPlanSelectedBorder,
              unselectedBorderColor:
                  tokenColors.subscriptionPlanUnselectedBorder,
              radioSelectedFillColor:
                  tokenColors.subscriptionPlanRadioSelectedFill,
              radioCheckColor: tokenColors.subscriptionPlanRadioCheck,
              radioUnselectedBorderColor:
                  tokenColors.subscriptionPlanRadioUnselectedBorder,
              child: Stack(
                children: [
                  SafeArea(
                    left: false,
                    right: false,
                    bottom: false,
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
                                              left:
                                                  _PlansLayout.planSelectorLeft,
                                              child: _PlanSelector(
                                                selectedPlan: _selectedPlan,
                                                onSelected: _selectPlan,
                                                onPromoCode:
                                                    widget.onPromoCode ?? () {},
                                              ),
                                            ),
                                            Positioned(
                                              top:
                                                  canvasHeight -
                                                  _PlansLayout.ctaGap,
                                              left: _PlansLayout.ctaLeft,
                                              child: _SubscribeButton(
                                                plan: _selectedPlan,
                                                onPressed: () =>
                                                    _continue(context),
                                              ),
                                            ),
                                            Positioned(
                                              top:
                                                  canvasHeight -
                                                  _PlansLayout.trustGap,
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
                          ],
                        );
                      },
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: _PlansHeader(),
                  ),
                ],
              ),
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
    return const SizedBox.expand();
  }
}

class _PlansTokenScope extends InheritedWidget {
  const _PlansTokenScope({
    required this.contentColor,
    required this.cardBackgroundColor,
    required this.cardBorderColor,
    required this.ctaBackgroundColor,
    required this.ctaBorderColor,
    required this.selectedBorderColor,
    required this.unselectedBorderColor,
    required this.radioSelectedFillColor,
    required this.radioCheckColor,
    required this.radioUnselectedBorderColor,
    required super.child,
  });

  final Color contentColor;
  final Color cardBackgroundColor;
  final Color cardBorderColor;
  final Color ctaBackgroundColor;
  final Color ctaBorderColor;
  final Color selectedBorderColor;
  final Color unselectedBorderColor;
  final Color radioSelectedFillColor;
  final Color radioCheckColor;
  final Color radioUnselectedBorderColor;

  Color get secondaryColor => contentColor.withAlpha(217);

  static _PlansTokenScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_PlansTokenScope>() ??
        const _PlansTokenScope(
          contentColor: AppColors.textOnPrimary,
          cardBackgroundColor: _PlansColors.glass,
          cardBorderColor: _PlansColors.glassBorder,
          ctaBackgroundColor: _PlansColors.glass,
          ctaBorderColor: _PlansColors.glassBorder,
          selectedBorderColor: _PlansColors.selectedBorder,
          unselectedBorderColor: _PlansColors.glassBorder,
          radioSelectedFillColor: AppColors.textOnPrimary,
          radioCheckColor: AppColors.blue500,
          radioUnselectedBorderColor: _PlansColors.glassBorder,
          child: SizedBox.shrink(),
        );
  }

  @override
  bool updateShouldNotify(_PlansTokenScope oldWidget) {
    return contentColor != oldWidget.contentColor ||
        cardBackgroundColor != oldWidget.cardBackgroundColor ||
        cardBorderColor != oldWidget.cardBorderColor ||
        ctaBackgroundColor != oldWidget.ctaBackgroundColor ||
        ctaBorderColor != oldWidget.ctaBorderColor ||
        selectedBorderColor != oldWidget.selectedBorderColor ||
        unselectedBorderColor != oldWidget.unselectedBorderColor ||
        radioSelectedFillColor != oldWidget.radioSelectedFillColor ||
        radioCheckColor != oldWidget.radioCheckColor ||
        radioUnselectedBorderColor != oldWidget.radioUnselectedBorderColor;
  }
}

class _PlansHeader extends StatelessWidget {
  const _PlansHeader();

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final contentColor = _PlansTokenScope.of(context).contentColor;

    return Container(
      height: statusBarHeight + _PlansLayout.headerHeight,
      color: _PlansColors.headerOverlay,
      padding: EdgeInsets.only(top: statusBarHeight),
      child: SizedBox(
        height: _PlansLayout.headerHeight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: 'Back',
                child: InkResponse(
                  key: const ValueKey('membershipPlansBackButton'),
                  onTap: () {
                    unawaited(
                      PostHogAnalytics.instance.capture(
                        'back_clicked',
                        properties: {
                          'screen_name': 'subscription_page',
                          'source': 'subscription_header',
                        },
                      ),
                    );
                    unawaited(
                      PostHogAnalytics.instance.buttonClicked(
                        buttonName: 'back',
                        screenName: 'subscription_page',
                        properties: {'source': 'subscription_header'},
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

class _PlansHeroCopy extends ConsumerWidget {
  const _PlansHeroCopy();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mascotUrl = _membershipMascotUrl();
    final tokenScope = _PlansTokenScope.of(context);
    final tokenTextStyles = AppTokenTextStyles.of(ref);

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
        Text(
          'Unlock the Magic',
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
          style: tokenTextStyles.subscriptionHeroTitle.copyWith(
            color: tokenScope.contentColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Unlimited stories to inspire, learn, and dream.',
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

class _PlusMemberBadge extends ConsumerWidget {
  const _PlusMemberBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenScope = _PlansTokenScope.of(context);
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
    final tokenScope = _PlansTokenScope.of(context);
    final tokenTextStyles = AppTokenTextStyles.of(ref);

    return Column(
      children: [
        Text(
          'Your Membership Includes',
          key: ValueKey('membershipPlansBenefits'),
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
                const SizedBox(width: _PlansLayout.benefitGap),
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
    final tokenScope = _PlansTokenScope.of(context);
    final contentColor = tokenScope.contentColor;
    final tokenTextStyles = AppTokenTextStyles.of(ref);

    return Container(
      width: _PlansLayout.benefitCardWidth,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokenScope.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokenScope.cardBorderColor),
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
            colorFilter: ColorFilter.mode(contentColor, BlendMode.srcIn),
          ),
          const SizedBox(height: 4),
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

class _PlanOptionCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenScope = _PlansTokenScope.of(context);
    final contentColor = tokenScope.contentColor;
    final tokenTextStyles = AppTokenTextStyles.of(ref);

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
            color: tokenScope.cardBackgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? tokenScope.selectedBorderColor
                  : tokenScope.unselectedBorderColor,
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
                      _PlanTextLine(
                        text: label,
                        style: tokenTextStyles.subscriptionPlanLabel.copyWith(
                          color: contentColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _PlanTextLine(
                        text: price,
                        style: tokenTextStyles.subscriptionPlanPrice.copyWith(
                          color: contentColor,
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
        child: Text(text, maxLines: 1, softWrap: false, style: style),
      ),
    );
  }
}

class _PlanRadio extends StatelessWidget {
  const _PlanRadio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tokenScope = _PlansTokenScope.of(context);

    if (!selected) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: tokenScope.radioUnselectedBorderColor,
            width: 2,
          ),
        ),
      );
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: tokenScope.radioSelectedFillColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check_rounded,
        color: tokenScope.radioCheckColor,
        size: 18,
        applyTextScaling: false,
      ),
    );
  }
}

class _PromoCodeAction extends ConsumerWidget {
  const _PromoCodeAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenScope = _PlansTokenScope.of(context);
    final contentColor = tokenScope.contentColor;
    final tokenTextStyles = AppTokenTextStyles.of(ref);

    return Semantics(
      button: true,
      child: InkWell(
        key: const ValueKey('membershipPromoCodeButton'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: _PlansLayout.minimumTouchTarget,
          child: Center(
            child: Text(
              'Have a promo code?',
              key: const ValueKey('membershipPromoCodeText'),
              style: tokenTextStyles.subscriptionPlanLabel.copyWith(
                color: contentColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubscribeButton extends ConsumerWidget {
  const _SubscribeButton({required this.plan, required this.onPressed});

  final MembershipPlan plan;
  final VoidCallback onPressed;

  String get _label => switch (plan) {
    MembershipPlan.monthly => 'Subscribe Monthly',
    MembershipPlan.annual => 'Subscribe Yearly',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenScope = _PlansTokenScope.of(context);
    final contentColor = tokenScope.contentColor;
    final tokenTextStyles = AppTokenTextStyles.of(ref);

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
                _label,
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

class _TrustIndicators extends StatelessWidget {
  const _TrustIndicators();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
                const _TrustIndicator(
                  iconAsset:
                      'assets/icons/new_boopi/State=Default, Icon=Shield Done.svg',
                  iconWidth: 10.5,
                  iconHeight: 14,
                  label: 'Secure Payment',
                ),
                const SizedBox(width: 24),
                const _TrustIndicator(
                  iconAsset:
                      'assets/icons/new_boopi/State=Default, Icon=Close Square.svg',
                  iconWidth: 13.417,
                  iconHeight: 14,
                  label: 'Cancel anytime',
                ),
                const SizedBox(width: 24),
                const _TrustIndicator(
                  iconAsset:
                      'assets/icons/new_boopi/State=Default, Icon=3 User.svg',
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
    final tokenScope = _PlansTokenScope.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          iconAsset,
          width: iconWidth,
          height: iconHeight,
          colorFilter: ColorFilter.mode(
            tokenScope.contentColor,
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
            color: tokenScope.secondaryColor,
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
  static const headerOverlay = AppColors.backgroundGradientStart;
  static const glass = Color(0x2EFFFFFF);
  static const glassBorder = Color(0x66FFFFFF);
  static const selectedBorder = Color(0xFF99E1FA);
}

abstract final class _PlansSystemUi {
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
