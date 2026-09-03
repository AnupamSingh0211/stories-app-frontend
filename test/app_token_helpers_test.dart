import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:boopi_app/core/design_system/design_system_provider.dart';
import 'package:boopi_app/core/design_system/design_system_repository.dart';
import 'package:boopi_app/core/design_system/design_token.dart';
import 'package:boopi_app/core/design_system/design_token_parser.dart';
import 'package:boopi_app/core/design_system/design_token_resolver.dart';
import 'package:boopi_app/shared/theme/app_colors.dart';
import 'package:boopi_app/shared/theme/app_token_colors.dart';
import 'package:boopi_app/shared/theme/app_token_presets.dart';
import 'package:boopi_app/shared/theme/app_token_text_styles.dart';
import 'package:boopi_app/shared/theme/app_typography.dart';

void main() {
  test('token color helper returns resolved token color', () {
    final colors = AppTokenColors.fromResolver(
      DesignTokenResolver([
        const DesignToken(
          tokenKey: 'color.primary',
          tokenValue: '#123456',
          tokenType: DesignTokenType.color,
          groupName: 'boopi',
          sortOrder: 0,
          isActive: true,
        ),
      ]),
    );

    expect(colors.primary, const Color(0xFF123456));
  });

  test('token parser treats 8-digit CMS hex as RRGGBBAA', () {
    expect(DesignTokenParser.parseColor('#FFFFFF1F'), const Color(0x1FFFFFFF));
    expect(DesignTokenParser.parseColor('#FFFFFFB3'), const Color(0xB3FFFFFF));
    expect(DesignTokenParser.parseColor('#00000052'), const Color(0x52000000));
  });

  test('token color helper falls back for invalid or missing token', () {
    final colors = AppTokenColors.fromResolver(
      DesignTokenResolver([
        const DesignToken(
          tokenKey: 'color.primary',
          tokenValue: 'bad-color',
          tokenType: DesignTokenType.color,
          groupName: 'boopi',
          sortOrder: 0,
          isActive: true,
        ),
      ]),
    );

    expect(colors.primary, AppColors.accentPrimary);
    expect(colors.error, AppColors.error500);
  });

  test('token color helper exposes semantic screen tokens', () {
    final colors = AppTokenColors.fromResolver(
      DesignTokenResolver([
        const DesignToken(
          tokenKey: 'profile.card.background',
          tokenValue: '#223344',
          tokenType: DesignTokenType.color,
          groupName: 'profile',
          sortOrder: 0,
          isActive: true,
        ),
        const DesignToken(
          tokenKey: 'onboarding.control.border',
          tokenValue: '#334455',
          tokenType: DesignTokenType.color,
          groupName: 'onboarding',
          sortOrder: 0,
          isActive: true,
        ),
        const DesignToken(
          tokenKey: 'episodes.progress.track',
          tokenValue: '#445566',
          tokenType: DesignTokenType.color,
          groupName: 'episodes',
          sortOrder: 0,
          isActive: true,
        ),
        const DesignToken(
          tokenKey: 'player.timeline.fill',
          tokenValue: '#556677',
          tokenType: DesignTokenType.color,
          groupName: 'player',
          sortOrder: 0,
          isActive: true,
        ),
        const DesignToken(
          tokenKey: 'home.search.background',
          tokenValue: '#667788',
          tokenType: DesignTokenType.color,
          groupName: 'home',
          sortOrder: 0,
          isActive: true,
        ),
        const DesignToken(
          tokenKey: 'favorites.card.background',
          tokenValue: '#778899',
          tokenType: DesignTokenType.color,
          groupName: 'favorites',
          sortOrder: 0,
          isActive: true,
        ),
      ]),
    );

    expect(colors.profileCardBackground, const Color(0xFF223344));
    expect(colors.onboardingControlBorder, const Color(0xFF334455));
    expect(colors.episodesProgressTrack, const Color(0xFF445566));
    expect(colors.playerTimelineFill, const Color(0xFF556677));
    expect(colors.homeSearchBackground, const Color(0xFF667788));
    expect(colors.favoritesCardBackground, const Color(0xFF778899));
  });

  test('token text style helper returns resolved typography style', () {
    final textStyles = AppTokenTextStyles.fromResolver(
      DesignTokenResolver([
        const DesignToken(
          tokenKey: 'typography.title-medium',
          tokenValue:
              '{"size":"19","lineHeight":"1.4","letterSpacing":"0.2","weight":"700"}',
          tokenType: DesignTokenType.typography,
          groupName: 'typography',
          sortOrder: 0,
          isActive: true,
        ),
      ]),
    );

    final style = textStyles.titleMedium;

    expect(style.fontSize, 19);
    expect(style.height, 1.4);
    expect(style.letterSpacing, 0.2);
    expect(style.fontWeight, FontWeight.w700);
  });

  test('token text style helper falls back safely', () {
    final textStyles = AppTokenTextStyles.fromResolver(
      DesignTokenResolver([
        const DesignToken(
          tokenKey: 'typography.body-medium',
          tokenValue: '{bad-json',
          tokenType: DesignTokenType.typography,
          groupName: 'typography',
          sortOrder: 0,
          isActive: true,
        ),
      ]),
    );

    expect(textStyles.bodyMedium, AppTypography.bodyMediumRegular);
    expect(textStyles.labelSmall, AppTypography.captionMedium);
  });

  test('token preset helper returns resolved preset', () {
    final presets = AppTokenPresets.fromResolver(
      DesignTokenResolver([
        const DesignToken(
          tokenKey: 'preset.stories.card',
          tokenValue:
              '{"background":"#101010","foreground":"#FAFAFA","track":"#303030","radius":"14","padding":"18","fillMode":"solid","trackMode":"solid","applicability":["Guide"]}',
          tokenType: DesignTokenType.preset,
          groupName: 'Stories',
          sortOrder: 0,
          isActive: true,
        ),
      ]),
    );

    final preset = presets.storiesCard;

    expect(preset.background, const Color(0xFF101010));
    expect(preset.foreground, const Color(0xFFFAFAFA));
    expect(preset.track, const Color(0xFF303030));
    expect(preset.radius, 14);
    expect(preset.padding, 18);
    expect(preset.fillMode, 'solid');
    expect(preset.trackMode, 'solid');
    expect(preset.applicability, ['Guide']);
  });

  test('token preset helper falls back safely', () {
    final presets = AppTokenPresets.fromResolver(
      DesignTokenResolver([
        const DesignToken(
          tokenKey: 'preset.button.primary-cta',
          tokenValue:
              '{"background":"not-a-color","foreground":"#FFFFFF","radius":"12"}',
          tokenType: DesignTokenType.preset,
          groupName: 'Button',
          sortOrder: 0,
          isActive: true,
        ),
      ]),
    );

    expect(
      presets.primaryCtaButton,
      same(AppTokenPresetFallbacks.primaryCtaButton),
    );
    expect(presets.tooltipBubble, same(AppTokenPresetFallbacks.tooltipBubble));
  });

  testWidgets('token helpers can be consumed from providers in a widget', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          designSystemRepositoryProvider.overrideWithValue(
            const DesignSystemRepository(),
          ),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, child) {
              final colors = AppTokenColors.of(ref);
              final textStyles = AppTokenTextStyles.of(ref);
              final presets = AppTokenPresets.of(ref);

              return DecoratedBox(
                key: const ValueKey('token-helper-proof'),
                decoration: BoxDecoration(
                  color: colors.homeBackgroundTop,
                  borderRadius: BorderRadius.circular(
                    presets.storiesCard.radius,
                  ),
                ),
                child: Text(
                  'Token proof',
                  style: textStyles.bodyMedium.copyWith(
                    color: colors.homeCardTextPrimary,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final proof = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('token-helper-proof')),
    );
    final decoration = proof.decoration as BoxDecoration;

    expect(decoration.color, const Color(0xFF24325F));
    expect(decoration.borderRadius, BorderRadius.circular(16));
    expect(find.text('Token proof'), findsOneWidget);
  });
}
