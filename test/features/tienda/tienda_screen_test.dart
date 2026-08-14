import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carrota_flutter/core/store.dart';
import 'package:carrota_flutter/features/tienda/tienda_screen.dart';

void main() {
  Widget wrap() {
    return LumoScope(
      store: LumoStore(),
      child: const MaterialApp(home: Scaffold(body: TiendaScreen())),
    );
  }

  testWidgets('filtra el feed al buscar por nombre', (tester) async {
    await tester.pumpWidget(wrap());

    await tester.enterText(find.byType(TextField), 'tomate');
    await tester.pump();

    expect(find.text('Tomate saladet'), findsOneWidget);
    expect(find.textContaining('1 / 1'), findsOneWidget);
  });

  testWidgets('busca también por etiqueta', (tester) async {
    await tester.pumpWidget(wrap());

    await tester.enterText(find.byType(TextField), '#limon');
    await tester.pump();

    expect(find.text('Limón'), findsOneWidget);
  });

  testWidgets('sin resultados muestra estado vacío', (tester) async {
    await tester.pumpWidget(wrap());

    await tester.enterText(find.byType(TextField), 'xyzabc');
    await tester.pump();

    expect(find.textContaining('Sin resultados'), findsOneWidget);
  });
}
