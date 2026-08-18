import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carrota_flutter/core/store.dart';
import 'package:carrota_flutter/features/negocio/negocio_screen.dart';

void main() {
  Widget wrap({required bool darkMode, required ValueChanged<bool> onToggle}) {
    return LumoScope(
      store: LumoStore(),
      child: MaterialApp(
        home: Scaffold(
          body: NegocioScreen(
            onOpenProduct: (_) {},
            onOpenShopping: () {},
            darkMode: darkMode,
            onToggleTheme: onToggle,
          ),
        ),
      ),
    );
  }

  testWidgets('muestra la fila de modo oscuro con el estado actual', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(darkMode: false, onToggle: (_) {}));

    expect(find.text('Modo oscuro'), findsOneWidget);
    final sw = tester.widget<Switch>(
      find.byKey(const ValueKey('theme-switch')),
    );
    expect(sw.value, false);
  });

  testWidgets('alternar el switch avisa al padre', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    bool? toggled;
    await tester.pumpWidget(wrap(darkMode: true, onToggle: (v) => toggled = v));

    await tester.tap(find.byKey(const ValueKey('theme-switch')));
    expect(toggled, false);
  });
}
