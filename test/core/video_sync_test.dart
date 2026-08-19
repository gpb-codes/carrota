import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:carrota_flutter/core/api.dart';
import 'package:carrota_flutter/core/store.dart';

class _FakeApi extends ApiClient {
  _FakeApi() : super(baseUrl: 'http://fake');

  int createStatus = 200;
  bool updateOk = true;
  bool deleteOk = true;
  int uploadCalls = 0;
  Uint8List? lastUploadBytes;
  String? lastUploadName;
  List<Map<String, dynamic>> mine = [];
  final List<String> created = [];
  final List<String> updated = [];
  final List<String> deleted = [];

  @override
  Future<String?> uploadVideo(
    List<int> bytes, {
    required String filename,
  }) async {
    uploadCalls++;
    lastUploadBytes = Uint8List.fromList(bytes);
    lastUploadName = filename;
    return 'http://fake/uploads/video.mp4';
  }

  @override
  Future<int> createVideo({
    required String productId,
    required String caption,
    required List<String> hashtags,
    required int c1,
    required int c2,
    String? url,
  }) async {
    created.add(productId);
    return createStatus;
  }

  @override
  Future<bool> updateVideo(
    String productId, {
    required String caption,
    required List<String> hashtags,
    required int c1,
    required int c2,
  }) async {
    updated.add(productId);
    return updateOk;
  }

  @override
  Future<bool> deleteVideo(String productId) async {
    deleted.add(productId);
    return deleteOk;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMyVideos() async => mine;
}

void main() {
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 30));

  test(
    'publicar con servidor online sube el archivo y marca el video como sincronizado',
    () async {
      final store = LumoStore();
      final api = _FakeApi();
      store.api = api;
      store.serverOnline = true;
      final tmp = File(
        '${Directory.systemTemp.path}/carrota_test_video_${DateTime.now().microsecondsSinceEpoch}.mp4',
      );
      await tmp.writeAsBytes([1, 2, 3]);

      store.publishVideo(
        productId: 'aguacate',
        caption: 'Mi video',
        hashtags: const ['fresco'],
        price: 30,
        filePath: tmp.path,
      );
      await settle();

      expect(api.uploadCalls, 1);
      expect(api.lastUploadBytes, [1, 2, 3]);
      expect(api.lastUploadName, 'video.mp4');
      expect(api.created, ['aguacate']);
      expect(store.myVideos.first.synced, isTrue);
      await tmp.delete();
    },
  );

  test('publicar con 409 actualiza el video existente del producto', () async {
    final store = LumoStore();
    final api = _FakeApi()..createStatus = 409;
    store.api = api;
    store.serverOnline = true;

    store.publishVideo(
      productId: 'tomate',
      caption: 'Mi video',
      hashtags: const ['fresco'],
      price: 20,
    );
    await settle();

    expect(api.created, ['tomate']);
    expect(api.updated, ['tomate']);
    expect(store.myVideos.first.synced, isTrue);
  });

  test('publicar sin servidor no llama a la API y queda local', () async {
    final store = LumoStore();
    final api = _FakeApi();
    store.api = api;
    store.serverOnline = false;

    store.publishVideo(
      productId: 'limon',
      caption: 'Sin conexión',
      hashtags: const [],
      price: 15,
    );
    await settle();

    expect(api.uploadCalls, 0);
    expect(api.created, isEmpty);
    expect(store.myVideos.first.synced, isFalse);
  });

  test('editar solo sincroniza videos ya publicados en el servidor', () async {
    final store = LumoStore();
    final api = _FakeApi();
    store.api = api;
    store.serverOnline = true;
    store.publishVideo(
      productId: 'lechuga',
      caption: 'Original',
      hashtags: const [],
      price: 10,
    );
    final id = store.myVideos.first.id;
    await settle();
    expect(store.myVideos.first.synced, isTrue);

    store.updateMyVideo(id, caption: 'Editado');
    await settle();
    expect(api.updated, ['lechuga']);

    // un video publicado sin servidor no se sincroniza al editar
    store.serverOnline = false;
    store.publishVideo(
      productId: 'limon',
      caption: 'Local',
      hashtags: const [],
      price: 5,
    );
    final localId = store.myVideos.first.id;
    store.updateMyVideo(localId, caption: 'Local editado');
    await settle();
    expect(api.updated, ['lechuga']);
    expect(store.myVideos.first.caption, 'Local editado');
    expect(store.myVideos.first.synced, isFalse);
  });

  test('eliminar sincroniza solo videos publicados en el servidor', () async {
    final store = LumoStore();
    final api = _FakeApi();
    store.api = api;
    store.serverOnline = true;
    store.publishVideo(
      productId: 'lechuga',
      caption: 'A',
      hashtags: const [],
      price: 10,
    );
    await settle();
    final syncedId = store.myVideos.first.id;

    store.serverOnline = false;
    store.publishVideo(
      productId: 'limon',
      caption: 'B',
      hashtags: const [],
      price: 5,
    );
    final localId = store.myVideos.first.id;

    store.serverOnline = true;
    store.removeMyVideo(syncedId);
    store.removeMyVideo(localId);
    await settle();

    expect(api.deleted, ['lechuga']);
    expect(store.myVideos, isEmpty);
  });

  test('refreshMyVideos mezcla los videos del servidor sin duplicar', () async {
    final store = LumoStore();
    final api = _FakeApi()
      ..mine = [
        {
          'productId': 'aguacate',
          'caption': 'Video remoto',
          'hashtags': ['nuevo'],
          'price': 42,
          'c1': 0xFF9BC94C,
          'c2': 0xFF2F6B2F,
        },
        {
          'productId': 'sin-producto-local',
          'caption': 'No visible',
          'hashtags': <String>[],
          'price': 1,
        },
      ];
    store.api = api;
    store.publishVideo(
      productId: 'limon',
      caption: 'Local',
      hashtags: const [],
      price: 9,
    );
    final localId = store.myVideos.first.id;

    await store.refreshMyVideos();

    expect(store.myVideos, hasLength(2));
    expect(store.myVideos.any((m) => m.id == localId), isTrue);
    final remote = store.myVideos.firstWhere(
      (m) => m.id == 'vid_remote_aguacate',
    );
    expect(remote.caption, 'Video remoto');
    expect(remote.synced, isTrue);
    expect(
      store.myVideos.any((m) => m.productId == 'sin-producto-local'),
      isFalse,
    );
  });
}
