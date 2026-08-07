import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether first-launch onboarding has been completed.
/// Cleared only when the app is uninstalled or app data is wiped.
class OnboardingPrefs {
  static const _completedKey = 'onboarding_completed';

  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  Future<void> setCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
  }
}
