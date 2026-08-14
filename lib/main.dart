import 'package:flutter/material.dart';

import 'app/app.dart';
import 'features/onboarding/data/onboarding_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final onboarded = await const OnboardingStorage().isOnboarded();
  runApp(CarrotaApp(initialLocation: onboarded ? '/' : '/onboarding'));
}
