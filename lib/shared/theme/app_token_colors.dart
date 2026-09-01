import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/design_system_provider.dart';
import '../../core/design_system/design_token_resolver.dart';
import 'app_colors.dart';

class AppTokenColors {
  const AppTokenColors._(this._resolver);

  factory AppTokenColors.of(WidgetRef ref) {
    return AppTokenColors._(ref.watch(designTokenResolverProvider));
  }

  factory AppTokenColors.fromResolver(DesignTokenResolver resolver) {
    return AppTokenColors._(resolver);
  }

  final DesignTokenResolver _resolver;

  Color _color(String key, Color fallback) {
    return _resolver.color(key, fallback: fallback);
  }

  Color get primary => _color('color.primary', AppColors.accentPrimary);
  Color get onPrimary => _color('color.on-primary', AppColors.textOnPrimary);
  Color get primaryContainer => _resolver.color(
    'color.primary-container',
    fallback: AppColors.accentPrimarySoft,
  );
  Color get onPrimaryContainer => _resolver.color(
    'color.on-primary-container',
    fallback: AppColors.textPrimary,
  );
  Color get secondary =>
      _resolver.color('color.secondary', fallback: AppColors.accentSecondary);
  Color get onSecondary =>
      _resolver.color('color.on-secondary', fallback: AppColors.textOnPrimary);
  Color get secondaryContainer => _resolver.color(
    'color.secondary-container',
    fallback: AppColors.surfaceSecondary,
  );
  Color get onSecondaryContainer => _resolver.color(
    'color.on-secondary-container',
    fallback: AppColors.textPrimary,
  );
  Color get surface =>
      _resolver.color('color.surface', fallback: AppColors.surfacePrimary);
  Color get onSurface =>
      _resolver.color('color.on-surface', fallback: AppColors.textPrimary);
  Color get surfaceVariant => _resolver.color(
    'color.surface-variant',
    fallback: AppColors.surfaceSecondary,
  );
  Color get onSurfaceVariant => _resolver.color(
    'color.on-surface-variant',
    fallback: AppColors.textSecondary,
  );
  Color get outline =>
      _resolver.color('color.outline', fallback: AppColors.borderDefault);
  Color get error =>
      _resolver.color('color.error', fallback: AppColors.error500);

  Color get homeBackgroundTop => _resolver.color(
    'home.background.top',
    fallback: AppColors.backgroundGradientStart,
  );
  Color get homeBackgroundMiddle => _resolver.color(
    'home.background.middle',
    fallback: AppColors.backgroundGradientMiddle,
  );
  Color get homeBackgroundBottom => _resolver.color(
    'home.background.bottom',
    fallback: AppColors.backgroundGradientEnd,
  );
  Color get playerBackgroundPrimary => _resolver.color(
    'player.background.primary',
    fallback: AppColors.playerBackground,
  );
  Color get homeCardTextPrimary => _resolver.color(
    'home.card.text.primary',
    fallback: AppColors.textOnPrimary,
  );

  Color get profileTextPrimary =>
      _color('profile.text.primary', AppColors.textOnPrimary);
  Color get profileTextSecondary =>
      _color('profile.text.secondary', AppColors.textOnPrimary.withAlpha(217));
  Color get profileCardBackground =>
      _color('profile.card.background', AppColors.backgroundGlass);
  Color get profileCardBorder =>
      _color('profile.card.border', AppColors.borderLight);
  Color get profileRowDivider =>
      _color('profile.row.divider', AppColors.borderLight);
  Color get profileIconBackground =>
      _color('profile.icon.background', AppColors.glassBackground);
  Color get profileSwitchTrack =>
      _color('profile.switch.track', AppColors.glassBackground);
  Color get profileSwitchThumbActive =>
      _color('profile.switch.thumb.active', AppColors.textOnPrimary);
  Color get profileLoadingPlaceholder =>
      _color('profile.loading.placeholder', AppColors.backgroundGlass);

