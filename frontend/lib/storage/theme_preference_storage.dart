import 'package:shared_preferences/shared_preferences.dart';

enum ThemePreferenceArea { mentor, admin }

abstract interface class ThemePreferenceStorage {
  Future<bool?> readDarkMode(ThemePreferenceArea area);
  Future<void> writeDarkMode(ThemePreferenceArea area, bool isDark);
}

class SharedPreferencesThemePreferenceStorage
    implements ThemePreferenceStorage {
  const SharedPreferencesThemePreferenceStorage();

  @override
  Future<bool?> readDarkMode(ThemePreferenceArea area) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_key(area));
  }

  @override
  Future<void> writeDarkMode(ThemePreferenceArea area, bool isDark) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_key(area), isDark);
  }

  String _key(ThemePreferenceArea area) => 'theme_${area.name}_dark';
}
