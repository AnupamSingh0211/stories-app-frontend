import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/design_system_provider.dart';
import '../../core/design_system/design_token_resolver.dart';
import 'app_typography.dart';

class AppTokenTextStyles {
  const AppTokenTextStyles._(this._resolver);

  factory AppTokenTextStyles.of(WidgetRef ref) {
    return AppTokenTextStyles._(ref.watch(designTokenResolverProvider));
  }

  factory AppTokenTextStyles.fromResolver(DesignTokenResolver resolver) {
    return AppTokenTextStyles._(resolver);
  }

  final DesignTokenResolver _resolver;

  TextStyle custom(String key, {required TextStyle fallback}) {
    return _resolver.textStyle(key, fallback: fallback);
  }

  TextStyle get displayLarge => _resolver.textStyle(
    'typography.display-large',
    fallback: AppTypography.displayRegular,
  );
  TextStyle get displayMedium => _resolver.textStyle(
    'typography.display-medium',
    fallback: AppTypography.displayMedium,
  );
  TextStyle get displaySmall => _resolver.textStyle(
    'typography.display-small',
    fallback: AppTypography.displayRegular,
  );
  TextStyle get headlineLarge => _resolver.textStyle(
    'typography.headline-large',
    fallback: AppTypography.heading1Regular,
  );
  TextStyle get headlineMedium => _resolver.textStyle(
    'typography.headline-medium',
    fallback: AppTypography.heading1Medium,
  );
  TextStyle get headlineSmall => _resolver.textStyle(
    'typography.headline-small',
    fallback: AppTypography.heading2Medium,
  );
  TextStyle get titleLarge => _resolver.textStyle(
    'typography.title-large',
    fallback: AppTypography.titleMedium,
  );
  TextStyle get titleMedium => _resolver.textStyle(
    'typography.title-medium',
    fallback: AppTypography.bodyLargeMedium,
  );
  TextStyle get titleSmall => _resolver.textStyle(
    'typography.title-small',
    fallback: AppTypography.bodyMediumMedium,
  );
  TextStyle get bodyLarge => _resolver.textStyle(
    'typography.body-large',
    fallback: AppTypography.bodyLargeRegular,
  );
  TextStyle get bodyMedium => _resolver.textStyle(
    'typography.body-medium',
    fallback: AppTypography.bodyMediumRegular,
  );
  TextStyle get bodySmall => _resolver.textStyle(
    'typography.body-small',
    fallback: AppTypography.bodySmallRegular,
  );
  TextStyle get labelLarge => _resolver.textStyle(
    'typography.label-large',
    fallback: AppTypography.labelMedium,
  );
  TextStyle get labelMedium => _resolver.textStyle(
    'typography.label-medium',
    fallback: AppTypography.bodySmallMedium,
  );
  TextStyle get labelSmall => _resolver.textStyle(
    'typography.label-small',
    fallback: AppTypography.captionMedium,
  );

  TextStyle get homeGreetingLabel =>
      custom('home.greeting.label', fallback: AppTypography.bodySmallRegular);
  TextStyle get homeGreetingName =>
      custom('home.greeting.name', fallback: AppTypography.bodyLargeBold);
  TextStyle get homeHeroEyebrow =>
      custom('home.hero.eyebrow', fallback: AppTypography.captionBold);
  TextStyle get homeHeroTitle =>
      custom('home.hero.title', fallback: AppTypography.bodyLargeBold);
  TextStyle get homeNavLabel =>
      custom('home.nav.label', fallback: AppTypography.captionBold);
  TextStyle get homeNavLabelDefault =>
      custom('home.nav.label.default', fallback: homeNavLabel);
  TextStyle get homeNavLabelSelected =>
      custom('home.nav.label.selected', fallback: homeNavLabel);
  TextStyle get homeSearchInput =>
      custom('home.search.input', fallback: AppTypography.bodyMediumBold);
  TextStyle get homeSectionTitle =>
      custom('home.section.title', fallback: AppTypography.bodyLargeBold);
  TextStyle get homeStoryCardMeta =>
      custom('home.story-card.meta', fallback: AppTypography.bodySmallSemiBold);
  TextStyle get homeStoryCardTitle => custom(
    'home.story-card.title',
    fallback: AppTypography.bodyMediumSemiBold,
  );

  TextStyle get profileHeaderTitle =>
      custom('profile.header.title', fallback: AppTypography.heading3SemiBold);
  TextStyle get profileRowTitle =>
      custom('profile.row.title', fallback: AppTypography.bodyLargeBold);
  TextStyle get profileRowSubtitle => custom(
    'profile.row.subtitle',
    fallback: AppTypography.bodyMediumSemiBold,
  );
  TextStyle get profileSectionLabel =>
      custom('profile.section.label', fallback: AppTypography.bodySmallBold);

