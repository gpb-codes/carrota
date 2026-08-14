import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carrota_flutter/features/onboarding/screens/summary_screen.dart';

void main() {
  testWidgets('muestra el nombre y la actividad capturados', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SummaryScreen(
          businessName: 'Panadería Sol',
          businessType: 'Venta de pan artesanal',
          onDone: () {},
        ),
      ),
    );

    expect(find.text('Panadería Sol'), findsOneWidget);
    expect(find.text('Venta de pan artesanal'), findsOneWidget);
    expect(find.text('Ya conozco tu negocio'), findsOneWidget);
  });

  testWidgets('el botón final llama a onDone', (tester) async {
    var done = false;
    await tester.pumpWidget(
      MaterialApp(
        home: SummaryScreen(
          businessName: 'Panadería Sol',
          businessType: 'Venta de pan artesanal',
          onDone: () => done = true,
        ),
      ),
    );

    await tester.tap(find.text('Empezar a hablar con Carrota'));
    await tester.pump();

    expect(done, isTrue);
  });
}
