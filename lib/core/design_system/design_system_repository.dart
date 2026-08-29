import 'design_token.dart';
import 'design_token_defaults.dart';

class DesignSystemRepository {
  const DesignSystemRepository();

  Future<List<DesignToken>> fetchDesignTokens() async {
    return defaultDesignTokens;
  }
}
