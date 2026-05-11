import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'assets_provider.g.dart';

@Riverpod(keepAlive: true)
Map<String, String> appAssets(AppAssetsRef ref) {
  final storage = Supabase.instance.client.storage.from('app-assets');

  return {
    'welcome_bg': storage.getPublicUrl('backgrounds/welcome_bg.webp'),
    'profile_setup_bg': storage.getPublicUrl(
      'backgrounds/profileSetup_bg.webp',
    ),
    'ios_icon': storage.getPublicUrl('icons/ios_icon.png'),
    'google_icon': storage.getPublicUrl('icons/google_icon.png'),
    'email_icon': storage.getPublicUrl('icons/email_icon.png'),
    'companion_krishna': storage.getPublicUrl('companions/comp_krishna.webp'),
    'companion_hanuman': storage.getPublicUrl('companions/comp_hanuman.webp'),
    'companion_shiva': storage.getPublicUrl('companions/comp_shiva.webp'),
    'companion_ganesha': storage.getPublicUrl('companions/comp_ganesha.webp'),
    'companion_bheem': storage.getPublicUrl('companions/comp_bheem.webp'),
    'companion_arjun': storage.getPublicUrl('companions/comp_arjun.webp'),
  };
}
