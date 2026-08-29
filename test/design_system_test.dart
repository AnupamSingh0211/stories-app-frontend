import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dharma_app/core/design_system/design_system_provider.dart';
import 'package:dharma_app/core/design_system/design_system_repository.dart';
import 'package:dharma_app/core/design_system/design_token.dart';
import 'package:dharma_app/core/design_system/design_token_defaults.dart';
import 'package:dharma_app/core/design_system/design_token_resolver.dart';

void main() {
  test('design token model parses CMS schema fields', () {
    final token = DesignToken.fromJson({
      'token_key': 'color.primary',
      'token_value': '#6750A4',
      'token_type': 'color',
      'theme': 'dark',
      'group_name': 'boopi',
      'description': 'Main Boopi action color.',
      'sort_order': '3',
      'is_active': true,
    });

    expect(token.tokenKey, 'color.primary');
    expect(token.tokenValue, '#6750A4');
    expect(token.tokenType, DesignTokenType.color);
    expect(token.theme, DesignTokenTheme.dark);
    expect(token.groupName, 'boopi');
    expect(token.description, 'Main Boopi action color.');
    expect(token.sortOrder, 3);
    expect(token.isActive, isTrue);
  });

  test('resolver parses color tokens and falls back for invalid colors', () {
    final resolver = DesignTokenResolver([
      const DesignToken(
        tokenKey: 'color.primary',
        tokenValue: '#6750A4',
        tokenType: DesignTokenType.color,
        groupName: 'boopi',
        sortOrder: 0,
        isActive: true,
      ),
      const DesignToken(
        tokenKey: 'color.error',
        tokenValue: 'not-a-color',
        tokenType: DesignTokenType.color,
        groupName: 'boopi',
        sortOrder: 1,
        isActive: true,
      ),
    ]);

    expect(
      resolver.color('color.primary', fallback: Colors.black),
      const Color(0xFF6750A4),
    );
    expect(resolver.color('color.error', fallback: Colors.red), Colors.red);
    expect(
      resolver.color('color.missing', fallback: Colors.white),
      Colors.white,
    );
  });

  test('resolver prefers requested theme and falls back to light tokens', () {
    final resolver = DesignTokenResolver([
      const DesignToken(
        tokenKey: 'color.primary',
        tokenValue: '#6750A4',
        tokenType: DesignTokenType.color,
        theme: DesignTokenTheme.light,
        groupName: 'boopi',
        sortOrder: 0,
        isActive: true,
      ),
      const DesignToken(
        tokenKey: 'color.primary',
        tokenValue: '#D0BCFF',
        tokenType: DesignTokenType.color,
        theme: DesignTokenTheme.dark,
        groupName: 'boopi',
        sortOrder: 0,
        isActive: true,
      ),
      const DesignToken(
        tokenKey: 'typography.body-medium',
        tokenValue:
            '{"size":"14","lineHeight":"1.43","letterSpacing":"0.25","weight":"400"}',
        tokenType: DesignTokenType.typography,
        theme: DesignTokenTheme.light,
        groupName: 'typography',
        sortOrder: 0,
        isActive: true,
      ),
    ], theme: DesignTokenTheme.dark);

    expect(
      resolver.color('color.primary', fallback: Colors.black),
      const Color(0xFFD0BCFF),
    );

    final style = resolver.textStyle(
      'typography.body-medium',
      fallback: const TextStyle(fontSize: 12),
    );
    expect(style.fontSize, 14);
  });

  test('resolver ignores inactive tokens', () {
    final resolver = DesignTokenResolver([
      const DesignToken(
        tokenKey: 'color.primary',
        tokenValue: '#6750A4',
        tokenType: DesignTokenType.color,
        groupName: 'boopi',
        sortOrder: 0,
        isActive: false,
      ),
    ]);

    expect(
      resolver.color('color.primary', fallback: Colors.black),
      Colors.black,
    );
  });

  test('resolver parses typography JSON and ignores sample preview field', () {
    final resolver = DesignTokenResolver([
      const DesignToken(
        tokenKey: 'typography.display-large',
        tokenValue:
            '{"sample":"Keep the pace","size":"57","lineHeight":"1.12","letterSpacing":"-0.25","weight":"400"}',
        tokenType: DesignTokenType.typography,
        groupName: 'typography',
        sortOrder: 0,
        isActive: true,
      ),
    ]);

    const fallback = TextStyle(
      fontSize: 14,
      height: 1.43,
      letterSpacing: 0.25,
      fontWeight: FontWeight.w500,
    );
    final style = resolver.textStyle(
      'typography.display-large',
      fallback: fallback,
    );

    expect(style.fontSize, 57);
    expect(style.height, 1.12);
    expect(style.letterSpacing, -0.25);
    expect(style.fontWeight, FontWeight.w400);
    expect(style.fontFamily, 'PlusJakartaSans');
  });

  test('resolver keeps fallback typography values for invalid fields', () {
    final resolver = DesignTokenResolver([
      const DesignToken(
        tokenKey: 'typography.body-medium',
        tokenValue:
            '{"size":"bad","lineHeight":"1.43","letterSpacing":"bad","weight":"950"}',
        tokenType: DesignTokenType.typography,
        groupName: 'typography',
        sortOrder: 0,
        isActive: true,
      ),
      const DesignToken(
        tokenKey: 'typography.bad-json',
        tokenValue: '{bad',
        tokenType: DesignTokenType.typography,
        groupName: 'typography',
        sortOrder: 1,
        isActive: true,
      ),
    ]);

    const fallback = TextStyle(
      fontSize: 14,
      height: 1.2,
      letterSpacing: 0.1,
      fontWeight: FontWeight.w500,
    );

    final partialStyle = resolver.textStyle(
      'typography.body-medium',
      fallback: fallback,
    );
    expect(partialStyle.fontSize, fallback.fontSize);
    expect(partialStyle.height, 1.43);
    expect(partialStyle.letterSpacing, fallback.letterSpacing);
    expect(partialStyle.fontWeight, fallback.fontWeight);

    final badJsonStyle = resolver.textStyle(
      'typography.bad-json',
      fallback: fallback,
    );
    expect(badJsonStyle, fallback);
  });

  test('resolver parses preset tokens and falls back for invalid presets', () {
    final fallback = _fallbackPreset;
    final resolver = DesignTokenResolver([
      const DesignToken(
        tokenKey: 'preset.progress-bar.primary',
        tokenValue:
            '{"background":"#ffffff","foreground":"#4945FF","track":"#E0E0E0","radius":"4","padding":"0","fillMode":"solid","trackMode":"solid","applicability":["Nudge","Guide"]}',
        tokenType: DesignTokenType.preset,
        groupName: 'Progress Bar',
        sortOrder: 0,
        isActive: true,
      ),
      const DesignToken(
        tokenKey: 'preset.invalid',
        tokenValue:
            '{"background":"not-a-color","foreground":"#FFFFFF","radius":"12"}',
        tokenType: DesignTokenType.preset,
        groupName: 'Button',
        sortOrder: 1,
        isActive: true,
      ),
    ]);

    final preset = resolver.preset(
      'preset.progress-bar.primary',
      fallback: fallback,
    );
    expect(preset.background, Colors.white);
    expect(preset.foreground, const Color(0xFF4945FF));
    expect(preset.track, const Color(0xFFE0E0E0));
    expect(preset.radius, 4);
    expect(preset.padding, 0);
    expect(preset.fillMode, 'solid');
    expect(preset.trackMode, 'solid');
    expect(preset.applicability, ['Nudge', 'Guide']);

    expect(
      resolver.preset('preset.invalid', fallback: fallback),
      same(fallback),
    );
    expect(
      resolver.preset('preset.missing', fallback: fallback),
      same(fallback),
    );
  });

  test('repository returns local default design tokens', () async {
    final tokens = await const DesignSystemRepository().fetchDesignTokens();

    expect(tokens, defaultDesignTokens);
    expect(
      tokens.where((token) => token.tokenType == DesignTokenType.color),
      hasLength(38),
    );
    expect(
      tokens.where((token) => token.tokenType == DesignTokenType.typography),
      hasLength(15),
    );
    expect(
      tokens.where((token) => token.tokenType == DesignTokenType.preset),
      hasLength(5),
    );
  });

  test('provider returns defaults when token fetch fails', () async {
    final container = ProviderContainer(
      overrides: [
        designSystemRepositoryProvider.overrideWithValue(
          const _FailingDesignSystemRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final tokens = await container.read(designTokensProvider.future);
    final resolver = container.read(designTokenResolverProvider);

    expect(tokens, defaultDesignTokens);
    expect(
      resolver.color('color.primary', fallback: Colors.black),
      const Color(0xFF6750A4),
    );
  });

  test('provider can resolve dark theme tokens', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(designTokenThemeProvider.notifier).state =
        DesignTokenTheme.dark;
    await container.read(designTokensProvider.future);
    final resolver = container.read(designTokenResolverProvider);

    expect(
      resolver.color('color.primary', fallback: Colors.black),
      const Color(0xFFD0BCFF),
    );
  });

  testWidgets('isolated widget can consume design system provider', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, child) {
              final resolver = ref.watch(designTokenResolverProvider);
              return ColoredBox(
                key: const ValueKey('designSystemProof'),
                color: resolver.color(
                  'home.background.top',
                  fallback: Colors.black,
                ),
                child: const SizedBox(width: 24, height: 24),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final proof = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('designSystemProof')),
    );
    expect(proof.color, const Color(0xFF24325F));
  });
}

const _fallbackPreset = DesignPreset(
  background: Colors.black,
  foreground: Colors.white,
  track: Color(0xFFE0E0E0),
  radius: 12,
  padding: 14,
  fillMode: 'solid',
  trackMode: 'none',
  applicability: ['Guide'],
);

class _FailingDesignSystemRepository extends DesignSystemRepository {
  const _FailingDesignSystemRepository();

  @override
  Future<List<DesignToken>> fetchDesignTokens() async {
    throw StateError('App Config API is not ready');
  }
}
