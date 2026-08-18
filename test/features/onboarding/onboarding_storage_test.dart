import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:carrota_flutter/features/onboarding/data/onboarding_storage.dart';

void main() {
  group('OnboardingStorage', () {
    test('empieza sin onboarding completado', () async {
      SharedPreferences.setMockInitialValues({});

      expect(await const OnboardingStorage().isOnboarded(), isFalse);
      expect(await const OnboardingStorage().businessName(), isNull);
      expect(await const OnboardingStorage().businessType(), isNull);
    });

    test('complete() guarda el estado y los datos del negocio', () async {
      SharedPreferences.setMockInitialValues({});
      const storage = OnboardingStorage();

      await storage.complete(
        businessName: 'Panadería Sol',
        businessType: 'Venta de pan artesanal',
      );

      expect(await storage.isOnboarded(), isTrue);
      expect(await storage.businessName(), 'Panadería Sol');
      expect(await storage.businessType(), 'Venta de pan artesanal');
    });

    test('persiste entre instancias (misma sesión de prefs)', () async {
      SharedPreferences.setMockInitialValues({});
      await const OnboardingStorage().complete(
        businessName: 'Huerto Norte',
        businessType: 'Huerto urbano y tienda sostenible',
      );

      final otra = OnboardingStorage();
      expect(await otra.isOnboarded(), isTrue);
      expect(await otra.businessName(), 'Huerto Norte');
    });
  });
}
