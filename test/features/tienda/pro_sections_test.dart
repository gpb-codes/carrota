import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carrota_flutter/core/data.dart';
import 'package:carrota_flutter/core/store.dart';
import 'package:carrota_flutter/features/sheets/cart_sheet.dart';
import 'package:carrota_flutter/features/sheets/product_sheet.dart';
import 'package:carrota_flutter/features/tienda/tienda_screen.dart';

void main() {
  testWidgets('sección Favoritos filtra el feed', (tester) async {
    final store = LumoStore();
    await tester.pumpWidget(
      LumoScope(
        store: store,
        child: const MaterialApp(home: Scaffold(body: TiendaScreen())),
      ),
    );

    store.toggleFavorite('tomate');
    await tester.pump();

    await tester.tap(find.text('Favoritos'));
    await tester.pump();

    expect(find.textContaining('1 / 1'), findsOneWidget);
    expect(find.text('Tomate saladet'), findsOneWidget);
  });

  testWidgets('sección Más vendidos ordena por ranking', (tester) async {
    final store = LumoStore();
    await tester.pumpWidget(
      LumoScope(
        store: store,
        child: const MaterialApp(home: Scaffold(body: TiendaScreen())),
      ),
    );

    await tester.tap(find.text('Más vendidos'));
    await tester.pump();

    expect(find.textContaining('1 / '), findsOneWidget);
    expect(find.text('Aguacate'), findsOneWidget);
  });

  testWidgets('cupón válido se aplica y se puede quitar', (tester) async {
    final store = LumoStore();
    store.addToCart('tomate');
    await tester.pumpWidget(
      LumoScope(
        store: store,
        child: const MaterialApp(home: Scaffold(body: CartSheet())),
      ),
    );

    await tester.enterText(find.byType(TextField), 'fresco10');
    await tester.tap(find.text('Aplicar'));
    await tester.pump();

    expect(find.text('Cupón FRESCO10 aplicado'), findsOneWidget);
    expect(find.text(mxn(store.cartPayable)), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    expect(find.textContaining('FRESCO10'), findsOneWidget);
  });

  testWidgets('cupón inválido muestra error', (tester) async {
    final store = LumoStore();
    store.addToCart('tomate');
    await tester.pumpWidget(
      LumoScope(
        store: store,
        child: const MaterialApp(home: Scaffold(body: CartSheet())),
      ),
    );

    await tester.enterText(find.byType(TextField), 'nada');
    await tester.tap(find.text('Aplicar'));
    await tester.pump();

    expect(find.textContaining('Cupón no válido'), findsOneWidget);
  });

  testWidgets('producto: favorito, estrellas y relacionados', (tester) async {
    final store = LumoStore();
    await tester.pumpWidget(
      LumoScope(
        store: store,
        child: const MaterialApp(
          home: Scaffold(body: ProductSheet(productId: 'lechuga')),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.favorite_outline_rounded));
    await tester.pump();
    expect(store.isFavorite('lechuga'), isTrue);

    await tester.tap(find.byIcon(Icons.star_outline_rounded).first);
    await tester.pump();
    expect(store.ratingCountFor('lechuga'), 3);

    expect(find.text('RESEÑAS DE CLIENTES'), findsOneWidget);
    expect(find.text('También te puede interesar'), findsOneWidget);
  });
}
