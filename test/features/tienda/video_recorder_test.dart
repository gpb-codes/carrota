import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carrota_flutter/core/store.dart';
import 'package:carrota_flutter/features/tienda/tienda_screen.dart';
import 'package:carrota_flutter/features/tienda/video_recorder_sheet.dart';

void main() {
  Widget host({required void Function(XFile) onRecorded}) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) => VideoRecorderSheet(onRecorded: onRecorded),
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('graba en modo simulado y entrega el video al publicar', (
    tester,
  ) async {
    XFile? captured;
    await tester.pumpWidget(host(onRecorded: (v) => captured = v));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.byType(VideoRecorderSheet), findsOneWidget);
    expect(find.text('00:00'), findsNothing);

    final btn = find.byKey(const ValueKey('record-btn'));
    await tester.tap(btn);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:01'), findsOneWidget);

    await tester.tap(btn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Publicar'));
    await tester.pump();

    expect(captured, isNotNull);
    expect(captured!.mimeType, 'video/mp4');
  });

  testWidgets('el botón de grabar en Tienda abre el grabador', (tester) async {
    await tester.pumpWidget(
      LumoScope(
        store: LumoStore(),
        child: const MaterialApp(home: Scaffold(body: TiendaScreen())),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('record-btn')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(VideoRecorderSheet), findsOneWidget);
  });
}
