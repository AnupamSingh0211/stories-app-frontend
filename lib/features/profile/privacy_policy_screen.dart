import 'package:flutter/material.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/widgets/app_screen_background.dart';

const _figmaWidth = 390.0;

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withNoTextScaling(
      child: Scaffold(
        body: AppScreenBackground(
          child: SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale = (constraints.maxWidth / _figmaWidth)
                    .clamp(0.88, 1.18)
                    .toDouble();
                final horizontal = 16.0 * scale;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _PrivacyPolicyHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          9 * scale,
                          horizontal,
                          32 * scale,
                        ),
                        child: const _PrivacyPolicyText(),
                      ),
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

class _PrivacyPolicyHeader extends StatelessWidget {
  const _PrivacyPolicyHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 24,
              child: InkResponse(
                onTap: () => Navigator.of(context).maybePop(),
                radius: 24,
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textOnPrimary,
                  size: 24,
                  applyTextScaling: false,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Privacy Policy',
              style: _PrivacyPolicyTextStyles.headerTitle,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyPolicyText extends StatelessWidget {
  const _PrivacyPolicyText();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Privacy Policy\n',
            style: _PrivacyPolicyTextStyles.sectionTitle,
          ),
          TextSpan(
            text: 'Last updated: 15 July 2026\n\n',
            style: _PrivacyPolicyTextStyles.body,
          ),
          TextSpan(
            text:
                'At BOOPI, your privacy matters to us. We are committed to creating a safe and enjoyable storytelling experience for children and their families. This Privacy Policy explains what information we collect, how we use it, and the choices you have regarding your data.\n\n',
            style: _PrivacyPolicyTextStyles.body,
          ),
          TextSpan(
            text: 'Information We Collect\n',
            style: _PrivacyPolicyTextStyles.sectionTitle,
          ),
          TextSpan(
            text:
                "To personalize your child's storytelling experience, BOOPI may collect basic information such as your child's name, age, preferred language, favorite stories, and listening progress. We also collect limited device and app usage information to improve performance, fix issues, and provide a better experience.\n\n",
            style: _PrivacyPolicyTextStyles.body,
          ),
          TextSpan(
            text: 'How We Use Your Information\n',
            style: _PrivacyPolicyTextStyles.sectionTitle,
          ),
          TextSpan(
            text:
                "The information you provide helps us recommend stories that match your child's age and interests, remember your preferences across sessions, and improve the overall quality of the app. We use anonymous analytics to understand how features are used so we can continue enhancing BOOPI.\n\n",
            style: _PrivacyPolicyTextStyles.body,
          ),
          TextSpan(
            text: "Children's Privacy\n",
            style: _PrivacyPolicyTextStyles.sectionTitle,
          ),
          TextSpan(
            text:
                'BOOPI is designed for young children to enjoy with parental guidance. We only collect the information necessary to personalize the storytelling experience and do not knowingly collect sensitive personal information from children. Parents or guardians remain in control of the information shared within the app.\n\n',
            style: _PrivacyPolicyTextStyles.body,
          ),
          TextSpan(
            text: 'Data Security\n',
            style: _PrivacyPolicyTextStyles.sectionTitle,
          ),
          TextSpan(
            text:
                'We take reasonable security measures to protect your information from unauthorized access, loss, or misuse. While no online service can guarantee complete security, we continuously work to keep your data safe and secure.\n\n',
            style: _PrivacyPolicyTextStyles.body,
          ),
          TextSpan(
            text: 'Third-Party Services\n',
            style: _PrivacyPolicyTextStyles.sectionTitle,
          ),
          TextSpan(
            text:
                'To improve reliability and app performance, BOOPI may use trusted third-party services such as analytics, crash reporting, and payment providers. These services only receive the information required to perform their functions and are expected to follow their own privacy and security standards.\n\n',
            style: _PrivacyPolicyTextStyles.body,
          ),
          TextSpan(
            text: 'Your Choices\n',
            style: _PrivacyPolicyTextStyles.sectionTitle,
          ),
          TextSpan(
            text:
                "You can update your child's profile, change the app language, manage your favorites, or request deletion of your account and associated data at any time. If you have any questions about your privacy, we're always here to help.\n\n",
            style: _PrivacyPolicyTextStyles.body,
          ),
          TextSpan(
            text: 'Contact Us\n',
            style: _PrivacyPolicyTextStyles.contactTitle,
          ),
          TextSpan(
            text:
                "If you have any questions, feedback, or privacy-related concerns, please contact us at:\nsupport@boopi.app\nWe'll be happy to assist you.",
            style: _PrivacyPolicyTextStyles.body,
          ),
        ],
      ),
      textAlign: TextAlign.start,
    );
  }
}

abstract final class _PrivacyPolicyTextStyles {
  static const _fontFeatures = [
    FontFeature.disable('liga'),
    FontFeature.disable('clig'),
  ];

  static const headerTitle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 20,
    height: 24 / 20,
    letterSpacing: -0.25,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    fontFeatures: _fontFeatures,
  );

  static const sectionTitle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 16,
    height: 20 / 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
    fontFeatures: _fontFeatures,
  );

  static const body = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textOnPrimary,
    fontFeatures: _fontFeatures,
  );

  static const contactTitle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
    fontFeatures: _fontFeatures,
  );
}
