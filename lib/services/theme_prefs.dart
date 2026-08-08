import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's light/dark theme choice (defaults to light).
class ThemePrefs {
  static const _darkModeKey = 'dark_mode_enabled';

  Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  Future<void> setDarkMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, enabled);
  }
}
