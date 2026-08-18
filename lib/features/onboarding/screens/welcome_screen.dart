import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/brand.dart';
import '../models/chat_message_model.dart';
import '../provider/conversation_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/lumo_header.dart';
import '../widgets/onboarding_input.dart';

/// Pantalla de bienvenida: conversación inicial con Lumo.
///
/// Coordina el [ConversationProvider] con la interfaz: la lista se
/// desplaza al último mensaje, el envío funciona con botón y teclado,
/// y al completar el flujo se ofrece una acción final.
class WelcomeScreen extends StatefulWidget {
  final ConversationProvider provider;

  /// Se llama cuando la persona pide ver el resumen tras completar.
  final VoidCallback onShowSummary;

  const WelcomeScreen({
    super.key,
    required this.provider,
    required this.onShowSummary,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submit() {
    widget.provider.submitAnswer(_controller.text);
    _controller.clear();
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.provider,
          builder: (context, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const LumoHeader(),
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    children: [
                      for (final ChatMessage m in widget.provider.messages)
                        ChatBubble(message: m),
                    ],
                  ),
                ),
                if (!widget.provider.isCompleted)
                  OnboardingInput(
                    controller: _controller,
                    hintText: widget.provider.inputHint,
                    enabled: widget.provider.inputEnabled,
                    errorText: widget.provider.error,
                    onChanged: (_) => widget.provider.clearError(),
                    onSubmitted: _submit,
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    child: GradientChip(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onShowSummary,
                          borderRadius: BorderRadius.circular(16),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: Text(
                                'Ver mi resumen',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
