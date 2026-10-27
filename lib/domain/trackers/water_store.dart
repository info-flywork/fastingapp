import 'dart:async';

import 'package:fastingapp/core/sync/data_sync.dart';
import 'package:fastingapp/domain/trackers/trackers_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateUtils;

/// Suyun tek doğruluk kaynağı (Su ekranı + ana sayfa kartı + widget).
///
/// - Sunucudan gelen her gün [_server]'da saklanır; gün değişince bilinen
///   gün beklemeden gösterilir.
/// - +/− işlemleri [_ops] kuyruğuna girer, sırayla gönderilir. Görünen gün =
///   sunucu günü + henüz onaylanmamış işlemler. Yoldaki eski GET / özet
///   cevabı onaylanmamış bardağı geri alamaz; işlem başka güne kaymaz.
final class WaterStore extends ChangeNotifier {
  WaterStore(TrackersRepository trackers)
    : this.withApi(
        _RepositoryWaterApi(trackers),
        afterWrite: DataSync.afterWrite,
      );

  /// Testler sahte API ve yazma sonrası kancası verir.
  @visibleForTesting
  WaterStore.withApi(this._api, {void Function()? afterWrite})
    : _afterWrite = afterWrite ?? (() {});

  final WaterApi _api;
  final void Function() _afterWrite;

  final _server = <DateTime, WaterDay>{};
  final _ops = <_WaterOp>[];
  final _inFlight = <DateTime, Future<void>>{};
  Timer? _debounce;
  bool _sending = false;

  /// Onaylı yazma sırası: yazmadan önce başlamış GET o günü geri yazmasın.
  int _writeSeq = 0;
  final _writtenAt = <DateTime, int>{};

  /// Hedef / bardak elle değişti, sunucu henüz onaylamadı (yalnızca bugün).
  int? _localGoal;
  int? _localGlass;

  final errors = StreamController<Object>.broadcast();

  static DateTime _day(DateTime d) => DateUtils.dateOnly(d);
  static DateTime get _today => _day(DateTime.now());

  bool isLoaded(DateTime date) => _server.containsKey(_day(date));

  /// Görünen gün: sunucu + bekleyen işlemler. Hiç bilinmiyorsa null.
  WaterDay? dayFor(DateTime date) {
    final d = _day(date);
    final base = _server[d];
    final ops = _ops.where((o) => o.date == d).toList();
    final isToday = d == _today;
    if (base == null && ops.isEmpty && !isToday) return null;
    final removed = {
      for (final o in ops)
        if (!o.isAdd) o.id,
    };
    final entries = <WaterEntry>[
      for (final e in base?.entries ?? const <WaterEntry>[])
        if (!removed.contains(e.id)) e,
    ];
    final known = {for (final e in entries) e.id};
    var total = base?.totalMl ?? 0;
    for (final o in ops) {
      if (o.isAdd) {
        if (removed.contains(o.id) || known.contains(o.id)) continue;
        entries.add(WaterEntry(id: o.id, amountMl: o.amountMl, loggedAt: o.at));
        total += o.amountMl;
      } else if (base?.entries.any((e) => e.id == o.id) ?? false) {
        total -= o.amountMl;
      }
    }
    entries.sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    final goal = (isToday ? _localGoal : null) ?? base?.goalMl ?? 2500;
    return WaterDay(
      date: d,
      totalMl: total < 0 ? 0 : total,
      goalMl: goal,
      glassSizeMl: (isToday ? _localGlass : null) ?? base?.glassSizeMl ?? 300,
      goalReached: total >= goal,
      entries: entries,
    );
  }

  /// Sunucu onaylamadıysa görünen toplam (ana sayfa özetinin üstüne biner).
  int? pendingTotal(DateTime date) {
    final d = _day(date);
    if (!_ops.any((o) => o.date == d)) return null;
    return dayFor(d)?.totalMl;
  }

  int? get pendingGoal => _localGoal;

  /// Ana sayfa özetiyle / repo önbelleğiyle tohumlama (0 ile açılmasın).
  void seedToday({required int totalMl, required int goalMl}) {
    final today = _today;
    if (_server.containsKey(today)) return;
    _server[today] = WaterDay(
      date: today,
      totalMl: totalMl,
      goalMl: goalMl,
      entries: const [],
    );
  }

  /// `GET /water/day?date=`. Aynı gün için süren istek paylaşılır.
  Future<void> load(DateTime date) {
    final d = _day(date);
    final running = _inFlight[d];
    if (running != null) return running;
    final seqAtStart = _writeSeq;
    final future = _api
        .getDay(d)
        .then((day) {
          if ((_writtenAt[d] ?? -1) >= seqAtStart) return;
          _server[d] = day;
          notifyListeners();
        })
        .whenComplete(() {
          _inFlight.remove(d);
        });
    return _inFlight[d] = future;
  }

