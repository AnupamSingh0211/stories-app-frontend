import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics_service.dart';
import '../../shared/theme/app_tokens.dart';
import '../../shared/widgets/app_screen_background.dart';

const _figmaWidth = 390.0;

class PrivacyPolicyScreen extends ConsumerStatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  ConsumerState<PrivacyPolicyScreen> createState() =>
      _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends ConsumerState<PrivacyPolicyScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(
      PostHogAnalytics.instance.screenOpened(
        'privacy_policy_screen',
        properties: {'source': 'profile_screen'},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokenStyles = _PrivacyPolicyTokenStyles.fromRef(ref);

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
                    _PrivacyPolicyHeader(tokenStyles: tokenStyles),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          9 * scale,
                          horizontal,
                          32 * scale,
                        ),
                        child: _PrivacyPolicyText(tokenStyles: tokenStyles),
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
  const _PrivacyPolicyHeader({required this.tokenStyles});

  final _PrivacyPolicyTokenStyles tokenStyles;

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
                onTap: () {
                  unawaited(
                    PostHogAnalytics.instance.capture(
                      'back_clicked',
                      properties: {
                        'screen_name': 'privacy_policy_screen',
                        'source': 'privacy_header',
                      },
                    ),
                  );
                  unawaited(
                    PostHogAnalytics.instance.buttonClicked(
                      buttonName: 'back',
                      screenName: 'privacy_policy_screen',
                      properties: {'source': 'privacy_header'},
                    ),
                  );
                  Navigator.of(context).maybePop();
                },
                radius: 24,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: tokenStyles.contentColor,
                  size: 24,
                  applyTextScaling: false,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('Privacy Policy', style: tokenStyles.headerTitle),
          ],
        ),
      ),
    );
  }
}

class _PrivacyPolicyText extends StatelessWidget {
  const _PrivacyPolicyText({required this.tokenStyles});

  final _PrivacyPolicyTokenStyles tokenStyles;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'Privacy Policy\n', style: tokenStyles.sectionTitle),
          TextSpan(
            text: 'Last updated: 15 July 2026\n\n',
            style: tokenStyles.body,
          ),
          TextSpan(
            text:
                'At BOOPI, your privacy matters to us. We are committed to creating a safe and enjoyable storytelling experience for children and their families. This Privacy Policy explains what information we collect, how we use it, and the choices you have regarding your data.\n\n',
            style: tokenStyles.body,
          ),
          TextSpan(
            text: 'Information We Collect\n',
            style: tokenStyles.sectionTitle,
          ),
          TextSpan(
            text:
                "To personalize your child's storytelling experience, BOOPI may collect basic information such as your child's name, age, preferred language, favorite stories, and listening progress. We also collect limited device and app usage information to improve performance, fix issues, and provide a better experience.\n\n",
            style: tokenStyles.body,
          ),
          TextSpan(
            text: 'How We Use Your Information\n',
            style: tokenStyles.sectionTitle,
          ),
          TextSpan(
            text:
                "The information you provide helps us recommend stories that match your child's age and interests, remember your preferences across sessions, and improve the overall quality of the app. We use anonymous analytics to understand how features are used so we can continue enhancing BOOPI.\n\n",
            style: tokenStyles.body,
          ),
          TextSpan(
            text: "Children's Privacy\n",
            style: tokenStyles.sectionTitle,
          ),
          TextSpan(
            text:
                'BOOPI is designed for young children to enjoy with parental guidance. We only collect the information necessary to personalize the storytelling experience and do not knowingly collect sensitive personal information from children. Parents or guardians remain in control of the information shared within the app.\n\n',
            style: tokenStyles.body,
          ),
          TextSpan(text: 'Data Security\n', style: tokenStyles.sectionTitle),
          TextSpan(
            text:
                'We take reasonable security measures to protect your information from unauthorized access, loss, or misuse. While no online service can guarantee complete security, we continuously work to keep your data safe and secure.\n\n',
            style: tokenStyles.body,
          ),
          TextSpan(
            text: 'Third-Party Services\n',
            style: tokenStyles.sectionTitle,
          ),
          TextSpan(
            text:
                'To improve reliability and app performance, BOOPI may use trusted third-party services such as analytics, crash reporting, and payment providers. These services only receive the information required to perform their functions and are expected to follow their own privacy and security standards.\n\n',
            style: tokenStyles.body,
          ),
          TextSpan(text: 'Your Choices\n', style: tokenStyles.sectionTitle),
          TextSpan(
            text:
                "You can update your child's profile, change the app language, manage your favorites, or request deletion of your account and associated data at any time. If you have any questions about your privacy, we're always here to help.\n\n",
            style: tokenStyles.body,
          ),
          TextSpan(text: 'Contact Us\n', style: tokenStyles.contactTitle),
          TextSpan(
            text:
                "If you have any questions, feedback, or privacy-related concerns, please contact us at:\nsupport@boopi.app\nWe'll be happy to assist you.",
            style: tokenStyles.body,
          ),
        ],
      ),
      textAlign: TextAlign.start,
    );
  }
}

class _PrivacyPolicyTokenStyles {
  const _PrivacyPolicyTokenStyles({
    required this.contentColor,
    required this.headerTitle,
    required this.sectionTitle,
    required this.body,
    required this.contactTitle,
  });

  factory _PrivacyPolicyTokenStyles.fromRef(WidgetRef ref) {
    final tokenColors = AppTokenColors.of(ref);
    final tokenTextStyles = AppTokenTextStyles.of(ref);
    final contentColor = tokenColors.profileTextPrimary;
    return _PrivacyPolicyTokenStyles(
      contentColor: contentColor,
      headerTitle: tokenTextStyles.profileHeaderTitle.copyWith(
        color: contentColor,
      ),
      sectionTitle: tokenTextStyles.profileRowTitle.copyWith(
        color: contentColor,
      ),
      body: tokenTextStyles.profileRowSubtitle.copyWith(
        color: tokenColors.profileTextSecondary,
      ),
      contactTitle: tokenTextStyles.profileSectionLabel.copyWith(
        color: contentColor,
      ),
    );
  }

  final Color contentColor;
  final TextStyle headerTitle;
  final TextStyle sectionTitle;
  final TextStyle body;
  final TextStyle contactTitle;
}
