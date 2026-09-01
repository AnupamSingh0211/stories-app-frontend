import 'package:flutter/material.dart';

import 'design_token.dart';
import 'design_token_parser.dart';

class DesignTokenResolver {
  DesignTokenResolver(
    Iterable<DesignToken> tokens, {
    this.theme = DesignTokenTheme.light,
    this.fallbackTheme = DesignTokenTheme.light,
  }) : _tokensByTheme = _indexTokens(tokens);

  final DesignTokenTheme theme;
  final DesignTokenTheme fallbackTheme;
  final Map<String, Map<DesignTokenTheme, DesignToken>> _tokensByTheme;

  Color color(String key, {required Color fallback}) {
    final token = _tokenFor(key);
    if (token == null || token.tokenType != DesignTokenType.color) {
      return fallback;
    }

    return DesignTokenParser.parseColor(token.tokenValue) ?? fallback;
  }

  TextStyle textStyle(String key, {required TextStyle fallback}) {
    final token = _tokenFor(key);
    if (token == null || token.tokenType != DesignTokenType.typography) {
      return fallback;
    }

    return DesignTokenParser.parseTypography(
          token.tokenValue,
          fallback: fallback,
        ) ??
        fallback;
  }

  DesignPreset preset(String key, {required DesignPreset fallback}) {
    final token = _tokenFor(key);
    if (token == null || token.tokenType != DesignTokenType.preset) {
      return fallback;
    }

    return DesignTokenParser.parsePreset(
          token.tokenValue,
          fallback: fallback,
        ) ??
        fallback;
  }

  double responsiveScaleForWidth(double width, {double baseline = 360}) {
    if (width <= 0 || baseline <= 0) {
      return 1;
    }
    return width / baseline;
  }

  DesignToken? _tokenFor(String key) {
    final themedTokens = _tokensByTheme[key];
    if (themedTokens == null) {
      return null;
    }

    return themedTokens[theme] ??
        themedTokens[fallbackTheme] ??
        themedTokens[DesignTokenTheme.light];
  }

  static Map<String, Map<DesignTokenTheme, DesignToken>> _indexTokens(
    Iterable<DesignToken> tokens,
  ) {
    final indexed = <String, Map<DesignTokenTheme, DesignToken>>{};
    for (final token in tokens) {
      if (!token.isActive || token.tokenKey.trim().isEmpty) {
        continue;
      }
      indexed.putIfAbsent(token.tokenKey, () => {})[token.theme] = token;
    }
    return indexed;
  }
}
