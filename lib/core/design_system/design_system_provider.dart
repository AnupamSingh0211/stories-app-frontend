import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'design_system_repository.dart';
import 'design_token.dart';
import 'design_token_defaults.dart';
import 'design_token_resolver.dart';

final designSystemRepositoryProvider = Provider<DesignSystemRepository>((ref) {
  return const DesignSystemRepository();
});

final designTokenThemeProvider = StateProvider<DesignTokenTheme>((ref) {
  return DesignTokenTheme.light;
});

final designTokensProvider = FutureProvider<List<DesignToken>>((ref) async {
  final repository = ref.watch(designSystemRepositoryProvider);
  final List<DesignToken> tokens;
  try {
    tokens = await repository.fetchDesignTokens();
  } catch (_) {
    return defaultDesignTokens;
  }

  return [
    for (final token in tokens)
      if (token.isActive) token,
  ];
});

final designTokenResolverProvider = Provider<DesignTokenResolver>((ref) {
  final tokens = ref.watch(designTokensProvider).valueOrNull;
  final theme = ref.watch(designTokenThemeProvider);
  return DesignTokenResolver(
    tokens == null || tokens.isEmpty ? defaultDesignTokens : tokens,
    theme: theme,
  );
});
