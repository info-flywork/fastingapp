import 'dart:async';

import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/core/sync/data_sync.dart';
import 'package:fastingapp/domain/trackers/trackers_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateUtils;

/// Adımların tek doğruluk kaynağı (Adım ekranı + ana sayfa kartı).
///
/// - Sunucudan gelen her gün [_server]'a yazılır; günler arası geçişte
///   bilinen gün beklemeden gösterilir.
/// - Elle +/- [_local]'a yazılır ve gün başına tek PUT'a katlanır. Sunucu o
///   değeri onaylayana kadar hiçbir GET / özet cevabı onu ezemez; onaylanınca
///   yerel kayıt kalkar. Böylece sayı ileri-geri oynamaz, başka güne kaymaz.
final class StepsStore extends ChangeNotifier {
  StepsStore(TrackersRepository trackers)
    : this.withApi(
        _RepositoryStepsApi(trackers),
        afterWrite: DataSync.afterWrite,
      );

  /// Testler sahte API ve yazma sonrası kancası verir.
  @visibleForTesting
  StepsStore.withApi(this._trackers, {void Function()? afterWrite})
    : _afterWrite = afterWrite ?? (() {});

  final StepsApi _trackers;
  final void Function() _afterWrite;

  final _server = <DateTime, StepsDay>{};
  final _local = <DateTime, int>{};
  final _loadedWeeks = <DateTime>{};
  final _inFlight = <DateTime, Future<void>>{};
  final _timers = <DateTime, Timer>{};

  /// Her onaylı yazmada artar; gün başına son yazmanın sırası. Yazmadan önce
  /// başlamış bir GET'in (eski) cevabı o günü geri yazmasın.
  int _writeSeq = 0;
  final _writtenAt = <DateTime, int>{};

  /// Gün başına son yanıttaki hedef (geçmiş günler kendi hedefini tutar).
  int _liveGoal = 8000;

  /// Bugünün hedefi elle değiştirildi, sunucu henüz onaylamadı.
  int? _localGoal;

  /// Son 409 / hata mesajı (ekran bir kez gösterir).
  final errors = StreamController<Object>.broadcast();

  static DateTime _day(DateTime d) => DateUtils.dateOnly(d);
  static DateTime mondayOf(DateTime d) =>
      _day(d).subtract(Duration(days: d.weekday - 1));

  bool isWeekLoaded(DateTime date) => _loadedWeeks.contains(mondayOf(date));

  /// Ekranda gösterilecek adım: onaylanmamış yerel değer önce gelir.
  int stepsFor(DateTime date) =>
      _local[_day(date)] ?? _server[_day(date)]?.steps ?? 0;

  /// Sunucu henüz onaylamadıysa yerel değer, yoksa null (özet üstüne biner).
  int? pendingSteps(DateTime date) => _local[_day(date)];

  int goalFor(DateTime date) {
    final d = _day(date);
    final today = _day(DateTime.now());
    if (!d.isBefore(today)) return _localGoal ?? _liveGoal;
    return _server[d]?.goal ?? _liveGoal;
  }

  int? get pendingGoal => _localGoal;

  bool isHealthSynced(DateTime date) =>
      _server[_day(date)]?.isHealthSynced ?? false;

  StepsDay? serverDay(DateTime date) => _server[_day(date)];

  /// Ana sayfa özetiyle tohumlama (ekran ilk açılışta 0 ile açılmasın).
  void seedToday({required int steps, required int goal}) {
    final today = _day(DateTime.now());
    if (_server.containsKey(today)) return;
    _liveGoal = goal;
    _server[today] = StepsDay(date: today, steps: steps, goal: goal);
  }

  /// `GET /steps?date=` (Pzt–Paz). Aynı hafta için süren istek paylaşılır.
  Future<void> loadWeek(DateTime date) {
    final monday = mondayOf(date);
    final running = _inFlight[monday];
    if (running != null) return running;
    final seqAtStart = _writeSeq;
    final future = _trackers
        .getSteps(date: monday)
        .then((range) => _applyRange(range, seqAtStart))
        .whenComplete(() {
          _inFlight.remove(monday);
        });
    return _inFlight[monday] = future;
  }

