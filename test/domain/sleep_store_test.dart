import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:fastingapp/domain/trackers/sleep_store.dart';
import 'package:fastingapp/domain/trackers/trackers_repository.dart';
import 'package:flutter/material.dart' show DateUtils;
import 'package:flutter_test/flutter_test.dart';

/// Sunucuyu taklit eder; istekler elle bitirilir (yarışlar kurulabilsin).
final class _FakeApi implements SleepApi {
  int? nightMinutes = 360;
  int goalMin = 450;
  final gets = <Completer<void>>[];
  final writes = <Completer<void>>[];
  Exception? writeError;

  SleepSummary _snapshot() {
    final today = DateUtils.dateOnly(DateTime.now());
    return SleepSummary(
      date: today,
      lastNightMinutes: nightMinutes,
      lastNightId: nightMinutes == null ? null : 'n1',
      lastNightSource: 'manual',
      goalMin: goalMin,
      weekMinutes: [0, 0, 0, 0, 0, 0, nightMinutes ?? 0],
      weekDates: [
        for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
      ],
    );
  }

  @override
  Future<SleepSummary> summary() async {
    final done = Completer<void>();
    gets.add(done);
    final snapshot = _snapshot(); // isteğin atıldığı andaki durum
    await done.future;
    return snapshot;
  }

  Future<void> _write(void Function() apply) async {
    final done = Completer<void>();
    writes.add(done);
    await done.future;
    final error = writeError;
    if (error != null) throw error;
    apply();
  }

  @override
  Future<void> create({required DateTime start, required DateTime end}) =>
      _write(() => nightMinutes = end.difference(start).inMinutes);

  @override
  Future<void> update(
    String id, {
    required DateTime start,
    required DateTime end,
  }) => _write(() => nightMinutes = end.difference(start).inMinutes);

  @override
  Future<void> delete(String id) => _write(() => nightMinutes = null);

  @override
  Future<void> updateGoals(Map<String, dynamic> fields) =>
      _write(() => goalMin = fields['sleepGoalMin'] as int? ?? goalMin);
}

void main() {
  final today = DateUtils.dateOnly(DateTime.now());
  final end = today.add(const Duration(hours: 7));
  final start = end.subtract(const Duration(hours: 8));

  late _FakeApi api;
  late SleepStore store;

  setUp(() {
    api = _FakeApi();
    store = SleepStore.withApi(api);
  });

  void finishGets(FakeAsync async) {
    for (final g in api.gets.where((g) => !g.isCompleted).toList()) {
      g.complete();
      async.flushMicrotasks();
    }
  }

  void loaded(FakeAsync async) {
    unawaited(store.load());
    async.flushMicrotasks();
    finishGets(async);
  }

  test('kayıt anında görünür; onay ve taze özet sonrası zıplamaz', () {
    fakeAsync((async) {
      loaded(async);
      expect(store.summary!.lastNightMinutes, 360);
      final shown = <int?>[];
      store.addListener(() => shown.add(store.summary!.lastNightMinutes));

      unawaited(store.logNight(start: start, end: end, id: 'n1'));
      async.flushMicrotasks();
      expect(store.summary!.lastNightMinutes, 480);
      expect(store.summary!.weekMinutes.last, 480);

      api.writes.single.complete();
      async.flushMicrotasks();
      finishGets(async);
      expect(store.summary!.lastNightMinutes, 480);
      expect(shown, everyElement(480), reason: "arada 360'a düşmemeli");
    });
  });

  test('yazmadan önce başlamış eski GET sonucu geri almaz', () {
    fakeAsync((async) {
      loaded(async);
      unawaited(store.load()); // eski veriyle başlar
      async.flushMicrotasks();
      unawaited(store.setGoals(goalMin: 540));
      async.flushMicrotasks();
      api.writes.single.complete();
      async.flushMicrotasks();
      finishGets(async);
      expect(store.summary!.goalMin, 540);
    });
  });

  test('yazma hatasında eski değere dönülür ve hata iletilir', () {
    fakeAsync((async) {
      loaded(async);
      api.writeError = Exception('ağ');
      Object? error;
      unawaited(store.deleteNight('n1').catchError((Object e) => error = e));
      async.flushMicrotasks();
      expect(store.summary!.lastNightMinutes, isNull);
      api.writes.single.complete();
      async.flushMicrotasks();
      expect(store.summary!.lastNightMinutes, 360);
      expect(error, isNotNull);
    });
  });
}
