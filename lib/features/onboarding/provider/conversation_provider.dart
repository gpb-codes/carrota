import 'package:flutter/foundation.dart';

import '../models/chat_message_model.dart';
import '../models/onboarding_step.dart';

/// Estado del onboarding conversacional.
///
/// Conoce el paso actual y decide cómo procesar la siguiente
/// respuesta; la interfaz solo lee propiedades derivadas y le
/// entrega texto mediante [submitAnswer].
class ConversationProvider extends ChangeNotifier {
  OnboardingStep _step = OnboardingStep.businessName;
  String _businessName = '';
  String _businessType = '';
  String? _error;
  final List<ChatMessage> _messages = [
    const ChatMessage.lumo(
      'Hola, soy Lumo. Quiero aprender cómo funciona tu negocio '
      'para ayudarte desde hoy. ¿Cómo se llama?',
    ),
  ];

  OnboardingStep get step => _step;

  String get businessName => _businessName;

  String get businessType => _businessType;

  /// Error de validación de la última respuesta, si lo hay.
  String? get error => _error;

  bool get isCompleted => _step == OnboardingStep.completed;

  /// El campo deja de aceptar entradas al completar el onboarding.
  bool get inputEnabled => !isCompleted;

  /// Nunca se puede mutar la colección desde fuera.
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  String get inputHint => switch (_step) {
    OnboardingStep.businessName => 'Nombre del negocio',
    OnboardingStep.businessType => 'Ej.: cafetería, consultoría…',
    OnboardingStep.completed => '',
  };

  /// Procesa la respuesta según el paso actual.
  ///
  /// Un texto vacío solo muestra el error de validación; cuando el
  /// onboarding está completo, las respuestas se ignoran.
  void submitAnswer(String value) {
    if (!inputEnabled) return;

    final answer = value.trim();
    if (answer.isEmpty) {
      _error = 'Escribe algo para continuar';
      notifyListeners();
      return;
    }

    _error = null;
    _messages.add(ChatMessage.user(answer));

    switch (_step) {
      case OnboardingStep.businessName:
        _businessName = answer;
        _messages.add(
          ChatMessage.lumo(
            'Mucho gusto, $answer. ¿A qué se dedica tu negocio?',
          ),
        );
        _step = OnboardingStep.businessType;
      case OnboardingStep.businessType:
        _businessType = answer;
        _messages.add(
          ChatMessage.lumo('Perfecto. Ya conozco la base de tu negocio.'),
        );
        _step = OnboardingStep.completed;
      case OnboardingStep.completed:
        break;
    }

    notifyListeners();
  }

  /// Quita el error cuando la persona vuelve a escribir.
  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }
}
