import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  const SupabaseConfig._();

  static String get url => _requiredValue('SUPABASE_URL');
  static String get anonKey => _requiredValue('SUPABASE_ANON_KEY');

  static String _requiredValue(String key) {
    final value = dotenv.env[key];

    if (value == null || value.isEmpty) {
      throw StateError('Missing required environment variable: $key');
    }

    return value;
  }
}
