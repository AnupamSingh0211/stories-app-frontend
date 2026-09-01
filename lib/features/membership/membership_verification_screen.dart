import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/analytics_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_tokens.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/widgets/app_screen_background.dart';
import 'membership_side_banner.dart';

class MembershipVerificationScreen extends ConsumerStatefulWidget {
  const MembershipVerificationScreen({super.key});

  @override
  ConsumerState<MembershipVerificationScreen> createState() =>
      _MembershipVerificationScreenState();
}

class _MembershipVerificationScreenState
    extends ConsumerState<MembershipVerificationScreen> {
  final List<String> _digits = [];
  bool _didTrackCompletion = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      PostHogAnalytics.instance.screenOpened(
        'membership_verification_screen',
        properties: {'source': 'subscription_flow'},
      ),
    );
  }

  void _enterDigit(String digit) {
    if (_digits.length == _VerificationLayout.yearLength) return;
    setState(() => _digits.add(digit));
    unawaited(
      PostHogAnalytics.instance.buttonClicked(
        buttonName: 'verification_digit',
        screenName: 'membership_verification_screen',
        properties: {'source': 'parent_gate'},
      ),
    );
    if (_digits.length == _VerificationLayout.yearLength &&
        !_didTrackCompletion) {
      _didTrackCompletion = true;
      unawaited(
        PostHogAnalytics.instance.capture(
          'subscription_completed',
          properties: {
            'screen_name': 'membership_verification_screen',
            'source': 'parent_gate',
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokenColors = AppTokenColors.of(ref);
    final contentColor = tokenColors.homeCardTextPrimary;

    return MediaQuery.withNoTextScaling(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: _VerificationSystemUi.style,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: AppScreenBackground(
            child: _VerificationTokenScope(
              contentColor: contentColor,
              badgeBackgroundColor: tokenColors.subscriptionCardBackground,
              badgeBorderColor: tokenColors.subscriptionCardBorder,
              panelBackgroundColor: tokenColors.subscriptionPanelBackground,
              panelBorderColor: tokenColors.subscriptionPanelBorder,
              controlBackgroundColor: tokenColors.subscriptionControlBackground,
              controlBorderColor: tokenColors.subscriptionControlBorder,
              child: Stack(
                children: [
                  SafeArea(
                    left: false,
                    right: false,
                    bottom: false,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final contentWidth = constraints.maxWidth;
                        final scale =
                            contentWidth / _VerificationLayout.designWidth;
                        final canvasHeight = math.max(
                          constraints.maxHeight / scale,
                          _VerificationLayout.designHeight,
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
                                      width: _VerificationLayout.designWidth,
                                      height: canvasHeight,
                                      child: ClipRect(
                                        child: Stack(
                                          clipBehavior: Clip.hardEdge,
                                          children: [
                                            const Positioned.fill(
                                              child: _VerificationBackground(),
                                            ),
                                            const _VerificationArtwork(),
                                            const Positioned(
                                              top: _VerificationLayout
                                                  .heroGroupTop,
                                              left: 0,
                                              right: 0,
                                              child: _VerificationHeroCopy(),
                                            ),
                                            Positioned(
                                              top: _VerificationLayout.panelTop,
                                              left: 0,
                                              right: 0,
                                              bottom: 0,
                                              child: _VerificationPanel(
                                                digits: _digits,
                                                onDigitPressed: _enterDigit,
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
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: _VerificationHeader(),
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

class _VerificationBackground extends StatelessWidget {
  const _VerificationBackground();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand();
  }
}

class _VerificationTokenScope extends InheritedWidget {
  const _VerificationTokenScope({
    required this.contentColor,
    required this.badgeBackgroundColor,
    required this.badgeBorderColor,
    required this.panelBackgroundColor,
    required this.panelBorderColor,
    required this.controlBackgroundColor,
    required this.controlBorderColor,
    required super.child,
  });

  final Color contentColor;
  final Color badgeBackgroundColor;
  final Color badgeBorderColor;
  final Color panelBackgroundColor;
  final Color panelBorderColor;
  final Color controlBackgroundColor;
  final Color controlBorderColor;

  Color get secondaryColor => contentColor.withAlpha(217);

  static _VerificationTokenScope of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<_VerificationTokenScope>() ??
        const _VerificationTokenScope(
          contentColor: AppColors.textOnPrimary,
          badgeBackgroundColor: _VerificationColors.glass,
          badgeBorderColor: _VerificationColors.glassBorder,
          panelBackgroundColor: _VerificationColors.glass,
          panelBorderColor: _VerificationColors.glassEdge,
          controlBackgroundColor: _VerificationColors.glass,
          controlBorderColor: _VerificationColors.controlEdge,
          child: SizedBox.shrink(),
        );
  }

  @override
  bool updateShouldNotify(_VerificationTokenScope oldWidget) {
    return contentColor != oldWidget.contentColor ||
        badgeBackgroundColor != oldWidget.badgeBackgroundColor ||
        badgeBorderColor != oldWidget.badgeBorderColor ||
        panelBackgroundColor != oldWidget.panelBackgroundColor ||
        panelBorderColor != oldWidget.panelBorderColor ||
        controlBackgroundColor != oldWidget.controlBackgroundColor ||
        controlBorderColor != oldWidget.controlBorderColor;
  }
}

class _VerificationHeader extends StatelessWidget {
  const _VerificationHeader();

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final contentColor = _VerificationTokenScope.of(context).contentColor;

    return Container(
      key: const ValueKey('membershipVerificationHeader'),
      height: statusBarHeight + _VerificationLayout.headerHeight,
      color: _VerificationColors.headerOverlay,
      padding: EdgeInsets.only(top: statusBarHeight),
      child: SizedBox(
        height: _VerificationLayout.headerHeight,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: 'Back',
                child: InkResponse(
                  key: const ValueKey('membershipVerificationBackButton'),
                  onTap: () {
                    unawaited(
                      PostHogAnalytics.instance.capture(
                        'back_clicked',
                        properties: {
                          'screen_name': 'membership_verification_screen',
                          'source': 'verification_header',
                        },
                      ),
                    );
                    unawaited(
                      PostHogAnalytics.instance.buttonClicked(
                        buttonName: 'back',
                        screenName: 'membership_verification_screen',
                        properties: {'source': 'verification_header'},
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

class _VerificationArtwork extends StatelessWidget {
  const _VerificationArtwork();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: _VerificationLayout.sideArtworkLeft,
            top: _VerificationLayout.sideArtworkTop,
            child: const MembershipSideBanner(),
          ),
        ],
      ),
    );
  }
}

class _VerificationHeroCopy extends ConsumerWidget {
  const _VerificationHeroCopy();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mascotUrl = _membershipMascotUrl();
    final tokenScope = _VerificationTokenScope.of(context);
    final tokenTextStyles = AppTokenTextStyles.of(ref);

    return Column(
      key: const ValueKey('membershipVerificationIntro'),
      mainAxisSize: MainAxisSize.min,
      children: [
        mascotUrl == null
            ? const SizedBox(
                key: ValueKey('membershipVerificationHero'),
                width: _VerificationLayout.mascotWidth,
                height: _VerificationLayout.mascotHeight,
              )
            : Image.network(
                mascotUrl,
                key: const ValueKey('membershipVerificationHero'),
                width: _VerificationLayout.mascotWidth,
                height: _VerificationLayout.mascotHeight,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  width: _VerificationLayout.mascotWidth,
                  height: _VerificationLayout.mascotHeight,
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
    final tokenScope = _VerificationTokenScope.of(context);
    final contentColor = tokenScope.contentColor;
    final tokenTextStyles = AppTokenTextStyles.of(ref);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: tokenScope.badgeBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokenScope.badgeBorderColor),
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

class _VerificationPanel extends StatelessWidget {
  const _VerificationPanel({
    required this.digits,
    required this.onDigitPressed,
  });

  final List<String> digits;
  final ValueChanged<String> onDigitPressed;

  static const _keys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', ''],
  ];

  @override
  Widget build(BuildContext context) {
    final tokenScope = _VerificationTokenScope.of(context);

    return DecoratedBox(
      key: const ValueKey('membershipVerificationPanel'),
      decoration: BoxDecoration(
        color: tokenScope.panelBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(child: _PanelGlassHighlight()),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 54, 24, 66),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const _VerificationPrompt(),
                  const SizedBox(height: 34),
                  _YearDigits(digits: digits),
                  const SizedBox(height: 28),
                  _NumberPad(keys: _keys, onDigitPressed: onDigitPressed),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelGlassHighlight extends StatelessWidget {
  const _PanelGlassHighlight();

  @override
  Widget build(BuildContext context) {
    final tokenScope = _VerificationTokenScope.of(context);

    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          border: Border.all(color: tokenScope.panelBorderColor),
        ),
      ),
    );
  }
}

class _VerificationPrompt extends ConsumerWidget {
  const _VerificationPrompt();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenScope = _VerificationTokenScope.of(context);
    final tokenTextStyles = AppTokenTextStyles.of(ref);

    return SizedBox(
      width: 267,
      child: Column(
        children: [
          Text(
            'For Parents Only',
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
            style: tokenTextStyles.subscriptionVerificationTitle.copyWith(
              color: tokenScope.contentColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Please enter the year you were born.',
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
            style: tokenTextStyles.subscriptionVerificationSubtitle.copyWith(
              color: tokenScope.secondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _YearDigits extends StatelessWidget {
  const _YearDigits({required this.digits});

  final List<String> digits;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < _VerificationLayout.yearLength; index += 1)
          Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : _VerificationLayout.yearBoxGap,
            ),
            child: _YearDigitBox(
              digit: index < digits.length ? digits[index] : '',
            ),
          ),
      ],
    );
  }
}

class _YearDigitBox extends ConsumerWidget {
  const _YearDigitBox({required this.digit});

  final String digit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentColor = _VerificationTokenScope.of(context).contentColor;
    final tokenTextStyles = AppTokenTextStyles.of(ref);

    return _GlassControlSurface(
      width: _VerificationLayout.yearBoxWidth,
      height: _VerificationLayout.yearBoxHeight,
      radius: 12,
      shadowBlur: 4,
      shadowOffset: const Offset(0, 2),
      child: Text(
        digit,
        style: tokenTextStyles.subscriptionVerificationDigit.copyWith(
          color: contentColor,
        ),
      ),
    );
  }
}

class _NumberPad extends StatelessWidget {
  const _NumberPad({required this.keys, required this.onDigitPressed});

  final List<List<String>> keys;
  final ValueChanged<String> onDigitPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var rowIndex = 0; rowIndex < keys.length; rowIndex += 1)
          Padding(
            padding: EdgeInsets.only(
              top: rowIndex == 0 ? 0 : _VerificationLayout.keyRowGap,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (
                  var columnIndex = 0;
                  columnIndex < keys[rowIndex].length;
                  columnIndex += 1
                )
                  Padding(
                    padding: EdgeInsets.only(
                      left: columnIndex == 0
                          ? 0
                          : _VerificationLayout.keyColumnGap,
                    ),
                    child: keys[rowIndex][columnIndex].isEmpty
                        ? const SizedBox(
                            width: _VerificationLayout.keyWidth,
                            height: _VerificationLayout.keyHeight,
                          )
                        : _NumberKey(
                            digit: keys[rowIndex][columnIndex],
                            onPressed: onDigitPressed,
                          ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _NumberKey extends ConsumerWidget {
  const _NumberKey({required this.digit, required this.onPressed});

  final String digit;
  final ValueChanged<String> onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentColor = _VerificationTokenScope.of(context).contentColor;
    final tokenTextStyles = AppTokenTextStyles.of(ref);

    return Semantics(
      button: true,
      label: digit,
      child: Material(
        color: Colors.transparent,
        child: _GlassControlSurface(
          key: ValueKey('membershipVerificationDigit$digit'),
          width: _VerificationLayout.keyWidth,
          height: _VerificationLayout.keyHeight,
          radius: 8,
          shadowBlur: 3,
          shadowOffset: const Offset(0, 1.5),
          child: InkWell(
            onTap: () => onPressed(digit),
            borderRadius: BorderRadius.circular(8),
            child: Center(
              child: Text(
                digit,
                style: tokenTextStyles.subscriptionVerificationDigit.copyWith(
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

class _GlassControlSurface extends StatelessWidget {
  const _GlassControlSurface({
    super.key,
    required this.width,
    required this.height,
    required this.radius,
    required this.child,
    required this.shadowBlur,
    required this.shadowOffset,
  });

  final double width;
  final double height;
  final double radius;
  final Widget child;
  final double shadowBlur;
  final Offset shadowOffset;

  @override
  Widget build(BuildContext context) {
    final tokenScope = _VerificationTokenScope.of(context);

    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokenScope.controlBackgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: tokenScope.controlBorderColor),
        boxShadow: [
          BoxShadow(
            color: _VerificationColors.controlDropShadow,
            offset: shadowOffset,
            blurRadius: shadowBlur,
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _VerificationColors.controlShineStart,
            _VerificationColors.controlShineEnd,
          ],
        ),
      ),
      child: child,
    );
  }
}

abstract final class _VerificationLayout {
  static const designWidth = 390.0;
  static const designHeight = 868.0;
  static const headerHeight = 56.0;

  static const sideArtworkLeft = -71.0;
  static const sideArtworkTop = 154.0;

  static const heroGroupTop = 98.0;
  static const mascotWidth = 116.614;
  static const mascotHeight = 152.0;

  static const panelTop = 358.0;

  static const yearLength = 4;
  static const yearBoxWidth = 44.0;
  static const yearBoxHeight = 52.0;
  static const yearBoxGap = 12.0;

  static const keyWidth = 44.0;
  static const keyHeight = 36.0;
  static const keyColumnGap = 24.0;
  static const keyRowGap = 24.0;
}

abstract final class _VerificationColors {
  static const topBlue = AppColors.backgroundGradientStart;
  static const bottomBlue = AppColors.backgroundGradientEnd;
  static const headerOverlay = AppColors.backgroundGradientStart;
  static const glass = Color(0x2EFFFFFF);
  static const glassBorder = Color(0x66FFFFFF);
  static const glassEdge = Color(0x8AFFFFFF);
  static const controlEdge = Color(0x99FFFFFF);
  static const controlDropShadow = Color(0x33000000);
  static const controlShineStart = Color(0x26FFFFFF);
  static const controlShineEnd = Color(0x00FFFFFF);
}

abstract final class _VerificationSystemUi {
  static const style = SystemUiOverlayStyle(
    statusBarColor: _VerificationColors.topBlue,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: _VerificationColors.bottomBlue,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: Colors.transparent,
  );
}
