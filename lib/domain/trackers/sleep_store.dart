import 'dart:async';

import 'package:fastingapp/core/sync/data_sync.dart';
import 'package:fastingapp/domain/trackers/trackers_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateUtils;

/// Uyku özetinin tek kaynağı (Uyku ekranı).
///
/// - Son özet bellekte kalır; ekran tekrar açılınca beklemeden dolu gelir,
///   arkadan sessizce tazelenir.
/// - Kayıt ekle / düzenle / sil ve hedef / program değişikliği anında
///   görünür (iyimser); sunucu onaylayınca gerçek özet gelir, hata olursa
///   eski hale döner. Yazmadan önce başlamış eski bir GET sonucu geri almaz.
final class SleepStore extends ChangeNotifier {
  SleepStore(TrackersRepository trackers)
    : this.withApi(
        _RepositorySleepApi(trackers),
        afterWrite: DataSync.afterWrite,
      );

  /// Testler sahte API ve yazma sonrası kancası verir.
  @visibleForTesting
  SleepStore.withApi(this._api, {void Function()? afterWrite})
    : _afterWrite = afterWrite ?? (() {});

  final SleepApi _api;
  final void Function() _afterWrite;

  SleepSummary? _server;
  Future<void>? _inFlight;

  /// Onaylı yazma sırası: yazmadan önce başlamış GET sonucu yok sayılır.
  int _writeSeq = 0;
  int _lastWrite = -1;

  /// Sunucu henüz onaylamadı; görünen özet bunların üstüne kurulur.
  _NightOverride? _night;
  int? _goalMin;
  String? _bedtime;
  String? _wakeTime;

  /// Görünen özet; hiç yüklenmediyse null.
  SleepSummary? get summary {
    final base = _server;
    if (base == null) return null;
    final night = _night;
    final goal = _goalMin ?? base.goalMin;
    var minutes = base.lastNightMinutes;
    var week = base.weekMinutes;
    if (night != null) {
      minutes = night.minutes;
      // Haftada o gecenin çubuğu da (uyanılan gün) anında güncellenir.
      final day = night.day;
      if (day != null) {
        week = [
          for (var i = 0; i < base.weekMinutes.length; i++)
            i < base.weekDates.length &&
                    base.weekDates[i] != null &&
                    DateUtils.isSameDay(base.weekDates[i], day)
                ? night.minutes ?? 0
                : base.weekMinutes[i],
        ];
      }
    }
    return SleepSummary(
      date: base.date,
      lastNightMinutes: minutes,
      lastNightId: night == null ? base.lastNightId : night.id,
      lastNightStart: night == null ? base.lastNightStart : night.start,
      lastNightEnd: night == null ? base.lastNightEnd : night.end,
      lastNightSource: night == null ? base.lastNightSource : 'manual',
      goalMin: goal,
      progress: minutes == null || goal <= 0
          ? 0
          : (minutes / goal).clamp(0.0, 1.0),
      bedtime: _bedtime ?? base.bedtime,
      wakeTime: _wakeTime ?? base.wakeTime,
      weekMinutes: week,
      weekDates: base.weekDates,
      scheduleSet:
          base.scheduleSet ||
          _goalMin != null ||
          _bedtime != null ||
          _wakeTime != null,
    );
  }

  /// `GET /sleep/summary`. Süren istek paylaşılır.
  Future<void> load() {
    final running = _inFlight;
    if (running != null) return running;
    final seqAtStart = _writeSeq;
    return _inFlight = _api
        .summary()
        .then((s) {
          if (_lastWrite >= seqAtStart) return;
          _server = s;
          notifyListeners();
        })
        .whenComplete(() => _inFlight = null);
  }

  /// Yazma onaylandı: taze özet okunur, sonra iyimser katman kalkar
  /// (arada eski değere düşüp zıplamasın).
  Future<void> _confirmed(void Function() clearOverride) async {
    _lastWrite = _writeSeq++;
    _afterWrite();
    try {
      await _inFlight; // yazmadan önce başlamış GET bitsin (yok sayılır)
      await load();
    } on Object {
      // Görünen iyimser değer kalır; sonraki açılışta tazelenir.
      return;
    }
    clearOverride();
    notifyListeners();
  }

