import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'assets_provider.g.dart';

@riverpod
Map<String, String> appAssets(AppAssetsRef ref) {
  final storage = Supabase.instance.client.storage.from('app-assets');

  return {
    'welcome_bg': storage.getPublicUrl('backgrounds/welcome_bg.png'),
    'profile_setup_bg': storage.getPublicUrl(
      'backgrounds/profileSetup_bg.jpg',
    ),
    'ios_icon': storage.getPublicUrl('icons/ios_icon.png'),
    'google_icon': storage.getPublicUrl('icons/google_icon.png'),
    'email_icon': storage.getPublicUrl('icons/email_icon.png'),
  };
}
