import 'package:flutter_dotenv/flutter_dotenv.dart';

class BackendConfig {
  const BackendConfig._();

  static String get baseUrl {
    final value = dotenv.env['BACKEND_BASE_URL']?.trim();
    if (value == null || value.isEmpty) {
      throw StateError(
        'Missing required environment variable: BACKEND_BASE_URL',
      );
    }

    return value.replaceFirst(RegExp(r'/+$'), '');
  }
}