  /// Bugüne bir bardak ekler (anında görünür; 450 ms sonra gönderilir).
  void add(int amountMl) {
    _ops.add(
      _WaterOp(
        id: _api.newEntryId(),
        date: _today,
        amountMl: amountMl,
        isAdd: true,
        at: DateTime.now(),
      ),
    );
    notifyListeners();
    _schedule();
  }

  /// Bugünün son bardağını geri alır. Henüz gönderilmemiş bir ekleme ise
  /// yalnızca kuyruktan düşer (sunucuya hiç gitmez).
  void removeLast() {
    final day = dayFor(_today);
    if (day == null || day.entries.isEmpty) return;
    final last = day.entries.last;
    final queued = _ops.indexWhere(
      (o) => o.isAdd && o.id == last.id && !o.sending,
    );
    if (queued >= 0) {
      _ops.removeAt(queued);
    } else {
      _ops.add(
        _WaterOp(
          id: last.id,
          date: _today,
          amountMl: last.amountMl,
          isAdd: false,
          at: DateTime.now(),
        ),
      );
    }
    notifyListeners();
    _schedule();
  }

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => unawaited(_send()),
    );
  }

  /// Bekleyenleri hemen gönder (ekran kapanırken / gün değişirken).
  void flush() {
    if (!(_debounce?.isActive ?? false)) return;
    _debounce!.cancel();
    unawaited(_send());
  }

  /// İşlemler sırayla gider; her onay o günün sunucu halini günceller.
  Future<void> _send() async {
    if (_sending) return;
    _sending = true;
    var wrote = false;
    try {
      while (_ops.isNotEmpty) {
        final op = _ops.first..sending = true;
        final day = op.isAdd
            ? await _api.add(id: op.id, amountMl: op.amountMl)
            : await _api.delete(op.id);
        _server[op.date] = day;
        _writtenAt[op.date] = _writeSeq++;
        _ops.remove(op);
        wrote = true;
        notifyListeners();
      }
    } on Object catch (e) {
      // Kaydedilemeyenler düşer; gün sunucudan yeniden okunur.
      final dates = {for (final o in _ops) o.date};
      _ops.clear();
      errors.add(e);
      notifyListeners();
      for (final d in dates) {
        _writtenAt.remove(d);
        unawaited(load(d).catchError((Object _) {}));
      }
    } finally {
      _sending = false;
      if (wrote) _afterWrite();
    }
  }

  /// Bugünün hedefi / bardak boyu. Hata olursa eski değer geri gelir.
  Future<void> setGoals({int? goalMl, int? glassMl}) async {
    if (goalMl != null) _localGoal = goalMl;
    if (glassMl != null) _localGlass = glassMl;
    notifyListeners();
    try {
      await _api.updateGoals({'waterGoalMl': ?goalMl, 'glassSizeMl': ?glassMl});
      final today = _today;
      final base = _server[today];
      if (base != null) {
        _server[today] = WaterDay(
          date: base.date,
          totalMl: base.totalMl,
          goalMl: goalMl ?? base.goalMl,
          glassSizeMl: glassMl ?? base.glassSizeMl,
          goalReached: base.totalMl >= (goalMl ?? base.goalMl),
          entries: base.entries,
        );
      }
      _afterWrite();
    } finally {
      if (_localGoal == goalMl) _localGoal = null;
      if (_localGlass == glassMl) _localGlass = null;
      notifyListeners();
    }
  }

  /// Çıkış / hesap değişimi.
  void reset() {
    _debounce?.cancel();
    _ops.clear();
    _server.clear();
    _writtenAt.clear();
    _localGoal = null;
    _localGlass = null;
    notifyListeners();
  }
}

final class _WaterOp {
  _WaterOp({
    required this.id,
    required this.date,
    required this.amountMl,
    required this.isAdd,
    required this.at,
  });

  final String id;
  final DateTime date;
  final int amountMl;
  final bool isAdd;
  final DateTime at;

  /// Sunucuya gönderildi (artık kuyruktan sessizce düşürülemez).
  bool sending = false;
}

/// [WaterStore]'un kullandığı uçlar (testte sahtelenir).
abstract interface class WaterApi {
  Future<WaterDay> getDay(DateTime date);
  Future<WaterDay> add({required String id, required int amountMl});
  Future<WaterDay> delete(String id);
  Future<void> updateGoals(Map<String, dynamic> fields);
  String newEntryId();
}

final class _RepositoryWaterApi implements WaterApi {
  const _RepositoryWaterApi(this._repo);

  final TrackersRepository _repo;

  @override
  Future<WaterDay> getDay(DateTime date) => _repo.getWaterDay(date: date);

  @override
  Future<WaterDay> add({required String id, required int amountMl}) =>
      _repo.addWater(id: id, amountMl: amountMl);

  @override
  Future<WaterDay> delete(String id) => _repo.deleteWaterEntry(id);

  @override
  Future<void> updateGoals(Map<String, dynamic> fields) =>
      _repo.updateGoals(fields);

  @override
  String newEntryId() => _repo.newWaterEntryId();
}