  void _applyRange(StepsRange range, int seqAtStart) {
    final today = _day(DateTime.now());
    for (final day in range.days) {
      final d = _day(day.date);
      _loadedWeeks.add(mondayOf(d));
      if ((_writtenAt[d] ?? -1) >= seqAtStart) continue;
      _server[d] = day;
      if (DateUtils.isSameDay(d, today) && day.goal != null) {
        _liveGoal = day.goal!;
      }
    }
    notifyListeners();
  }

  /// Elle adım (yalnızca bugün; sağlık günü değilse). Art arda dokunuşlar
  /// 600 ms içinde tek PUT olur.
  void setSteps(DateTime date, int steps) {
    final d = _day(date);
    _local[d] = steps.clamp(0, 99999);
    notifyListeners();
    _timers[d]?.cancel();
    _timers[d] = Timer(
      const Duration(milliseconds: 600),
      () => unawaited(_persist(d)),
    );
  }

  /// Bekleyen yazmaları hemen gönder (ekran kapanırken / gün değişirken).
  void flush() {
    for (final entry in _timers.entries.toList()) {
      if (!entry.value.isActive) continue;
      entry.value.cancel();
      unawaited(_persist(entry.key));
    }
  }

  Future<void> _persist(DateTime d) async {
    _timers.remove(d);
    final value = _local[d];
    if (value == null) return;
    try {
      final range = await _trackers.putSteps(date: d, steps: value);
      for (final day in range.days) {
        if (DateUtils.isSameDay(day.date, d)) _server[d] = day;
      }
      _writtenAt[d] = _writeSeq++;
      // Yoldayken yeni dokunuş geldiyse o kendi PUT'unu bekliyor; yerel kalır.
      if (_local[d] == value) _local.remove(d);
      notifyListeners();
      _afterWrite();
    } on NetworkException catch (e) {
      _local.remove(d);
      // 409: sağlık uygulamasının günü; elle yazılamaz. Sunucu değerine dön.
      if (e.statusCode != 409) errors.add(e);
      notifyListeners();
      unawaited(_reloadWeek(d));
    } on Object catch (e) {
      _local.remove(d);
      errors.add(e);
      notifyListeners();
      unawaited(_reloadWeek(d));
    }
  }

  Future<void> _reloadWeek(DateTime d) async {
    _loadedWeeks.remove(mondayOf(d));
    try {
      await loadWeek(d);
    } on Object {
      // Ekran kendi yüklemesinde tekrar dener.
    }
  }

  /// Bugünün hedefi (1.000–50.000). Hata olursa eski hedef geri gelir.
  Future<void> setTodayGoal(int goal) async {
    _localGoal = goal;
    notifyListeners();
    try {
      await _trackers.updateGoals({'stepsGoal': goal});
      _liveGoal = goal;
      _afterWrite();
    } finally {
      if (_localGoal == goal) _localGoal = null;
      notifyListeners();
    }
  }

  /// Sağlık senkronu / başka cihaz: haftalar yeniden yüklensin.
  void invalidate() {
    _loadedWeeks.clear();
  }

  /// Çıkış / hesap değişimi.
  void reset() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    _server.clear();
    _local.clear();
    _writtenAt.clear();
    _loadedWeeks.clear();
    _localGoal = null;
    _liveGoal = 8000;
    notifyListeners();
  }
}

/// [StepsStore]'un kullandığı uçlar (testte sahtelenir).
abstract interface class StepsApi {
  Future<StepsRange> getSteps({required DateTime date});
  Future<StepsRange> putSteps({required DateTime date, required int steps});
  Future<void> updateGoals(Map<String, dynamic> fields);
}

final class _RepositoryStepsApi implements StepsApi {
  const _RepositoryStepsApi(this._repo);

  final TrackersRepository _repo;

  @override
  Future<StepsRange> getSteps({required DateTime date}) =>
      _repo.getSteps(date: date);

  @override
  Future<StepsRange> putSteps({required DateTime date, required int steps}) =>
      _repo.putSteps(date: date, steps: steps);

  @override
  Future<void> updateGoals(Map<String, dynamic> fields) =>
      _repo.updateGoals(fields);
}
