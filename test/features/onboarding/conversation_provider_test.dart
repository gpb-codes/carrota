import 'package:flutter_test/flutter_test.dart';

import 'package:carrota_flutter/features/onboarding/models/chat_message_model.dart';
import 'package:carrota_flutter/features/onboarding/models/onboarding_step.dart';
import 'package:carrota_flutter/features/onboarding/provider/conversation_provider.dart';

void main() {
  group('ConversationProvider', () {
    test('inicia solicitando el nombre del negocio', () {
      final provider = ConversationProvider();

      expect(provider.step, OnboardingStep.businessName);
      expect(provider.messages, hasLength(1));
      expect(provider.messages.single.type, MessageType.lumo);
      expect(provider.error, isNull);
      expect(provider.inputHint, 'Nombre del negocio');
    });

    test('la primera respuesta guarda el nombre y avanza a businessType', () {
      final provider = ConversationProvider();

      provider.submitAnswer('Panadería Sol');

      expect(provider.businessName, 'Panadería Sol');
      expect(provider.step, OnboardingStep.businessType);
      expect(provider.messages, hasLength(3));
      expect(provider.messages.last.text, contains('¿A qué se dedica'));
    });

    test('la segunda respuesta completa el onboarding', () {
      final provider = ConversationProvider();

      provider.submitAnswer('Panadería Sol');
      provider.submitAnswer('Venta de pan artesanal');

      expect(provider.businessType, 'Venta de pan artesanal');
      expect(provider.step, OnboardingStep.completed);
      expect(provider.isCompleted, isTrue);
      expect(provider.inputEnabled, isFalse);
      expect(provider.messages.last.text, contains('base de tu negocio'));
    });

    test('una respuesta vacía muestra error y no agrega mensajes', () {
      final provider = ConversationProvider();

      provider.submitAnswer('   ');

      expect(provider.error, 'Escribe algo para continuar');
      expect(provider.step, OnboardingStep.businessName);
      expect(provider.messages, hasLength(1));
    });

    test('clearError quita la validación', () {
      final provider = ConversationProvider();

      provider.submitAnswer(' ');
      provider.clearError();

      expect(provider.error, isNull);
    });

    test('tras completar, submitAnswer no cambia el estado', () {
      final provider = ConversationProvider();

      provider.submitAnswer('Panadería Sol');
      provider.submitAnswer('Venta de pan');
      final messagesAfterCompletion = provider.messages.length;

      provider.submitAnswer('Otra cosa');

      expect(provider.businessType, 'Venta de pan');
      expect(provider.messages, hasLength(messagesAfterCompletion));
      expect(provider.step, OnboardingStep.completed);
    });

    test('inputHint sigue el paso actual', () {
      final provider = ConversationProvider();

      expect(provider.inputHint, 'Nombre del negocio');

      provider.submitAnswer('Panadería Sol');

      expect(provider.inputHint, contains('cafetería'));

      provider.submitAnswer('Venta de pan');

      expect(provider.inputHint, isEmpty);
    });

    test('messages se entrega como lista inmodificable', () {
      final provider = ConversationProvider();

      expect(() => provider.messages.clear(), throwsUnsupportedError);
    });
  });
}
