import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fastingapp/core/connectivity/connectivity_service.dart';
import 'package:fastingapp/core/connectivity/offline_gate.dart';
import 'package:fastingapp/presentation/no_internet/view/no_internet_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sonucu testten kontrol edilen ulaşılabilirlik yoklaması.
final class _Probe {
  bool online = true;
  int calls = 0;
  Completer<void>? gate;

  Future<bool> call() async {
    calls++;
    await gate?.future;
    return online;
  }
}

void main() {
  late StreamController<List<ConnectivityResult>> changes;
  late _Probe probe;
  late ConnectivityService service;

  setUp(() {
    changes = StreamController.broadcast();
    probe = _Probe();
    service = ConnectivityService(
      changes: changes.stream,
      probe: probe.call,
      retryInterval: const Duration(milliseconds: 20),
      offlineDebounce: const Duration(milliseconds: 20),
      // Testlerde açılış grace'i kapalı; gerçek uygulama 2 sn bekler.
      startupGrace: Duration.zero,
    );
  });

  tearDown(() async {
    await service.dispose();
    await changes.close();
  });

  test(
    'açılışta internet yoksa çevrimdışı; gelince kendiliğinden düzelir',
    () async {
      probe.online = false;
      service.start();
      await pumpEventQueue();
      // Offline debounce bitmeden hâlâ çevrimiçi varsayılır.
      expect(service.isOnline.value, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(service.isOnline.value, isFalse);

      probe.online = true;
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(service.isOnline.value, isTrue);
      expect(service.reconnects.value, 1);
    },
  );

  test('ağ kapanınca debounce sonrası çevrimdışı; kısa none blip yanıp sönmez', () async {
    service.start();
    await pumpEventQueue();
    final before = probe.calls;

    // Anlık none → hemen wifi: offline sayfası açılmaz.
    changes.add([ConnectivityResult.none]);
    await pumpEventQueue();
    expect(service.isOnline.value, isTrue);
    changes.add([ConnectivityResult.wifi]);
    await pumpEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(service.isOnline.value, isTrue);

    // Kalıcı none: debounce sonrası çevrimdışı.
    changes.add([ConnectivityResult.none]);
    await pumpEventQueue();
    expect(service.isOnline.value, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(service.isOnline.value, isFalse);
    expect(probe.calls, greaterThanOrEqualTo(before));
  });

  test('açılış probe sürerken none olayı offline flash yapmaz', () async {
    probe.gate = Completer();
    service.start();
    await pumpEventQueue();
    expect(service.isChecking.value, isTrue);
    expect(service.isOnline.value, isTrue);

    // Soğuk açılış blip'i: probe bitmeden none gelirse ertele.
    changes.add([ConnectivityResult.none]);
    await pumpEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(service.isOnline.value, isTrue);

    probe.online = true;
    probe.gate!.complete();
    await pumpEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(service.isOnline.value, isTrue);
  });

  test('startup grace: ilk saniyelerde offline UI uygulanmaz', () async {
    final gated = ConnectivityService(
      changes: changes.stream,
      probe: probe.call,
      retryInterval: const Duration(milliseconds: 20),
      offlineDebounce: const Duration(milliseconds: 20),
      startupGrace: const Duration(milliseconds: 80),
    );
    addTearDown(gated.dispose);

    probe.online = false;
    gated.start();
    await pumpEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    // Grace bitmeden çevrimdışı sayfa açılmaz.
    expect(gated.isOnline.value, isTrue);

    await Future<void>.delayed(const Duration(milliseconds: 80));
    // Grace sonrası checkNow → debounce → offline.
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(gated.isOnline.value, isFalse);
  });

  test('eşzamanlı kontroller tek yoklamada birleşir; kontrol sırasında '
      'isChecking true', () async {
    probe.gate = Completer();
    final a = service.checkNow();
    final b = service.checkNow();
    expect(service.isChecking.value, isTrue);
    probe.gate!.complete();
    expect(await Future.wait([a, b]), [true, true]);
    expect(probe.calls, 1);
    expect(service.isChecking.value, isFalse);
  });

  testWidgets('OfflineGate: çevrimdışıyken sayfa üstte, tekrar dene yoklar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OfflineGate(service: service, child: const Text('uygulama')),
      ),
    );
    expect(find.byType(NoInternetView), findsNothing);
    expect(find.text('uygulama'), findsOneWidget);

    service.isOnline.value = false;
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(NoInternetView), findsOneWidget);
    expect(find.text('no_internet.title'), findsOneWidget);

    probe.online = false;
    await tester.tap(find.text('no_internet.retry'));
    await tester.pump();
    expect(probe.calls, 1);

    // Bağlantı geri geldi: yeniden deneme zamanlayıcısı yoklar, sayfa kapanır.
    probe.online = true;
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump(const Duration(milliseconds: 300));
    expect(service.isOnline.value, isTrue);
    expect(find.byType(NoInternetView), findsNothing);
    expect(find.text('uygulama'), findsOneWidget);
  });
}
