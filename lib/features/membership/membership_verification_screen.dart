import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import 'membership_side_banner.dart';

class MembershipVerificationScreen extends StatefulWidget {
  const MembershipVerificationScreen({super.key});

  @override
  State<MembershipVerificationScreen> createState() =>
      _MembershipVerificationScreenState();
}

class _MembershipVerificationScreenState
    extends State<MembershipVerificationScreen> {
  final List<String> _digits = [];

  void _enterDigit(String digit) {
    if (_digits.length == _VerificationLayout.yearLength) return;
    setState(() => _digits.add(digit));
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withNoTextScaling(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: _VerificationSystemUi.style,
        child: Scaffold(
          backgroundColor: _VerificationColors.topBlue,
          body: SafeArea(
            left: false,
            right: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final contentWidth = constraints.maxWidth;
                final scale = contentWidth / _VerificationLayout.designWidth;
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
                                      top: _VerificationLayout.heroGroupTop,
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
                    const Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: _VerificationHeader(),
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

class _VerificationBackground extends StatelessWidget {
  const _VerificationBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _VerificationColors.topBlue,
            _VerificationColors.midBlue,
            _VerificationColors.bottomBlue,
          ],
          stops: [0, 0.54, 1],
        ),
      ),
    );
  }
}

class _VerificationHeader extends StatelessWidget {
  const _VerificationHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _VerificationLayout.headerHeight,
      color: _VerificationColors.headerOverlay,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Back',
            child: InkResponse(
              key: const ValueKey('membershipVerificationBackButton'),
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

class _VerificationHeroCopy extends StatelessWidget {
  const _VerificationHeroCopy();

  @override
  Widget build(BuildContext context) {
    final mascotUrl = _membershipMascotUrl();

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
        const Text(
          'Unlock the Magic',
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
          style: _VerificationTextStyles.heroTitle,
        ),
        const SizedBox(height: 8),
        const Text(
          'Unlimited stories to inspire, learn, and dream.',
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
          style: _VerificationTextStyles.heroSubtitle,
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
        color: _VerificationColors.glass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _VerificationColors.glassBorder),
      ),
      child: const Text('PLUS MEMBER', style: _VerificationTextStyles.badge),
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
    return DecoratedBox(
      key: const ValueKey('membershipVerificationPanel'),
      decoration: const BoxDecoration(
        color: _VerificationColors.glass,
        borderRadius: BorderRadius.only(
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
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          border: Border.all(color: _VerificationColors.glassEdge),
        ),
      ),
    );
  }
}

class _VerificationPrompt extends StatelessWidget {
  const _VerificationPrompt();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 267,
      child: Column(
        children: [
          Text(
            'For Parents Only',
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
            style: _VerificationTextStyles.panelTitle,
          ),
          SizedBox(height: 12),
          Text(
            'Please enter the year you were born.',
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
            style: _VerificationTextStyles.panelSubtitle,
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

class _YearDigitBox extends StatelessWidget {
  const _YearDigitBox({required this.digit});

  final String digit;

  @override
  Widget build(BuildContext context) {
    return _GlassControlSurface(
      width: _VerificationLayout.yearBoxWidth,
      height: _VerificationLayout.yearBoxHeight,
      radius: 12,
      shadowBlur: 4,
      shadowOffset: const Offset(0, 2),
      child: Text(digit, style: _VerificationTextStyles.digit),
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

class _NumberKey extends StatelessWidget {
  const _NumberKey({required this.digit, required this.onPressed});

  final String digit;
  final ValueChanged<String> onPressed;

  @override
  Widget build(BuildContext context) {
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
              child: Text(digit, style: _VerificationTextStyles.digit),
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
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _VerificationColors.glass,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _VerificationColors.controlEdge),
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
  static const topBlue = Color(0xFF49A7F4);
  static const midBlue = Color(0xFF2D86EA);
  static const bottomBlue = Color(0xFF0F4E9B);
  static const headerOverlay = Color(0xFF49A7F4);
  static const glass = Color(0x2EFFFFFF);
  static const glassBorder = Color(0x66FFFFFF);
  static const glassEdge = Color(0x8AFFFFFF);
  static const controlEdge = Color(0x99FFFFFF);
  static const controlDropShadow = Color(0x33000000);
  static const controlShineStart = Color(0x26FFFFFF);
  static const controlShineEnd = Color(0x00FFFFFF);
  static const textSecondaryOpacity = Color(0xD9FFFFFF);
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

abstract final class _VerificationTextStyles {
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
    color: _VerificationColors.textSecondaryOpacity,
  );

  static const panelTitle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 24,
    height: 28 / 24,
    letterSpacing: -0.25,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );

  static const panelSubtitle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    color: _VerificationColors.textSecondaryOpacity,
  );

  static const digit = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 16,
    height: 20 / 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );
}
