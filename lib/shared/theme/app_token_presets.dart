import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/design_system_provider.dart';
import '../../core/design_system/design_token.dart';
import '../../core/design_system/design_token_resolver.dart';
import 'app_colors.dart';

class AppTokenPresets {
  const AppTokenPresets._(this._resolver);

  factory AppTokenPresets.of(WidgetRef ref) {
    return AppTokenPresets._(ref.watch(designTokenResolverProvider));
  }

  factory AppTokenPresets.fromResolver(DesignTokenResolver resolver) {
    return AppTokenPresets._(resolver);
  }

  final DesignTokenResolver _resolver;

  DesignPreset get primaryCtaButton => _resolver.preset(
    'preset.button.primary-cta',
    fallback: AppTokenPresetFallbacks.primaryCtaButton,
  );

  DesignPreset get primaryProgressBar => _resolver.preset(
    'preset.progress-bar.primary',
    fallback: AppTokenPresetFallbacks.primaryProgressBar,
  );

  DesignPreset get storiesCard => _resolver.preset(
    'preset.stories.card',
    fallback: AppTokenPresetFallbacks.storiesCard,
  );

  DesignPreset get dialogSurface => _resolver.preset(
    'preset.dialog.surface',
    fallback: AppTokenPresetFallbacks.dialogSurface,
  );

  DesignPreset get tooltipBubble => _resolver.preset(
    'preset.tooltip.bubble',
    fallback: AppTokenPresetFallbacks.tooltipBubble,
  );
}

abstract final class AppTokenPresetFallbacks {
  static const primaryCtaButton = DesignPreset(
    background: AppColors.accentPrimary,
    foreground: AppColors.textOnPrimary,
    track: AppColors.borderDefault,
    radius: 24,
    padding: 16,
    fillMode: 'solid',
    trackMode: 'none',
    applicability: ['Nudge', 'Guide'],
  );

  static const primaryProgressBar = DesignPreset(
    background: AppColors.surfaceWhite,
    foreground: AppColors.accentPrimary,
    track: AppColors.borderDefault,
    radius: 4,
    padding: 0,
    fillMode: 'solid',
    trackMode: 'solid',
    applicability: ['Nudge', 'Guide'],
  );

  static const storiesCard = DesignPreset(
    background: AppColors.backgroundGlass,
    foreground: AppColors.textOnPrimary,
    track: AppColors.borderLight,
    radius: 8,
    padding: 12,
    fillMode: 'solid',
    trackMode: 'none',
    applicability: ['Guide'],
  );

  static const dialogSurface = DesignPreset(
    background: AppColors.surfaceModalBackground,
    foreground: AppColors.textPrimary,
    track: AppColors.borderDefault,
    radius: 20,
    padding: 20,
    fillMode: 'solid',
    trackMode: 'none',
    applicability: ['Nudge', 'Guide'],
  );

  static const tooltipBubble = DesignPreset(
    background: AppColors.textPrimary,
    foreground: AppColors.textOnPrimary,
    track: AppColors.borderDefault,
    radius: 8,
    padding: 10,
    fillMode: 'solid',
    trackMode: 'none',
    applicability: ['Nudge'],
  );
}
