import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/onboarding/screens/onboarding_flow.dart';

/// Rutas de la app con go_router.
///
/// - `/` → shell principal (inicio, hoy, tienda, memoria, negocio)
/// - `/onboarding` → conversación de bienvenida con Lumo
class AppRouter {
  static GoRouter create({
    required String initialLocation,
    required WidgetBuilder shellBuilder,
  }) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/', builder: (context, state) => shellBuilder(context)),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingFlow(),
        ),
      ],
    );
  }
}
