import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';

const _figmaWidth = 390.0;
const _arrowUpAsset = 'assets/icons/new_boopi/Iconly/Light/Arrow - Up 2.svg';

class HelpAndSupportScreen extends StatefulWidget {
  const HelpAndSupportScreen({super.key});

  @override
  State<HelpAndSupportScreen> createState() => _HelpAndSupportScreenState();
}

class _HelpAndSupportScreenState extends State<HelpAndSupportScreen> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withNoTextScaling(
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final scale = (constraints.maxWidth / _figmaWidth)
                .clamp(0.88, 1.18)
                .toDouble();
            final safeTop = MediaQuery.paddingOf(context).top;

            return DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [
                    AppColors.blue300,
                    AppColors.blue500,
                    AppColors.blue800,
                  ],
                  stops: [0, 0.48, 1],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: safeTop,
                    height: 56 * scale,
                    child: _HelpHeader(scale: scale),
                  ),
                  Positioned(
                    left: 16 * scale,
                    top: safeTop + (65 * scale),
                    width: 338 * scale,
                    child: const _IntroText(),
                  ),
                  Positioned(
                    left: 16 * scale,
                    right: 16 * scale,
                    top: safeTop + (120 * scale),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FaqList(
                          expandedIndex: _expandedIndex,
                          onToggle: (index) {
                            setState(() {
                              _expandedIndex = _expandedIndex == index
                                  ? null
                                  : index;
                            });
                          },
                        ),
                        const SizedBox(height: 29),
                        const _SupportContact(),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 16 * scale,
                    right: 33 * scale,
                    bottom: 44 * scale,
                    child: const Text(
                      'App Version v1.0.0',
                      style: _HelpTextStyles.sectionTitle,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HelpHeader extends StatelessWidget {
  const _HelpHeader({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16 * scale),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 24 * scale,
            child: InkResponse(
              onTap: () => Navigator.of(context).maybePop(),
              radius: 24 * scale,
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textOnPrimary,
                size: 24 * scale,
                applyTextScaling: false,
              ),
            ),
          ),
          SizedBox(width: 12 * scale),
          const Text('Help & Support', style: _HelpTextStyles.headerTitle),
        ],
      ),
    );
  }
}

class _IntroText extends StatelessWidget {
  const _IntroText();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'Need a hand?\n', style: _HelpTextStyles.sectionTitle),
          TextSpan(text: "We're here to help.", style: _HelpTextStyles.body),
        ],
      ),
    );
  }
}

class _FaqList extends StatelessWidget {
  const _FaqList({required this.expandedIndex, required this.onToggle});

  final int? expandedIndex;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < 5; index += 1) ...[
          _FaqTile(
            expanded: expandedIndex == index,
            onTap: () => onToggle(index),
          ),
          if (index < 4) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundGlass,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Text(
                    'How do I start a story?',
                    style: _HelpTextStyles.question,
                  ),
                ),
                _FaqArrow(expanded: expanded),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: 4),
              const SizedBox(
                width: 329,
                child: Text(
                  'Select a story from the Home screen and tap the Play '
                  'button to begin listening.',
                  style: _HelpTextStyles.answer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FaqArrow extends StatelessWidget {
  const _FaqArrow({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final icon = SvgPicture.asset(
      _arrowUpAsset,
      width: 24,
      height: 24,
      colorFilter: const ColorFilter.mode(
        AppColors.textOnPrimary,
        BlendMode.srcIn,
      ),
    );

    return SizedBox.square(
      dimension: 24,
      child: expanded ? Transform.rotate(angle: math.pi, child: icon) : icon,
    );
  }
}

class _SupportContact extends StatelessWidget {
  const _SupportContact();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Still need help?  \n',
            style: _HelpTextStyles.sectionTitle,
          ),
          TextSpan(text: 'support@boopi.app', style: _HelpTextStyles.body),
        ],
      ),
    );
  }
}

abstract final class _HelpTextStyles {
  static const headerTitle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 20,
    height: 24 / 20,
    letterSpacing: -0.25,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );

  static const sectionTitle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 16,
    height: 20 / 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
  );

  static const body = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textOnPrimary,
  );

  static const question = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );

  static const answer = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );
}
