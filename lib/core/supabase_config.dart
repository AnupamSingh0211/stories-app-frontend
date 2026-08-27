import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  const SupabaseConfig._();

  static String get url => _requiredValue('SUPABASE_URL');
  static String get anonKey => _requiredValue('SUPABASE_ANON_KEY');

  static String appAssetsPublicUrl(String path) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.encodeFull(
      '$url/storage/v1/object/public/app-assets/$normalizedPath',
    );
  }

  static String _requiredValue(String key) {
    final value = dotenv.env[key];

    if (value == null || value.isEmpty) {
      throw StateError('Missing required environment variable: $key');
    }

    return value;
  }
}
