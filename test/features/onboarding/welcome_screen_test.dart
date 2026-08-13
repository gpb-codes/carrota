import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carrota_flutter/features/onboarding/models/onboarding_step.dart';
import 'package:carrota_flutter/features/onboarding/provider/conversation_provider.dart';
import 'package:carrota_flutter/features/onboarding/screens/welcome_screen.dart';

Widget harness(ConversationProvider provider, {VoidCallback? onDone}) {
  return MaterialApp(
    home: WelcomeScreen(provider: provider, onDone: onDone ?? () {}),
  );
}

Future<void> submit(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('campo vacío muestra validación y no agrega mensajes', (
    tester,
  ) async {
    final provider = ConversationProvider();
    await tester.pumpWidget(harness(provider));

    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();

    expect(find.text('Escribe algo para continuar'), findsOneWidget);
    expect(provider.messages, hasLength(1));
    expect(provider.step, OnboardingStep.businessName);
  });

  testWidgets('enviar con teclado produce el mismo resultado que el botón', (
    tester,
  ) async {
    final provider = ConversationProvider();
    await tester.pumpWidget(harness(provider));

    await submit(tester, 'Panadería Sol');

    expect(provider.businessName, 'Panadería Sol');
    expect(provider.step, OnboardingStep.businessType);
    expect(find.text('Panadería Sol'), findsOneWidget);
    expect(find.textContaining('¿A qué se dedica'), findsOneWidget);
  });

  testWidgets(
    'mensajes del usuario se alinean a la derecha y de Lumo a la izquierda',
    (tester) async {
      final provider = ConversationProvider();
      await tester.pumpWidget(harness(provider));

      await submit(tester, 'Panadería Sol');

      final userDx = tester.getTopLeft(find.text('Panadería Sol')).dx;
      final lumoDx = tester
          .getTopLeft(find.textContaining('¿A qué se dedica'))
          .dx;

      expect(userDx, greaterThan(lumoDx));
    },
  );

  testWidgets('al completar el onboarding se ofrece la acción final', (
    tester,
  ) async {
    var done = false;
    final provider = ConversationProvider();
    await tester.pumpWidget(harness(provider, onDone: () => done = true));

    await submit(tester, 'Panadería Sol');
    await submit(tester, 'Venta de pan artesanal');

    expect(find.text('Empezar a hablar con Carrota'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('Empezar a hablar con Carrota'));
    await tester.pump();

    expect(done, isTrue);
  });

  testWidgets('el error se limpia al volver a escribir', (tester) async {
    final provider = ConversationProvider();
    await tester.pumpWidget(harness(provider));

    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();
    expect(find.text('Escribe algo para continuar'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Carrota');
    await tester.pump();

    expect(find.text('Escribe algo para continuar'), findsNothing);
  });
}
