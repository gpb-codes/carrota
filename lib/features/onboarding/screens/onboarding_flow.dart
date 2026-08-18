import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/store.dart';
import '../data/onboarding_storage.dart';
import '../provider/conversation_provider.dart';
import 'summary_screen.dart';
import 'welcome_screen.dart';

/// Flujo completo del onboarding: conversación con Lumo y resumen final.
///
/// Posee el [ConversationProvider] y la [OnboardingStorage]; al terminar
/// persiste los datos, marca el negocio como onboarded y navega al inicio
/// con go_router.
class OnboardingFlow extends StatefulWidget {
  final OnboardingStorage storage;

  const OnboardingFlow({super.key, this.storage = const OnboardingStorage()});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _provider = ConversationProvider();
  bool _showSummary = false;

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final store = LumoScope.of(context);
    await widget.storage.complete(
      businessName: _provider.businessName,
      businessType: _provider.businessType,
    );
    store.setOnboarded(true);
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    if (_showSummary) {
      return SummaryScreen(
        businessName: _provider.businessName,
        businessType: _provider.businessType,
        onDone: _finish,
      );
    }
    return WelcomeScreen(
      provider: _provider,
      onShowSummary: () => setState(() => _showSummary = true),
    );
  }
}
