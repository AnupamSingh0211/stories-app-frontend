import '../backend_api_client.dart';
import 'design_system_config.dart';
import 'design_token.dart';

class DesignSystemRepository {
  const DesignSystemRepository({BackendApiClient? apiClient})
    : _apiClient = apiClient;

  final BackendApiClient? _apiClient;

  Future<DesignSystemConfig> fetchDesignSystemConfig() async {
    final apiClient = _apiClient;
    if (apiClient == null) {
      return DesignSystemConfig.defaults();
    }

    try {
      final config = await apiClient.getObject('/api/v1/public-app-config');
      return _designSystemFromConfig(config);
    } catch (_) {
      return DesignSystemConfig.defaults();
    }
  }

  Future<List<DesignToken>> fetchDesignTokens() async {
    final config = await fetchDesignSystemConfig();
    return config.tokens;
  }

  DesignSystemConfig _designSystemFromConfig(Map<String, dynamic> config) {
    final uiConfig = config['ui_config'];
    if (uiConfig is! Map) {
      return DesignSystemConfig.defaults();
    }

    final designSystem = uiConfig['designSystem'];
    if (designSystem is! Map) {
      return DesignSystemConfig.defaults();
    }

    final tokens = _tokensFromDesignSystem(designSystem);
    if (tokens.isEmpty) {
      return DesignSystemConfig.defaults();
    }

    return DesignSystemConfig(
      version: DesignSystemConfig.versionFromJson(designSystem['version']),
      tokens: tokens,
    );
  }

  List<DesignToken> _tokensFromDesignSystem(
    Map<dynamic, dynamic> designSystem,
  ) {
    final tokens = designSystem['tokens'];
    if (tokens is! List) {
      return const [];
    }

    return tokens
        .whereType<Map>()
        .map((token) => DesignToken.fromJson(token.cast<String, dynamic>()))
        .where((token) => token.isActive)
        .toList(growable: false);
  }
}
