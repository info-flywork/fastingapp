import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/remote_images/remote_image_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// 1×1 şeffaf PNG (çözülebilir gerçek görsel).
final Uint8List _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

/// Testte "CDN": istek sayılarını tutar, istenirse bozuk yanıt verir.
final class _FakeCdn {
  late HttpServer _server;
  final Map<String, List<int>> files = {};
  final Map<String, int> hits = {};
  bool corrupt = false;

  Uri get baseUrl => Uri.parse('http://127.0.0.1:${_server.port}/app-images/');
  int get totalHits => hits.values.fold(0, (a, b) => a + b);

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((req) async {
      final name = req.uri.pathSegments.last;
      hits[name] = (hits[name] ?? 0) + 1;
      final body = files[name];
      if (body == null) {
        req.response.statusCode = HttpStatus.notFound;
      } else {
        req.response.add(corrupt ? [...body.take(body.length - 1), 0] : body);
      }
      await req.response.close();
    });
  }

  Future<void> stop() => _server.close(force: true);
}

final class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.assets);

  final Map<String, List<int>> assets;

  @override
  Future<ByteData> load(String key) async {
    final bytes = assets[key];
    if (bytes == null) throw FlutterError('asset yok: $key');
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

void main() {
  late _FakeCdn cdn;
  late Directory cacheRoot;
  final stores = <RemoteImageStore>[];

  /// `remote` görselleri CDN'e konur ve manifeste yazılır.
  RemoteImageStore newStore({
    required Map<String, List<int>> remote,
    Map<String, String> bundled = const {},
    Map<String, List<int>> bundleAssets = const {},
  }) {
    final images = <String, Object>{};
    for (final MapEntry(:key, :value) in remote.entries) {
      final sha = sha256.convert(value).toString();
      final file = '${sha.substring(0, 20)}.webp';
      cdn.files[file] = value;
      images[key] = {'file': file, 'bytes': value.length, 'sha256': sha};
    }
    for (final MapEntry(:key, :value) in bundled.entries) {
      images[key] = {'bundled': value};
    }
    final manifest = jsonEncode({
      'version': 1,
      'baseUrl': cdn.baseUrl.toString(),
      'images': images,
    });
    final store = RemoteImageStore(
      bundle: _FakeBundle({
        RemoteImageStore.manifestAsset: utf8.encode(manifest),
        ...bundleAssets,
      }),
      cacheDirectory: () async => cacheRoot,
    );
    stores.add(store);
    return store;
  }

  List<String> cachedFiles() => Directory(
    '${cacheRoot.path}/remote_images',
  ).listSync().map((e) => e.uri.pathSegments.last).toList();

  setUp(() async {
    // flutter_test HttpClient'ı sahtesiyle değiştirir; bu testler gerçek
    // yerel sunucuya bağlanır.
    HttpOverrides.global = null;
    cdn = _FakeCdn();
    await cdn.start();
    cacheRoot = await Directory.systemTemp.createTemp('remote_images_test');
  });

  tearDown(() async {
    for (final s in stores) {
      s.close();
    }
    stores.clear();
    await cdn.stop();
    await cacheRoot.delete(recursive: true);
  });

  test(
    'ilk açılışta hepsini indirir; sonraki açılışta hiç ağ isteği yok',
    () async {
      final remote = {
        'assets/images/a.png': [1, 2, 3],
        'assets/images/b.png': [4, 5, 6, 7],
        'assets/images/c.png': List.filled(5000, 9),
      };
      final first = newStore(remote: remote);
      await first.syncInBackground();
      expect(cdn.totalHits, 3);
      expect(cachedFiles(), hasLength(3));

      // Uygulama yeniden açıldı: yeni örnek, aynı klasör.
      final second = newStore(remote: remote);
      await second.syncInBackground();
      expect(await second.load('assets/images/b.png'), [4, 5, 6, 7]);
      expect(cdn.totalHits, 3);
    },
  );

  test(
    'ekrana erken gelen görsel o an indirilir; eşzamanlı istekler tek indirme',
    () async {
      final store = newStore(remote: {'assets/images/a.png': _pixel});
      final results = await Future.wait([
        store.load('assets/images/a.png'),
        store.load('assets/images/a.png'),
        store.syncInBackground().then((_) => store.load('assets/images/a.png')),
      ]);
      expect(results.every((r) => r.length == _pixel.length), isTrue);
      expect(cdn.totalHits, 1);
    },
  );

  test('bozuk yanıt kaydedilmez, hata verir; düzelince indirilir', () async {
    final store = newStore(
      remote: {
        'assets/images/a.png': [1, 2, 3, 4],
      },
    );
    cdn.corrupt = true;
    await expectLater(
      store.load('assets/images/a.png'),
      throwsA(isA<RemoteImageException>()),
    );
    expect(cachedFiles(), isEmpty);

    cdn.corrupt = false;
    expect(await store.load('assets/images/a.png'), [1, 2, 3, 4]);
    expect(cachedFiles(), hasLength(1));
  });

  test('manifestte olmayan eski dosyalar silinir', () async {
    final dir = Directory('${cacheRoot.path}/remote_images')
      ..createSync(recursive: true);
    File('${dir.path}/eski-surum.webp').writeAsBytesSync([0]);
    final store = newStore(
      remote: {
        'assets/images/a.png': [1],
      },
    );
    await store.syncInBackground();
    expect(cachedFiles(), [isNot('eski-surum.webp')]);
  });

  test('gömülü ve manifest dışı görseller uygulama içinden okunur', () async {
    final store = newStore(
      remote: const {},
      bundled: {'assets/images/App Icon.png': 'assets/images/bundled/a.webp'},
      bundleAssets: {
        'assets/images/bundled/a.webp': [7, 7],
        'assets/images/mochi/bench.webp': [8],
      },
    );
    expect(await store.load('assets/images/App Icon.png'), [7, 7]);
    expect(await store.load('assets/images/mochi/bench.webp'), [8]);
    expect(cdn.totalHits, 0);
  });

  testWidgets('AppImageProvider indirilmiş dosyayı çözer ve gösterir', (
    tester,
  ) async {
    final store = newStore(remote: {'assets/images/a.png': _pixel});
    await tester.runAsync(() async {
      // Testlerde HttpClient sahte; dosya önce gerçek ağ olmadan yerleştirilir.
      await store.ensureInitialized();
      final entry = store.entryFor('assets/images/a.png')!;
      File(
        '${cacheRoot.path}/remote_images/${entry.file}',
      ).writeAsBytesSync(_pixel);
    });
    final previous = RemoteImageStore.instance;
    RemoteImageStore.instance = newStore(
      remote: {'assets/images/a.png': _pixel},
    );
    addTearDown(() => RemoteImageStore.instance = previous);

    final info = await tester.runAsync(() async {
      final stream = const AppImageProvider(
        'assets/images/a.png',
      ).resolve(ImageConfiguration.empty);
      final completer = Completer<ImageInfo>();
      stream.addListener(
        ImageStreamListener(
          (image, _) => completer.complete(image),
          onError: completer.completeError,
        ),
      );
      return completer.future;
    });
    expect(info!.image.width, 1);
    expect(info.image.height, 1);
  });
}
