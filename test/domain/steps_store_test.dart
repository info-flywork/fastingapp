import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/domain/trackers/steps_store.dart';
import 'package:fastingapp/domain/trackers/trackers_repository.dart';
import 'package:flutter/material.dart' show DateUtils;
import 'package:flutter_test/flutter_test.dart';

/// Sunucuyu taklit eder; istekler elle bitirilir (yarışlar kurulabilsin).
final class _FakeApi implements StepsApi {
  final server = <DateTime, int>{};
  final gets = <(DateTime, Completer<void>)>[];
  final puts = <(DateTime, int, Completer<void>)>[];
  Exception? putError;

  StepsRange _week(DateTime date) {
    final monday = StepsStore.mondayOf(date);
    return StepsRange(
      range: 'week',
      days: [
        for (var i = 0; i < 7; i++)
          StepsDay(
            date: monday.add(Duration(days: i)),
            steps: server[monday.add(Duration(days: i))] ?? 0,
            goal: 8000,
          ),
      ],
    );
  }

  @override
  Future<StepsRange> getSteps({required DateTime date}) async {
    final done = Completer<void>();
    gets.add((date, done));
    // Yanıt, isteğin atıldığı andaki sunucu durumudur (eski veri yarışı).
    final snapshot = _week(date);
    await done.future;
    return snapshot;
  }

  @override
  Future<StepsRange> putSteps({
    required DateTime date,
    required int steps,
  }) async {
    final done = Completer<void>();
    puts.add((date, steps, done));
    await done.future;
    final error = putError;
    if (error != null) throw error;
    server[DateUtils.dateOnly(date)] = steps;
    return _week(date);
  }

  @override
  Future<void> updateGoals(Map<String, dynamic> fields) async {}
}

void main() {
  final today = DateUtils.dateOnly(DateTime.now());
  final yesterday = today.subtract(const Duration(days: 1));

  late _FakeApi api;
  late StepsStore store;

  setUp(() {
    api = _FakeApi()
      ..server[today] = 6500
      ..server[yesterday] = 3000;
    store = StepsStore.withApi(api);
  });

  test('yoldaki eski GET, onaylanmamış +500 değerini geri almaz', () {
    fakeAsync((async) {
      unawaited(store.loadWeek(today));
      async.flushMicrotasks();
      api.gets.single.$2.complete();
      async.flushMicrotasks();
      expect(store.stepsFor(today), 6500);

      // Kullanıcı +500; bu sırada eski veriyle bir GET başlıyor.
      store.setSteps(today, 7000);
      unawaited(store.loadWeek(today));
      async.flushMicrotasks();
      api.gets.last.$2.complete();
      async.flushMicrotasks();
      expect(store.stepsFor(today), 7000, reason: 'eski GET ezmemeli');

      // PUT gider ve onaylanır.
      async.elapse(const Duration(milliseconds: 600));
      api.puts.single.$3.complete();
      async.flushMicrotasks();
      expect(store.stepsFor(today), 7000);
      expect(store.pendingSteps(today), isNull);
    });
  });

  test(
    'art arda dokunuşlar tek PUT; ilk PUT yoldayken gelen dokunuş korunur',
    () {
      fakeAsync((async) {
        store
          ..seedToday(steps: 6500, goal: 8000)
          ..setSteps(today, 7000)
          ..setSteps(today, 7500);
        async.elapse(const Duration(milliseconds: 600));
        expect(api.puts, hasLength(1));
        expect(api.puts.single.$2, 7500);

        // PUT yoldayken bir dokunuş daha.
        store.setSteps(today, 8000);
        api.puts.single.$3.complete();
        async.flushMicrotasks();
        expect(
          store.stepsFor(today),
          8000,
          reason: 'ilk PUT cevabı geri almaz',
        );

        async.elapse(const Duration(milliseconds: 600));
        api.puts.last.$3.complete();
        async.flushMicrotasks();
        expect(store.stepsFor(today), 8000);
        expect(store.pendingSteps(today), isNull);
      });
    },
  );

  test(
    'gün değişince bekleyen değer kendi gününe yazılır, diğer güne kaymaz',
    () {
      fakeAsync((async) {
        unawaited(store.loadWeek(today));
        async.flushMicrotasks();
        api.gets.single.$2.complete();
        async.flushMicrotasks();

        store
          ..setSteps(today, 7000)
          ..flush(); // gün değişimi
        expect(store.stepsFor(yesterday), 3000);
        expect(store.stepsFor(today), 7000);

        api.puts.single.$3.complete();
        async.flushMicrotasks();
        expect(api.puts.single.$1, today);
        expect(store.stepsFor(yesterday), 3000);
        expect(store.stepsFor(today), 7000);
      });
    },
  );

  test('PUT onaylandıktan sonra gelen, ondan önce başlamış GET geri almaz', () {
    fakeAsync((async) {
      store
        ..seedToday(steps: 6500, goal: 8000)
        ..setSteps(today, 7000);
      async.elapse(const Duration(milliseconds: 600));
      // PUT yoldayken eski veriyle GET başlar…
      unawaited(store.loadWeek(today));
      async.flushMicrotasks();
      // …PUT önce biter, GET sonra.
      api.puts.single.$3.complete();
      async.flushMicrotasks();
      api.gets.single.$2.complete();
      async.flushMicrotasks();
      expect(store.stepsFor(today), 7000);
    });
  });

  test('loadWeek tamamlanır (await sonsuza dek beklemez)', () {
    fakeAsync((async) {
      var done = false;
      unawaited(store.loadWeek(today).whenComplete(() => done = true));
      async.flushMicrotasks();
      api.gets.single.$2.complete();
      async.flushMicrotasks();
      expect(done, isTrue);
    });
  });

  test('PUT hatasında yerel değer kalkar, sunucu değerine dönülür', () {
    fakeAsync((async) {
      unawaited(store.loadWeek(today));
      async.flushMicrotasks();
      api.gets.single.$2.complete();
      async.flushMicrotasks();

      api.putError = const NetworkException('x', statusCode: 409);
      store.setSteps(today, 7000);
      async.elapse(const Duration(milliseconds: 600));
      api.puts.single.$3.complete();
      async.flushMicrotasks();
      expect(store.pendingSteps(today), isNull);
      expect(store.stepsFor(today), 6500);
    });
  });
}
