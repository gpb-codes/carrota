import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carrota_flutter/core/store.dart';
import 'package:carrota_flutter/features/tienda/my_videos_sheet.dart';
import 'package:carrota_flutter/features/tienda/publish_video_sheet.dart';
import 'package:carrota_flutter/features/tienda/tienda_screen.dart';

void main() {
  XFile mockVideo() => XFile.fromData(
    Uint8List.fromList(const [0, 0, 0, 0]),
    mimeType: 'video/mp4',
  );

  testWidgets('publica un video nuevo con producto, descripción y precio', (
    tester,
  ) async {
    final store = LumoStore();
    await tester.pumpWidget(
      LumoScope(
        store: store,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      fullscreenDialog: true,
                      builder: (_) => PublishVideoSheet(video: mockVideo()),
                    ),
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Publicar video'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('caption-field')),
      'Aguacate cremoso de Milpa Verde',
    );
    await tester.enterText(
      find.byKey(const ValueKey('hashtags-field')),
      '#aguacate, #fresco',
    );
    await tester.pump();

    final product = store.products.first;
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('price-field')))
          .controller!
          .text,
      '${product.price}',
    );

    await tester.tap(find.text('Publicar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(store.myVideos, hasLength(1));
    final v = store.myVideos.first;
    expect(v.caption, 'Aguacate cremoso de Milpa Verde');
    expect(v.hashtags, ['aguacate', 'fresco']);
    expect(v.productId, product.id);
    expect(v.price, product.price);
  });

  testWidgets('edita un video publicado y guarda los cambios', (tester) async {
    final store = LumoStore();
    final product = store.products.first;
    store.publishVideo(
      productId: product.id,
      caption: 'Video original',
      hashtags: ['fresco'],
      price: 25,
    );
    final id = store.myVideos.first.id;

    await tester.pumpWidget(
      LumoScope(
        store: store,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      fullscreenDialog: true,
                      builder: (_) =>
                          PublishVideoSheet(editing: store.myVideos.first),
                    ),
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Editar video'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('caption-field')),
      'Video mejorado',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(store.myVideos, hasLength(1));
    expect(store.myVideos.first.id, id);
    expect(store.myVideos.first.caption, 'Video mejorado');
    expect(store.myVideos.first.price, 25);
  });

  testWidgets('elimina un video desde Mis videos con confirmación', (
    tester,
  ) async {
    final store = LumoStore();
    final product = store.products.first;
    store.publishVideo(
      productId: product.id,
      caption: 'Video a eliminar',
      hashtags: const [],
      price: 10,
    );
    expect(store.myVideos, hasLength(1));

    await tester.pumpWidget(
      LumoScope(
        store: store,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showMyVideosSheet(context),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Mis videos'), findsOneWidget);
    expect(find.text('Video a eliminar'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));
    await tester.pumpAndSettle();

    expect(store.myVideos, isEmpty);
    expect(find.text('Aún no has publicado videos'), findsOneWidget);
  });

  testWidgets('el feed muestra el video publicado con su etiqueta Tuyo', (
    tester,
  ) async {
    final store = LumoStore();
    final product = store.products.first;
    store.publishVideo(
      productId: product.id,
      caption: 'Mi primer video',
      hashtags: ['nuevo'],
      price: 30,
    );

    await tester.pumpWidget(
      LumoScope(
        store: store,
        child: const MaterialApp(home: Scaffold(body: TiendaScreen())),
      ),
    );
    await tester.pump();

    expect(find.text('Tuyo'), findsOneWidget);
    expect(find.text('Mi primer video'), findsOneWidget);
    expect(find.text('1 / ${store.feedVideos.length}'), findsOneWidget);
  });
}
