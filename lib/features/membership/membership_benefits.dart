import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';

class MembershipBenefitsStrip extends StatelessWidget {
  const MembershipBenefitsStrip({
    required this.heading,
    required this.headingGap,
    super.key,
  });

  final String heading;
  final double headingGap;

  static const _benefits = [
    _BenefitData(
      label: 'New\nReleases',
      iconAsset: 'assets/icons/membership/new_releases.svg',
    ),
    _BenefitData(
      label: 'Unlimited\nStories',
      iconAsset: 'assets/icons/membership/unlimited_stories.svg',
    ),
    _BenefitData(
      label: 'Premium\nCompanions',
      iconAsset: 'assets/icons/membership/premium_companions.svg',
    ),
    _BenefitData(
      label: 'Offline\nListening',
      iconAsset: 'assets/icons/membership/offline_listening.svg',
    ),
    _BenefitData(
      label: 'Ad-Free\nAccess',
      iconAsset: 'assets/icons/membership/ad_free.svg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          heading,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 18,
            height: 20 / 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF29609B),
          ),
        ),
        SizedBox(height: headingGap),
        SizedBox(
          height: membershipBenefitCardHeight,
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minWidth: membershipBenefitsRowWidth,
            maxWidth: membershipBenefitsRowWidth,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < _benefits.length; index++) ...[
                  _BenefitCard(data: _benefits[index]),
                  if (index < _benefits.length - 1)
                    const SizedBox(width: membershipBenefitGap),
                ],
              ],
            ),
          ),
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
      width: membershipBenefitCardWidth,
      height: membershipBenefitCardHeight,
      // The border plus 11px padding places content at Figma's 12px inset.
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          SvgPicture.asset(data.iconAsset, width: 32, height: 32),
          const SizedBox(height: 4),
          Text(
            data.label,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF001033),
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

const membershipBenefitCardWidth = 100.0;
const membershipBenefitCardHeight = 92.0;
const membershipBenefitGap = 16.0;
const membershipBenefitsRowWidth =
    (membershipBenefitCardWidth * 5) + (membershipBenefitGap * 4);
