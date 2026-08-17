import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppPostHogConfig {
  const AppPostHogConfig._();

  static String get projectToken =>
      dotenv.env['POSTHOG_PROJECT_TOKEN']?.trim() ?? '';

  static String get host {
    final value = dotenv.env['POSTHOG_HOST']?.trim();
    return value == null || value.isEmpty
        ? 'https://us.i.posthog.com'
        : value;
  }

  static bool get hasProjectToken => projectToken.isNotEmpty;

  static bool get debug {
    final appEnvironment = dotenv.env['APP_ENV']?.trim().toLowerCase();
    return kDebugMode && appEnvironment != 'production';
  }
}
