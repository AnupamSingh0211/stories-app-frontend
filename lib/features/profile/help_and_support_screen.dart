import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/analytics_service.dart';
import '../../shared/theme/app_tokens.dart';
import '../../shared/widgets/app_screen_background.dart';

const _figmaWidth = 390.0;
const _arrowUpAsset = 'assets/icons/new_boopi/Iconly/Light/Arrow - Up 2.svg';

class HelpAndSupportScreen extends ConsumerStatefulWidget {
  const HelpAndSupportScreen({super.key});

  @override
  ConsumerState<HelpAndSupportScreen> createState() =>
      _HelpAndSupportScreenState();
}

class _HelpAndSupportScreenState extends ConsumerState<HelpAndSupportScreen> {
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    unawaited(
      PostHogAnalytics.instance.screenOpened(
        'help_and_support_screen',
        properties: {'source': 'profile_screen'},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokenStyles = _HelpTokenStyles.fromRef(ref);

    return MediaQuery.withNoTextScaling(
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final scale = (constraints.maxWidth / _figmaWidth)
                .clamp(0.88, 1.18)
                .toDouble();
            final safeTop = MediaQuery.paddingOf(context).top;

            return AppScreenBackground(
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: safeTop,
                    height: 56 * scale,
                    child: _HelpHeader(scale: scale, tokenStyles: tokenStyles),
                  ),
                  Positioned(
                    left: 16 * scale,
                    top: safeTop + (65 * scale),
                    width: 338 * scale,
                    child: _IntroText(tokenStyles: tokenStyles),
                  ),
                  Positioned(
                    left: 16 * scale,
                    right: 16 * scale,
                    top: safeTop + (120 * scale),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FaqList(
                          tokenStyles: tokenStyles,
                          expandedIndex: _expandedIndex,
                          onToggle: (index) {
                            unawaited(
                              PostHogAnalytics.instance.buttonClicked(
                                buttonName: 'faq_item',
                                screenName: 'help_and_support_screen',
                                properties: {
                                  'source': 'faq_list',
                                  'target_index': index,
                                },
                              ),
                            );
                            setState(() {
                              _expandedIndex = _expandedIndex == index
                                  ? null
                                  : index;
                            });
                          },
                        ),
                        const SizedBox(height: 29),
                        _SupportContact(tokenStyles: tokenStyles),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 16 * scale,
                    right: 33 * scale,
                    bottom: 44 * scale,
                    child: Text(
                      'App Version v1.0.0',
                      style: tokenStyles.sectionTitle,
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
  const _HelpHeader({required this.scale, required this.tokenStyles});

  final double scale;
  final _HelpTokenStyles tokenStyles;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16 * scale),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 24 * scale,
            child: InkResponse(
              onTap: () {
                unawaited(
                  PostHogAnalytics.instance.capture(
                    'back_clicked',
                    properties: {
                      'screen_name': 'help_and_support_screen',
                      'source': 'help_header',
                    },
                  ),
                );
                unawaited(
                  PostHogAnalytics.instance.buttonClicked(
                    buttonName: 'back',
                    screenName: 'help_and_support_screen',
                    properties: {'source': 'help_header'},
                  ),
                );
                Navigator.of(context).maybePop();
              },
              radius: 24 * scale,
              child: Icon(
                Icons.arrow_back_rounded,
                color: tokenStyles.contentColor,
                size: 24 * scale,
                applyTextScaling: false,
              ),
            ),
          ),
          SizedBox(width: 12 * scale),
          Text('Help & Support', style: tokenStyles.headerTitle),
        ],
      ),
    );
  }
}

class _IntroText extends StatelessWidget {
  const _IntroText({required this.tokenStyles});

  final _HelpTokenStyles tokenStyles;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'Need a hand?\n', style: tokenStyles.sectionTitle),
          TextSpan(text: "We're here to help.", style: tokenStyles.body),
        ],
      ),
    );
  }
}

class _FaqList extends StatelessWidget {
  const _FaqList({
    required this.tokenStyles,
    required this.expandedIndex,
    required this.onToggle,
  });

  final _HelpTokenStyles tokenStyles;
  final int? expandedIndex;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < 5; index += 1) ...[
          _FaqTile(
            tokenStyles: tokenStyles,
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
  const _FaqTile({
    required this.tokenStyles,
    required this.expanded,
    required this.onTap,
  });

  final _HelpTokenStyles tokenStyles;
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
          color: tokenStyles.cardBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokenStyles.cardBorderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'How do I start a story?',
                    style: tokenStyles.question,
                  ),
                ),
                _FaqArrow(expanded: expanded, color: tokenStyles.contentColor),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: 4),
              SizedBox(
                width: 329,
                child: Text(
                  'Select a story from the Home screen and tap the Play '
                  'button to begin listening.',
                  style: tokenStyles.answer,
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
  const _FaqArrow({required this.expanded, required this.color});

  final bool expanded;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icon = SvgPicture.asset(
      _arrowUpAsset,
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );

    return SizedBox.square(
      dimension: 24,
      child: expanded ? Transform.rotate(angle: math.pi, child: icon) : icon,
    );
  }
}

class _SupportContact extends StatelessWidget {
  const _SupportContact({required this.tokenStyles});

  final _HelpTokenStyles tokenStyles;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Questions, Ideas and feedback?\n',
            style: tokenStyles.sectionTitle,
          ),
          TextSpan(
            text: 'Drop us a note at hello@boopikids.com.',
            style: tokenStyles.body,
          ),
        ],
      ),
    );
  }
}

class _HelpTokenStyles {
  const _HelpTokenStyles({
    required this.contentColor,
    required this.headerTitle,
    required this.sectionTitle,
    required this.body,
    required this.question,
    required this.answer,
    required this.cardBackgroundColor,
    required this.cardBorderColor,
  });

  factory _HelpTokenStyles.fromRef(WidgetRef ref) {
    final tokenColors = AppTokenColors.of(ref);
    final tokenTextStyles = AppTokenTextStyles.of(ref);
    final contentColor = tokenColors.profileTextPrimary;
    return _HelpTokenStyles(
      contentColor: contentColor,
      headerTitle: tokenTextStyles.profileHeaderTitle.copyWith(
        color: contentColor,
      ),
      sectionTitle: tokenTextStyles.profileSectionLabel.copyWith(
        color: contentColor,
      ),
      body: tokenTextStyles.profileRowSubtitle.copyWith(color: contentColor),
      question: tokenTextStyles.profileRowTitle.copyWith(color: contentColor),
      answer: tokenTextStyles.profileRowSubtitle.copyWith(
        color: tokenColors.profileTextSecondary,
      ),
      cardBackgroundColor: tokenColors.profileCardBackground,
      cardBorderColor: tokenColors.profileCardBorder,
    );
  }

  final Color contentColor;
  final TextStyle headerTitle;
  final TextStyle sectionTitle;
  final TextStyle body;
  final TextStyle question;
  final TextStyle answer;
  final Color cardBackgroundColor;
  final Color cardBorderColor;
}