  /// Gece kaydı ekle ya da [id] verilirse düzenle.
  Future<void> logNight({
    required DateTime start,
    required DateTime end,
    String? id,
  }) async {
    final override = _NightOverride(
      id: id ?? _server?.lastNightId,
      start: start,
      end: end,
      minutes: end.difference(start).inMinutes,
      day: DateUtils.dateOnly(end),
    );
    _night = override;
    notifyListeners();
    try {
      if (id != null) {
        await _api.update(id, start: start, end: end);
      } else {
        await _api.create(start: start, end: end);
      }
    } on Object {
      if (identical(_night, override)) _night = null;
      notifyListeners();
      rethrow;
    }
    await _confirmed(() {
      if (identical(_night, override)) _night = null;
    });
  }

  Future<void> deleteNight(String id) async {
    final base = _server;
    final override = _NightOverride(
      id: null,
      start: null,
      end: null,
      minutes: null,
      day: base?.lastNightEnd == null
          ? null
          : DateUtils.dateOnly(base!.lastNightEnd!),
    );
    _night = override;
    notifyListeners();
    try {
      await _api.delete(id);
    } on Object {
      if (identical(_night, override)) _night = null;
      notifyListeners();
      rethrow;
    }
    await _confirmed(() {
      if (identical(_night, override)) _night = null;
    });
  }

  /// Hedef (`sleepGoalMin`) ve/veya program (`bedtime`, `wakeTime`).
  Future<void> setGoals({
    int? goalMin,
    String? bedtime,
    String? wakeTime,
  }) async {
    if (goalMin != null) _goalMin = goalMin;
    if (bedtime != null) _bedtime = bedtime;
    if (wakeTime != null) _wakeTime = wakeTime;
    notifyListeners();
    void clear() {
      if (goalMin != null && _goalMin == goalMin) _goalMin = null;
      if (bedtime != null && _bedtime == bedtime) _bedtime = null;
      if (wakeTime != null && _wakeTime == wakeTime) _wakeTime = null;
    }

    try {
      await _api.updateGoals({
        'sleepGoalMin': ?goalMin,
        'bedtime': ?bedtime,
        'wakeTime': ?wakeTime,
      });
    } on Object {
      clear();
      notifyListeners();
      rethrow;
    }
    await _confirmed(clear);
  }

  /// Çıkış / hesap değişimi.
  void reset() {
    _server = null;
    _night = null;
    _goalMin = null;
    _bedtime = null;
    _wakeTime = null;
    _lastWrite = -1;
    notifyListeners();
  }
}

final class _NightOverride {
  const _NightOverride({
    required this.id,
    required this.start,
    required this.end,
    required this.minutes,
    required this.day,
  });

  final String? id;
  final DateTime? start;
  final DateTime? end;

  /// null → gece silindi.
  final int? minutes;

  /// Haftada güncellenecek gün (uyanılan gün).
  final DateTime? day;
}

/// [SleepStore]'un kullandığı uçlar (testte sahtelenir).
abstract interface class SleepApi {
  Future<SleepSummary> summary();
  Future<void> create({required DateTime start, required DateTime end});
  Future<void> update(
    String id, {
    required DateTime start,
    required DateTime end,
  });
  Future<void> delete(String id);
  Future<void> updateGoals(Map<String, dynamic> fields);
}

final class _RepositorySleepApi implements SleepApi {
  const _RepositorySleepApi(this._repo);

  final TrackersRepository _repo;

  @override
  Future<SleepSummary> summary() => _repo.getSleepSummary();

  @override
  Future<void> create({required DateTime start, required DateTime end}) =>
      _repo.createSleep(sleepStart: start, sleepEnd: end);

  @override
  Future<void> update(
    String id, {
    required DateTime start,
    required DateTime end,
  }) => _repo.updateSleep(id, sleepStart: start, sleepEnd: end);

  @override
  Future<void> delete(String id) => _repo.deleteSleep(id);

  @override
  Future<void> updateGoals(Map<String, dynamic> fields) =>
      _repo.updateGoals(fields);
}
