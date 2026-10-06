import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStore {
  const OnboardingStore._();

  static const completedKey = 'onboarding.completed';
  static const notificationsKey = 'onboarding.notifications_allowed';

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(completedKey) ?? false;
  }

  static Future<bool> notificationsAllowed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(notificationsKey) ?? false;
  }

  static Future<void> complete({required bool notificationsAllowed}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(completedKey, true);
    await prefs.setBool(notificationsKey, notificationsAllowed);
  }
}
