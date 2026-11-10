import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStore {
  OnboardingStore._();

  static const String _key = 'parc_onboarding_done_v1';

  static Future<bool> isDone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } catch (_) {
      return true;
    }
  }

  static Future<void> markDone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (_) {}
  }
}