  TextStyle get onboardingChoiceLabel => custom(
    'onboarding.choice.label',
    fallback: AppTypography.bodyMediumSemiBold,
  );
  TextStyle get onboardingCtaLabel =>
      custom('onboarding.cta.label', fallback: AppTypography.bodyLargeBold);
  TextStyle get onboardingFormInput =>
      custom('onboarding.form.input', fallback: AppTypography.bodyMediumBold);
  TextStyle get onboardingFormLabel => custom(
    'onboarding.form.label',
    fallback: AppTypography.bodySmallSemiBold,
  );
  TextStyle get onboardingHeaderSubtitle => custom(
    'onboarding.header.subtitle',
    fallback: AppTypography.bodyMediumMedium,
  );
  TextStyle get onboardingHeaderTitle =>
      custom('onboarding.header.title', fallback: AppTypography.heading2Bold);
  TextStyle get onboardingOtpCaption => custom(
    'onboarding.otp.caption',
    fallback: AppTypography.bodySmallSemiBold,
  );
  TextStyle get onboardingOtpTitle =>
      custom('onboarding.otp.title', fallback: AppTypography.heading3SemiBold);

  TextStyle get soonBadgeLabel =>
      custom('soon.badge.label', fallback: AppTypography.captionBold);
  TextStyle get soonCardTitle =>
      custom('soon.card.title', fallback: AppTypography.bodyMediumSemiBold);
  TextStyle get soonEmptySubtitle =>
      custom('soon.empty.subtitle', fallback: AppTypography.bodySmallMedium);
  TextStyle get soonEmptyTitle =>
      custom('soon.empty.title', fallback: AppTypography.bodyMediumSemiBold);
  TextStyle get soonHeaderTitle =>
      custom('soon.header.title', fallback: AppTypography.heading3SemiBold);

  TextStyle get subscriptionBadgeLabel =>
      custom('subscription.badge.label', fallback: AppTypography.captionBold);
  TextStyle get subscriptionBenefitsHeading => custom(
    'subscription.benefits.heading',
    fallback: AppTypography.bodyMediumSemiBold,
  );
  TextStyle get subscriptionBenefitsLabel => custom(
    'subscription.benefits.label',
    fallback: AppTypography.bodySmallSemiBold,
  );
  TextStyle get subscriptionCtaLabel =>
      custom('subscription.cta.label', fallback: AppTypography.bodyLargeBold);
  TextStyle get subscriptionHeaderTitle => custom(
    'subscription.header.title',
    fallback: AppTypography.heading3SemiBold,
  );
  TextStyle get subscriptionHeroSubtitle => custom(
    'subscription.hero.subtitle',
    fallback: AppTypography.bodyMediumMedium,
  );
  TextStyle get subscriptionHeroTitle =>
      custom('subscription.hero.title', fallback: AppTypography.heading2Bold);
  TextStyle get subscriptionPlanLabel =>
      custom('subscription.plan.label', fallback: AppTypography.bodyLargeBold);
  TextStyle get subscriptionPlanPrice =>
      custom('subscription.plan.price', fallback: AppTypography.bodyLargeBold);
  TextStyle get subscriptionVerificationDigit => custom(
    'subscription.verification.digit',
    fallback: AppTypography.bodyLargeSemiBold,
  );
  TextStyle get subscriptionVerificationSubtitle => custom(
    'subscription.verification.subtitle',
    fallback: AppTypography.bodyMediumMedium,
  );
  TextStyle get subscriptionVerificationTitle => custom(
    'subscription.verification.title',
    fallback: AppTypography.heading3SemiBold,
  );

  TextStyle get episodesHeaderTitle =>
      custom('episodes.header.title', fallback: AppTypography.heading3SemiBold);
  TextStyle get episodesHeroMeta =>
      custom('episodes.hero.meta', fallback: AppTypography.bodySmallBold);
  TextStyle get episodesHeroTitle =>
      custom('episodes.hero.title', fallback: AppTypography.titleSemiBold);
  TextStyle get episodesSectionLabel =>
      custom('episodes.section.label', fallback: AppTypography.bodyMediumBold);
  TextStyle get episodesTileMeta =>
      custom('episodes.tile.meta', fallback: AppTypography.captionSemiBold);
  TextStyle get episodesTileTitle =>
      custom('episodes.tile.title', fallback: AppTypography.bodyMediumSemiBold);

  TextStyle get favoritesCardTitle => custom(
    'favorites.card.title',
    fallback: AppTypography.bodyMediumSemiBold,
  );
  TextStyle get favoritesEmptyCtaLabel => custom(
    'favorites.empty.cta.label',
    fallback: AppTypography.bodyLargeBold,
  );
  TextStyle get favoritesEmptySubtitle => custom(
    'favorites.empty.subtitle',
    fallback: AppTypography.bodyMediumRegular,
  );
  TextStyle get favoritesEmptyTitle =>
      custom('favorites.empty.title', fallback: AppTypography.heading3SemiBold);
  TextStyle get favoritesHeaderTitle => custom(
    'favorites.header.title',
    fallback: AppTypography.heading3SemiBold,
  );
  TextStyle get favoritesSectionAction => custom(
    'favorites.section.action',
    fallback: AppTypography.bodyMediumRegular,
  );
  TextStyle get favoritesSectionTitle =>
      custom('favorites.section.title', fallback: AppTypography.bodyLargeBold);
}