  Color get onboardingControlBackground =>
      _color('onboarding.control.background', AppColors.backgroundGlass);
  Color get onboardingControlBorder =>
      _color('onboarding.control.border', AppColors.borderLight);
  Color get onboardingChoiceBackground =>
      _color('onboarding.choice.background', AppColors.backgroundGlass);
  Color get onboardingChoiceBorder =>
      _color('onboarding.choice.border', AppColors.borderLight);
  Color get onboardingOtpBoxBackground =>
      _color('onboarding.otp.box.background', AppColors.backgroundGlass);
  Color get onboardingOtpBoxBorder =>
      _color('onboarding.otp.box.border', AppColors.borderLight);
  Color get onboardingProgressActive =>
      _color('onboarding.progress.active', AppColors.info500);
  Color get onboardingProgressInactive =>
      _color('onboarding.progress.inactive', AppColors.gray300);
  Color get onboardingHeaderIcon =>
      _color('onboarding.header.icon', AppColors.textOnPrimary);

  Color get soonCardBackground =>
      _color('soon.card.background', AppColors.backgroundGlass);
  Color get soonCardBorder => _color('soon.card.border', AppColors.borderLight);
  Color get soonCardShadow => _color(
    'soon.card.shadow',
    AppColors.surfaceBlack.withValues(alpha: 0.18),
  );
  Color get soonImagePlaceholder =>
      _color('soon.image.placeholder', AppColors.backgroundGlass);
  Color get soonBadgeBackgroundStart => _color(
    'soon.badge.background.start',
    AppColors.interactivePrimaryPressed,
  );
  Color get soonBadgeBackgroundEnd =>
      _color('soon.badge.background.end', const Color(0xFF040F21));
  Color get soonBadgeText => _color('soon.badge.text', AppColors.textOnPrimary);
  Color get soonVoteIconDefault =>
      _color('soon.vote.icon.default', AppColors.textOnPrimary);
  Color get soonVoteIconSelected =>
      _color('soon.vote.icon.selected', AppColors.textOnPrimary);
  Color get soonVoteIconDisabled =>
      _color('soon.vote.icon.disabled', AppColors.textOnPrimary);

  Color get subscriptionBackgroundTop =>
      _color('subscription.background.top', AppColors.backgroundGradientStart);
  Color get subscriptionBackgroundMiddle => _color(
    'subscription.background.middle',
    AppColors.backgroundGradientMiddle,
  );
  Color get subscriptionBackgroundBottom =>
      _color('subscription.background.bottom', AppColors.backgroundGradientEnd);
  Color get subscriptionStatusBarBackground =>
      _color('subscription.status-bar.background', AppColors.transparent);
  Color get subscriptionNavBarBackground =>
      _color('subscription.nav-bar.background', AppColors.transparent);
  Color get subscriptionCardBackground =>
      _color('subscription.card.background', AppColors.backgroundGlass);
  Color get subscriptionCardBorder =>
      _color('subscription.card.border', AppColors.borderLight);
  Color get subscriptionCardShadow =>
      _color('subscription.card.shadow', AppColors.surfaceBlack);
  Color get subscriptionCtaBackground =>
      _color('subscription.cta.background', AppColors.backgroundGlass);
  Color get subscriptionCtaBorder =>
      _color('subscription.cta.border', AppColors.borderLight);
  Color get subscriptionControlBackground =>
      _color('subscription.control.background', AppColors.backgroundGlass);
  Color get subscriptionControlBorder =>
      _color('subscription.control.border', AppColors.borderLight);
  Color get subscriptionControlShadow =>
      _color('subscription.control.shadow', AppColors.surfaceBlack);
  Color get subscriptionPanelBackground =>
      _color('subscription.panel.background', AppColors.backgroundGlass);
  Color get subscriptionPanelBorder =>
      _color('subscription.panel.border', AppColors.borderLight);
  Color get subscriptionPlanSelectedBorder =>
      _color('subscription.plan.selected-border', AppColors.textOnPrimary);
  Color get subscriptionPlanUnselectedBorder =>
      _color('subscription.plan.unselected-border', AppColors.borderLight);
  Color get subscriptionPlanRadioSelectedFill =>
      _color('subscription.plan.radio.selected-fill', AppColors.textOnPrimary);
  Color get subscriptionPlanRadioCheck =>
      _color('subscription.plan.radio.check', AppColors.textPrimary);
  Color get subscriptionPlanRadioUnselectedBorder => _color(
    'subscription.plan.radio.unselected-border',
    AppColors.borderLight,
  );

