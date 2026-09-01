import 'design_token.dart';
import 'design_token_defaults.dart';

class DesignSystemConfig {
  const DesignSystemConfig({required this.version, required this.tokens});

  static const fallbackVersion = 1;

  factory DesignSystemConfig.defaults() {
    return const DesignSystemConfig(
      version: fallbackVersion,
      tokens: defaultDesignTokens,
    );
  }

  final int version;
  final List<DesignToken> tokens;

  static int versionFromJson(Object? value) {
    final version = switch (value) {
      int() => value,
      num() => value.toInt(),
      _ => int.tryParse(value?.toString() ?? ''),
    };

    if (version == null || version < fallbackVersion) {
      return fallbackVersion;
    }

    return version;
  }
}
