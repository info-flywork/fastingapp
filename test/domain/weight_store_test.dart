import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:fastingapp/domain/trackers/trackers_repository.dart';
import 'package:fastingapp/domain/trackers/weight_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sunucuyu taklit eder; istekler elle bitirilir (yarışlar kurulabilsin).
final class _FakeApi implements WeightApi {
  double current = 86;
  double goal = 65;
  final gets = <Completer<void>>[];
  final writes = <Completer<void>>[];
  Exception? writeError;

  WeightSummary _snapshot() =>
      WeightSummary(currentKg: current, startKg: 90, goalKg: goal);

  WeightChart _chart(String range) => WeightChart(
    range: range,
    buckets: [WeightChartBucket(label: 'Bugün', weightKg: current)],
  );

  Future<T> _get<T>(T Function() read) async {
    final done = Completer<void>();
    gets.add(done);
    final snapshot = read(); // isteğin atıldığı andaki durum
    await done.future;
    return snapshot;
  }

  @override
  Future<WeightSummary> summary() => _get(_snapshot);

  @override
  Future<WeightChart> chart(String range) => _get(() => _chart(range));

  @override
  Future<void> create(double kg) async {
    final done = Completer<void>();
    writes.add(done);
    await done.future;
    final error = writeError;
    if (error != null) throw error;
    current = kg;
  }

  @override
  Future<WeightSummary> setGoal(double kg) async {
    final done = Completer<void>();
    writes.add(done);
    await done.future;
    goal = kg;
    return _snapshot();
  }
}

void main() {
  late _FakeApi api;
  late WeightStore store;

  setUp(() {
    api = _FakeApi();
    store = WeightStore.withApi(api);
  });

  void finishGets(FakeAsync async) {
    for (final g in api.gets.where((g) => !g.isCompleted).toList()) {
      g.complete();
      async.flushMicrotasks();
    }
  }

  test('yeni tartı anında görünür; onay ve taze özet sonrası zıplamaz', () {
    fakeAsync((async) {
      unawaited(store.loadSummary());
      async.flushMicrotasks();
      finishGets(async);
      expect(store.currentKg, 86);

      final shown = <double?>[];
      store.addListener(() => shown.add(store.currentKg));
      unawaited(store.loadSummary()); // eski veriyle başlayan istek
      async.flushMicrotasks();
      unawaited(store.addWeight(84.5));
      async.flushMicrotasks();
      expect(store.currentKg, 84.5);

      api.writes.single.complete();
      async.flushMicrotasks();
      finishGets(async); // eski istek
      finishGets(async); // taze özet + grafik
      expect(store.currentKg, 84.5);
      expect(store.pendingKg, isNull);
      expect(store.chart('day')!.buckets.single.weightKg, 84.5);
      expect(shown, everyElement(84.5), reason: "arada 86'ya düşmemeli");
    });
  });

  test('tartı kaydedilemezse eski değere döner', () {
    fakeAsync((async) {
      unawaited(store.loadSummary());
      async.flushMicrotasks();
      finishGets(async);
      api.writeError = Exception('ağ');
      Object? error;
      unawaited(store.addWeight(80).catchError((Object e) => error = e));
      async.flushMicrotasks();
      expect(store.currentKg, 80);
      api.writes.single.complete();
      async.flushMicrotasks();
      expect(store.currentKg, 86);
      expect(error, isNotNull);
    });
  });

  test('hedef anında görünür, yanıttaki özet uygulanır', () {
    fakeAsync((async) {
      unawaited(store.loadSummary());
      async.flushMicrotasks();
      finishGets(async);
      unawaited(store.setGoal(70));
      async.flushMicrotasks();
      expect(store.goalKg, 70);
      api.writes.single.complete();
      async.flushMicrotasks();
      expect(store.goalKg, 70);
      expect(store.pendingGoal, isNull);
    });
  });
}
