import 'package:agu_frontend/controllers/controllers.dart';
import 'package:agu_frontend/storage/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the area default when no preference has been stored', () async {
    final storage = _ThemeStorage();
    final mentor = AreaThemeController(
      area: ThemePreferenceArea.mentor,
      defaultDark: true,
      storage: storage,
    );
    final admin = AreaThemeController(
      area: ThemePreferenceArea.admin,
      defaultDark: false,
      storage: storage,
    );

    await mentor.initialize();
    await admin.initialize();

    expect(mentor.brightness, Brightness.dark);
    expect(admin.brightness, Brightness.light);
  });

  test('loads and persists separate mentor and admin choices', () async {
    final storage = _ThemeStorage()..values[ThemePreferenceArea.mentor] = false;
    final mentor = AreaThemeController(
      area: ThemePreferenceArea.mentor,
      defaultDark: true,
      storage: storage,
    );
    final admin = AreaThemeController(
      area: ThemePreferenceArea.admin,
      defaultDark: false,
      storage: storage,
    );

    await mentor.initialize();
    await admin.toggle();

    expect(mentor.brightness, Brightness.light);
    expect(admin.brightness, Brightness.dark);
    expect(storage.values[ThemePreferenceArea.admin], isTrue);
    expect(storage.values[ThemePreferenceArea.mentor], isFalse);
  });
}

class _ThemeStorage implements ThemePreferenceStorage {
  final values = <ThemePreferenceArea, bool>{};

  @override
  Future<bool?> readDarkMode(ThemePreferenceArea area) async => values[area];

  @override
  Future<void> writeDarkMode(ThemePreferenceArea area, bool isDark) async {
    values[area] = isDark;
  }
}
