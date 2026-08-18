import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:carrota_flutter/core/theme_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('isDark devuelve false por defecto', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await ThemePrefs().isDark(), false);
  });

  test('setDark persiste la elección', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = ThemePrefs();
    await prefs.setDark(true);
    expect(await prefs.isDark(), true);

    final stored = await SharedPreferences.getInstance();
    expect(stored.getBool('theme.dark'), true);
  });

  test('setDark vuelve al modo claro', () async {
    SharedPreferences.setMockInitialValues({'theme.dark': true});
    final prefs = ThemePrefs();
    await prefs.setDark(false);
    expect(await prefs.isDark(), false);
  });
}
