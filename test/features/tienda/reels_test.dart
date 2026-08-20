import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carrota_flutter/core/store.dart';
import 'package:carrota_flutter/features/tienda/tienda_screen.dart';
import 'package:carrota_flutter/features/tienda/video_recorder_sheet.dart';

void main() {
  Widget feed() {
    return LumoScope(
      store: LumoStore(),
      child: const MaterialApp(home: Scaffold(body: TiendaScreen())),
    );
  }

  testWidgets('reels: badge En tendencia y contador de vistas', (tester) async {
    final store = LumoStore();
    await tester.pumpWidget(
      LumoScope(
        store: store,
        child: const MaterialApp(home: Scaffold(body: TiendaScreen())),
      ),
    );

    expect(find.text('🔥 En tendencia'), findsOneWidget);
    expect(find.textContaining('vistas'), findsOneWidget);
    expect(find.text('15.4 k vistas'), findsOneWidget);
  });

  testWidgets('reels: doble tap da like', (tester) async {
    final store = LumoStore();
    await tester.pumpWidget(
      LumoScope(
        store: store,
        child: const MaterialApp(home: Scaffold(body: TiendaScreen())),
      ),
    );

    final center = Offset(400, 180);
    final g1 = await tester.startGesture(center);
    await g1.up();
    await tester.pump(const Duration(milliseconds: 100));
    final g2 = await tester.startGesture(center);
    await g2.up();
    await tester.pump(const Duration(milliseconds: 400));

    expect(store.likedVideos.contains('aguacate'), isTrue);
  });

  testWidgets('reels: seguir proveedor alterna', (tester) async {
    final store = LumoStore();
    await tester.pumpWidget(
      LumoScope(
        store: store,
        child: const MaterialApp(home: Scaffold(body: TiendaScreen())),
      ),
    );

    await tester.tap(find.text('Seguir'));
    await tester.pump();

    expect(store.isFollowing('Milpa Verde'), isTrue);
    expect(find.text('Siguiendo'), findsOneWidget);
  });

  testWidgets('reels: mute alterna el ícono de sonido', (tester) async {
    await tester.pumpWidget(feed());

    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.volume_up_rounded));
    await tester.pump();
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.volume_off_rounded));
    await tester.pump();
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
  });

  testWidgets('reels: pantalla completa se abre y cierra', (tester) async {
    await tester.pumpWidget(feed());

    await tester.tap(find.byIcon(Icons.fullscreen_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.text('Aguacate'), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(TiendaScreen), findsOneWidget);
  });

  Widget recorderHost() {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) => VideoRecorderSheet(onRecorded: (_) {}),
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('grabar: velocidad 2x avanza el reloj el doble', (tester) async {
    await tester.pumpWidget(recorderHost());
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('2x'));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('record-btn')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('00:02'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('record-btn')));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('2x'), findsOneWidget);
  });

  testWidgets('grabar: temporizador cuenta regresiva y graba solo', (
    tester,
  ) async {
    await tester.pumpWidget(recorderHost());
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('3s'));
    await tester.pump();

    expect(find.text('3'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('00:00'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('record-btn')));
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('grabar: cuadrícula y filtro se aplican', (tester) async {
    await tester.pumpWidget(recorderHost());
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.grid_off_rounded));
    await tester.pump();
    expect(find.byIcon(Icons.grid_on_rounded), findsOneWidget);

    await tester.tap(find.byTooltip('Vintage'));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('record-btn')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const ValueKey('record-btn')));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Vintage'), findsOneWidget);
    expect(find.textContaining('Vista previa'), findsOneWidget);
  });
}
