import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia del onboarding entre sesiones.
///
/// Guarda que la bienvenida ya se completó y los datos del negocio,
/// de modo que no se repite al reiniciar la app.
class OnboardingStorage {
  static const _kOnboarded = 'onboarding.onboarded';
  static const _kBusinessName = 'onboarding.business_name';
  static const _kBusinessType = 'onboarding.business_type';

  const OnboardingStorage();

  Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboarded) ?? false;
  }

  Future<String?> businessName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kBusinessName);
  }

  Future<String?> businessType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kBusinessType);
  }

  Future<void> complete({
    required String businessName,
    required String businessType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboarded, true);
    await prefs.setString(_kBusinessName, businessName);
    await prefs.setString(_kBusinessType, businessType);
  }
}