  Color get episodesCardBackground =>
      _color('episodes.card.background', AppColors.backgroundGlass);
  Color get episodesCardBorder =>
      _color('episodes.card.border', AppColors.borderLight);
  Color get episodesHeroBorder =>
      _color('episodes.hero.border', AppColors.borderLight);
  Color get episodesHeroOverlay =>
      _color('episodes.hero.overlay', AppColors.backgroundOverlay);
  Color get episodesProgressTrack =>
      _color('episodes.progress.track', AppColors.glassBackground);
  Color get episodesTileBackground =>
      _color('episodes.tile.background', AppColors.backgroundGlass);
  Color get episodesTileBorder =>
      _color('episodes.tile.border', AppColors.borderLight);
  Color get episodesActionCompletedBackground => _color(
    'episodes.action.completed.background',
    AppColors.interactivePrimary,
  );
  Color get episodesActionCompletedIcon =>
      _color('episodes.action.completed.icon', AppColors.textOnPrimary);
  Color get episodesActionContinuingBackground => _color(
    'episodes.action.continuing.background',
    AppColors.interactivePrimary,
  );
  Color get episodesActionContinuingIcon =>
      _color('episodes.action.continuing.icon', AppColors.textOnPrimary);
  Color get episodesActionLeftBorder =>
      _color('episodes.action.left.border', AppColors.textOnPrimary);
  Color get episodesActionLeftIcon =>
      _color('episodes.action.left.icon', AppColors.textOnPrimary);

  Color get playerOverlayButtonBackground =>
      _color('player.overlay.button.background', AppColors.glassBackground);
  Color get playerOverlayButtonBorder =>
      _color('player.overlay.button.border', AppColors.borderLight);
  Color get playerOverlayIcon =>
      _color('player.overlay.icon', AppColors.textOnPrimary);
  Color get playerTimelineTrack =>
      _color('player.timeline.track', AppColors.glassBackground);
  Color get playerTimelineFill =>
      _color('player.timeline.fill', AppColors.textOnPrimary);
  Color get playerTimelineLabel =>
      _color('player.timeline.label', AppColors.textOnPrimary);
  Color get playerImageBorder =>
      _color('player.image.border', AppColors.borderLight);
  Color get playerSheetBackground =>
      _color('player.sheet.background', AppColors.surfacePrimary);
  Color get playerSheetTextPrimary =>
      _color('player.sheet.text.primary', AppColors.textPrimary);
  Color get playerSheetTextSecondary =>
      _color('player.sheet.text.secondary', AppColors.textSecondary);
  Color get playerSheetControlPrimary =>
      _color('player.sheet.control.primary', AppColors.accentPrimary);
  Color get playerSheetControlDisabled =>
      _color('player.sheet.control.disabled', AppColors.textDisabled);

  Color get storyFeedBackground =>
      _color('story-feed.background', AppColors.surfacePrimary);
  Color get storyFeedHeaderBackground =>
      _color('story-feed.header.background', AppColors.surfacePrimary);
  Color get storyFeedTextPrimary =>
      _color('story-feed.text.primary', AppColors.textPrimary);
  Color get storyFeedTextSecondary =>
      _color('story-feed.text.secondary', AppColors.textSecondary);
  Color get storyFeedIconPrimary =>
      _color('story-feed.icon.primary', AppColors.accentPrimary);
  Color get storyPageSurface =>
      _color('story-page.surface', AppColors.surfaceWhite);
  Color get storyPageText => _color('story-page.text', AppColors.textPrimary);

