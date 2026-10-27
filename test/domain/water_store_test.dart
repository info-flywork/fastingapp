import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:fastingapp/domain/trackers/trackers_repository.dart';
import 'package:fastingapp/domain/trackers/water_store.dart';
import 'package:flutter/material.dart' show DateUtils;
import 'package:flutter_test/flutter_test.dart';

/// Sunucuyu taklit eder; istekler elle bitirilir (yarışlar kurulabilsin).
final class _FakeApi implements WaterApi {
  final days = <DateTime, List<WaterEntry>>{};
  final gets = <Completer<void>>[];
  final writes = <(String, bool, Completer<void>)>[];
  Exception? writeError;
  var _id = 0;

  WaterDay _snapshot(DateTime date) {
    final d = DateUtils.dateOnly(date);
    final entries = List<WaterEntry>.of(days[d] ?? const []);
    return WaterDay(
      date: d,
      totalMl: entries.fold(0, (sum, e) => sum + e.amountMl),
      goalMl: 2500,
      entries: entries,
    );
  }

  @override
  Future<WaterDay> getDay(DateTime date) async {
    final done = Completer<void>();
    gets.add(done);
    final snapshot = _snapshot(date); // isteğin atıldığı andaki durum
    await done.future;
    return snapshot;
  }

  @override
  Future<WaterDay> add({required String id, required int amountMl}) async {
    final done = Completer<void>();
    writes.add((id, true, done));
    await done.future;
    final error = writeError;
    if (error != null) throw error;
    final today = DateUtils.dateOnly(DateTime.now());
    (days[today] ??= []).add(
      WaterEntry(id: id, amountMl: amountMl, loggedAt: DateTime.now()),
    );
    return _snapshot(today);
  }

  @override
  Future<WaterDay> delete(String id) async {
    final done = Completer<void>();
    writes.add((id, false, done));
    await done.future;
    final today = DateUtils.dateOnly(DateTime.now());
    days[today]?.removeWhere((e) => e.id == id);
    return _snapshot(today);
  }

  @override
  Future<void> updateGoals(Map<String, dynamic> fields) async {}

  @override
  String newEntryId() => 'n${_id++}';
}

void main() {
  final today = DateUtils.dateOnly(DateTime.now());
  final yesterday = today.subtract(const Duration(days: 1));

  late _FakeApi api;
  late WaterStore store;

  void finishWrites(FakeAsync async) {
    while (api.writes.any((w) => !w.$3.isCompleted)) {
      api.writes.firstWhere((w) => !w.$3.isCompleted).$3.complete();
      async.flushMicrotasks();
    }
  }

  setUp(() {
    api = _FakeApi()
      ..days[today] = [WaterEntry(id: 'a', amountMl: 300, loggedAt: today)]
      ..days[yesterday] = [
        WaterEntry(id: 'y', amountMl: 1200, loggedAt: yesterday),
      ];
    store = WaterStore.withApi(api);
  });

  void loadToday(FakeAsync async) {
    unawaited(store.load(today));
    async.flushMicrotasks();
    api.gets.last.complete();
    async.flushMicrotasks();
  }

  test('yoldaki eski GET onaylanmamış bardağı geri almaz', () {
    fakeAsync((async) {
      loadToday(async);
      store.add(300);
      unawaited(store.load(today));
      async.flushMicrotasks();
      api.gets.last.complete();
      async.flushMicrotasks();
      expect(store.dayFor(today)!.totalMl, 600);
      async.elapse(const Duration(milliseconds: 450));
      finishWrites(async);
      expect(store.dayFor(today)!.totalMl, 600);
      expect(store.pendingTotal(today), isNull);
    });
  });

  test(
    'yazma onaylandıktan sonra gelen, ondan önce başlamış GET geri almaz',
    () {
      fakeAsync((async) {
        loadToday(async);
        store.add(300);
        async.elapse(const Duration(milliseconds: 450));
        unawaited(store.load(today)); // eski veriyle başlar
        async.flushMicrotasks();
        finishWrites(async); // yazma önce biter
        api.gets.last.complete(); // eski GET sonra
        async.flushMicrotasks();
        expect(store.dayFor(today)!.totalMl, 600);
      });
    },
  );

  test('ekleme yoldayken gelen ekleme ve geri alma doğru toplanır', () {
    fakeAsync((async) {
      loadToday(async);
      store.add(300);
      async.elapse(const Duration(milliseconds: 450)); // 1. ekleme yolda
      store
        ..add(300) // 2. ekleme kuyrukta
        ..removeLast(); // gönderilmemiş 2. ekleme kuyruktan düşer
      expect(store.dayFor(today)!.totalMl, 600);
      store.removeLast(); // yoldaki 1. eklemeyi geri al → silme işlemi
      expect(store.dayFor(today)!.totalMl, 300);
      async.elapse(const Duration(milliseconds: 450));
      finishWrites(async);
      expect(store.dayFor(today)!.totalMl, 300);
      expect(api.days[today]!.map((e) => e.id), ['a']);
    });
  });

  test('gün değişince bugünün bardağı dünkü güne kaymaz', () {
    fakeAsync((async) {
      loadToday(async);
      unawaited(store.load(yesterday));
      async.flushMicrotasks();
      api.gets.last.complete();
      async.flushMicrotasks();

      store
        ..add(500)
        ..flush(); // gün değişimi
      expect(store.dayFor(yesterday)!.totalMl, 1200);
      expect(store.dayFor(today)!.totalMl, 800);
      finishWrites(async);
      expect(store.dayFor(yesterday)!.totalMl, 1200);
      expect(store.dayFor(today)!.totalMl, 800);
    });
  });

  test('load tamamlanır (await sonsuza dek beklemez)', () {
    fakeAsync((async) {
      var done = false;
      unawaited(store.load(today).whenComplete(() => done = true));
      async.flushMicrotasks();
      api.gets.single.complete();
      async.flushMicrotasks();
      expect(done, isTrue);
    });
  });

  test('yazma hatasında bekleyen bardaklar düşer, sunucu değerine dönülür', () {
    fakeAsync((async) {
      loadToday(async);
      api.writeError = Exception('ağ');
      final errors = <Object>[];
      store.errors.stream.listen(errors.add);
      store.add(300);
      async.elapse(const Duration(milliseconds: 450));
      finishWrites(async);
      expect(store.pendingTotal(today), isNull);
      expect(store.dayFor(today)!.totalMl, 300);
      expect(errors, hasLength(1));
    });
  });
}
