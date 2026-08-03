import 'package:flutter/material.dart';

import '../storage/storage.dart';
import 'feature_controller.dart';

class AreaThemeController extends FeatureController {
  AreaThemeController({
    required this.area,
    required bool defaultDark,
    ThemePreferenceStorage? storage,
  }) : _isDark = defaultDark,
       _storage = storage ?? const SharedPreferencesThemePreferenceStorage();

  final ThemePreferenceArea area;
  final ThemePreferenceStorage _storage;
  bool _isDark;

  bool get isDark => _isDark;
  Brightness get brightness => _isDark ? Brightness.dark : Brightness.light;

  Future<void> initialize() async {
    final request = beginRequest();
    bool? storedValue;
    try {
      storedValue = await _storage.readDarkMode(area);
    } catch (_) {
      return;
    }
    if (!requestIsCurrent(request) || storedValue == null) return;
    _isDark = storedValue;
    notifyListeners();
  }

  Future<void> toggle() async {
    invalidateRequests();
    _isDark = !_isDark;
    notifyListeners();
    try {
      await _storage.writeDarkMode(area, _isDark);
    } catch (_) {
      // The selected theme still applies for the current session.
    }
  }
}
