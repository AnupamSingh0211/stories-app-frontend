import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backend_api_client.dart';
import 'design_system_repository.dart';
import 'design_system_config.dart';
import 'design_token.dart';
import 'design_token_defaults.dart';
import 'design_token_resolver.dart';

final designSystemRepositoryProvider = Provider<DesignSystemRepository>((ref) {
  return DesignSystemRepository(apiClient: ref.watch(backendApiClientProvider));
});

final designTokenThemeProvider = StateProvider<DesignTokenTheme>((ref) {
  return DesignTokenTheme.light;
});

final designSystemConfigProvider = FutureProvider<DesignSystemConfig>((
  ref,
) async {
  final repository = ref.watch(designSystemRepositoryProvider);
  try {
    final config = await repository.fetchDesignSystemConfig();
    if (config.tokens.isEmpty) {
      return DesignSystemConfig.defaults();
    }
    return config;
  } catch (_) {
    return DesignSystemConfig.defaults();
  }
});

final designTokensProvider = FutureProvider<List<DesignToken>>((ref) async {
  final config = await ref.watch(designSystemConfigProvider.future);
  return [
    for (final token in config.tokens)
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
