import 'package:shared_preferences/shared_preferences.dart';

/// Persiste el modo oscuro elegido por el usuario.
class ThemePrefs {
  static const _key = 'theme.dark';

  Future<bool> isDark() async =>
      (await SharedPreferences.getInstance()).getBool(_key) ?? false;

  Future<void> setDark(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