  Color get homeSearchBackground =>
      _color('home.search.background', AppColors.backgroundGlass);
  Color get homeSearchBorder =>
      _color('home.search.border', AppColors.borderLight);
  Color get homeActionBackground =>
      _color('home.action.background', AppColors.backgroundGlass);
  Color get homeActionBorder =>
      _color('home.action.border', AppColors.borderLight);
  Color get homeNavBackground =>
      _color('home.nav.background', AppColors.backgroundGlass);
  Color get homeNavBorder => _color('home.nav.border', AppColors.borderLight);
  Color get homeNavActiveBackground =>
      _color('home.nav.active.background', AppColors.backgroundGlass);
  Color get homeNavActiveBorder =>
      _color('home.nav.active.border', AppColors.borderLight);
  Color get homeNavIconDefault =>
      _color('home.nav.icon.default', homeCardTextPrimary);
  Color get homeNavIconSelected =>
      _color('home.nav.icon.selected', homeCardTextPrimary);
  Color get homeNavLabelDefault =>
      _color('home.nav.label.default', homeCardTextPrimary);
  Color get homeNavLabelSelected =>
      _color('home.nav.label.selected', homeCardTextPrimary);
  Color get homeCardBackground =>
      _color('home.card.background', AppColors.backgroundGlass);
  Color get homeCardBorder => _color('home.card.border', AppColors.borderLight);
  Color get homeCardShadow => _color(
    'home.card.shadow',
    AppColors.surfaceBlack.withValues(alpha: 0.10),
  );
  Color get homeHeroOverlayStart =>
      _color('home.hero.overlay.start', AppColors.transparent);
  Color get homeHeroOverlayMiddle => _color(
    'home.hero.overlay.middle',
    AppColors.surfaceBlack.withValues(alpha: 0.08),
  );
  Color get homeHeroOverlayEnd => _color(
    'home.hero.overlay.end',
    AppColors.surfaceBlack.withValues(alpha: 0.72),
  );
  Color get homeHeroBorder => _color('home.hero.border', AppColors.borderLight);
  Color get homeHeroShadow => _color(
    'home.hero.shadow',
    AppColors.surfaceBlack.withValues(alpha: 0.18),
  );
  Color get homeStoryCardImagePlaceholder =>
      _color('home.story-card.image.placeholder', AppColors.backgroundGlass);
  Color get homeStoryCardFavoriteBackground =>
      _color('home.story-card.favorite.background', AppColors.glassBackground);
  Color get homeStoryCardFavoriteBorder =>
      _color('home.story-card.favorite.border', AppColors.borderLight);
  Color get homeStoryCardBadgeBackground =>
      _color('home.story-card.badge.background', AppColors.glassBackground);
  Color get homeStoryCardBadgeBorder =>
      _color('home.story-card.badge.border', AppColors.borderLight);

  Color get favoritesCardBackground =>
      _color('favorites.card.background', AppColors.backgroundGlass);
  Color get favoritesCardBorder =>
      _color('favorites.card.border', AppColors.borderLight);
  Color get favoritesCardShadow => _color(
    'favorites.card.shadow',
    AppColors.surfaceBlack.withValues(alpha: 0.10),
  );
  Color get favoritesEmptyCtaBackground =>
      _color('favorites.empty.cta.background', AppColors.backgroundGlass);
  Color get favoritesEmptyCtaBorder =>
      _color('favorites.empty.cta.border', AppColors.borderLight);
  Color get favoritesIconButtonBackground =>
      _color('favorites.icon-button.background', AppColors.glassBackground);
  Color get favoritesIconButtonForeground =>
      _color('favorites.icon-button.foreground', homeCardTextPrimary);
}
