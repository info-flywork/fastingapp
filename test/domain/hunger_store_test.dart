import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:fastingapp/domain/hunger/hunger_repository.dart';
import 'package:fastingapp/domain/hunger/hunger_store.dart';
import 'package:fastingapp/presentation/hunger_tracker/hunger_symptom.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sunucuyu taklit eder; istekler elle bitirilir (yarışlar kurulabilsin).
final class _FakeApi implements HungerApi {
  final items = <HungerCheckinItem>[];
  final gets = <Completer<void>>[];
  final saves = <Completer<void>>[];

  String get _today {
    final d = DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Future<T> _get<T>(T Function() read) async {
    final done = Completer<void>();
    gets.add(done);
    final snapshot = read(); // isteğin atıldığı andaki durum
    await done.future;
    return snapshot;
  }

  @override
  Future<List<HungerCheckinItem>> list() => _get(() => List.of(items));

  @override
  Future<HungerCheckinSummary> summary() => _get(() {
    final physical = items.where((e) => e.resultType == 'physical').length;
    return HungerCheckinSummary(
      todayTotal: items.length,
      todayPhysical: physical,
      todayEmotional: items.length - physical,
      week: [HungerWeekDay(date: _today, physical: physical)],
    );
  });

  @override
  Future<HungerEvaluation> save({
    required HungerFlowArgs flow,
    required String mode,
    String? notes,
  }) async {
    final done = Completer<void>();
    saves.add(done);
    await done.future;
    items.insert(
      0,
      HungerCheckinItem(
        id: 's${items.length}',
        loggedAt: DateTime.now(),
        resultType: 'physical',
      ),
    );
    return const HungerEvaluation(resultType: 'physical');
  }
}

void main() {
  late _FakeApi api;
  late HungerStore store;

  setUp(() {
    api = _FakeApi();
    store = HungerStore.withApi(api);
  });

  void finishGets(FakeAsync async) {
    for (final g in api.gets.where((g) => !g.isCompleted).toList()) {
      g.complete();
      async.flushMicrotasks();
    }
  }

  test('kayıt listeye ve sayılara anında girer; eski GET geri almaz', () {
    fakeAsync((async) {
      unawaited(store.load());
      async.flushMicrotasks();
      finishGets(async);
      expect(store.entries, isEmpty);

      unawaited(store.load()); // eski veriyle başlayan istek
      async.flushMicrotasks();
      unawaited(store.save(flow: const HungerFlowArgs(), mode: 'quick'));
      async.flushMicrotasks();
      api.saves.single.complete();
      async.flushMicrotasks();
      expect(store.entries, hasLength(1));
      expect(store.pendingToday?.physical, 1);
      expect(store.week.single.physical, 1);

      finishGets(async); // eski istek (yok sayılır)
      expect(store.entries, hasLength(1));
      finishGets(async); // taze istek
      expect(store.entries!.single.id, 's0');
      expect(store.pendingToday, isNull);
    });
  });
}
