import 'dart:async';

import 'package:fastingapp/core/sync/data_sync.dart';
import 'package:fastingapp/domain/trackers/trackers_repository.dart';
import 'package:flutter/foundation.dart';

/// Kilonun tek kaynağı (Kilo geçmişi ekranı + ana sayfa kilo kartı).
///
/// - Özet ve grafikler bellekte kalır; ekran tekrar açılınca beklemeden
///   dolu gelir, arkadan sessizce tazelenir.
/// - Yeni tartı ve hedef anında görünür (iyimser); sunucu onaylayınca taze
///   özet / grafik gelir, sonra iyimser değer kalkar (arada eskiye düşmez).
///   Hata olursa eski değere döner. Yazmadan önce başlamış eski GET geri
///   almaz.
final class WeightStore extends ChangeNotifier {
  WeightStore(TrackersRepository trackers)
    : this.withApi(
        _RepositoryWeightApi(trackers),
        afterWrite: () => DataSync.afterWrite(profile: true),
      );

  /// Testler sahte API ve yazma sonrası kancası verir.
  @visibleForTesting
  WeightStore.withApi(this._api, {void Function()? afterWrite})
    : _afterWrite = afterWrite ?? (() {});

  final WeightApi _api;
  final void Function() _afterWrite;

  WeightSummary? _summary;
  final _charts = <String, WeightChart>{};
  Future<void>? _summaryInFlight;
  final _chartsInFlight = <String, Future<WeightChart>>{};

  /// Onaylı yazma sırası: yazmadan önce başlamış GET sonucu yok sayılır.
  int _writeSeq = 0;
  int _lastWrite = -1;

  /// Sunucu henüz onaylamadı.
  double? _pendingKg;
  double? _pendingGoal;

  WeightSummary? get summary => _summary;

  double? get currentKg => _pendingKg ?? _summary?.currentKg;

  double? get goalKg => _pendingGoal ?? _summary?.goalKg;

  double? get pendingKg => _pendingKg;

  double? get pendingGoal => _pendingGoal;

  /// Bellekteki grafik ([range]: day | week | month).
  WeightChart? chart(String range) => _charts[range];

  /// `GET /weights/summary`. Süren istek paylaşılır.
  Future<void> loadSummary() {
    final running = _summaryInFlight;
    if (running != null) return running;
    final seqAtStart = _writeSeq;
    return _summaryInFlight = _api
        .summary()
        .then((s) {
          if (_lastWrite >= seqAtStart) return;
          _summary = s;
          notifyListeners();
        })
        .whenComplete(() => _summaryInFlight = null);
  }

  /// `GET /weights/chart?range=`. Süren istek paylaşılır.
  Future<WeightChart> loadChart(String range) {
    final running = _chartsInFlight[range];
    if (running != null) return running;
    final seqAtStart = _writeSeq;
    final future = _api
        .chart(range)
        .then((c) {
          if (_lastWrite < seqAtStart) {
            _charts[range] = c;
            notifyListeners();
          }
          return _charts[range] ?? c;
        })
        .whenComplete(() {
          _chartsInFlight.remove(range);
        });
    return _chartsInFlight[range] = future;
  }

  /// Yeni tartı (bugün).
  Future<void> addWeight(double kg, {String visibleRange = 'day'}) async {
    _pendingKg = kg;
    notifyListeners();
    try {
      await _api.create(kg);
    } on Object {
      if (_pendingKg == kg) _pendingKg = null;
      notifyListeners();
      rethrow;
    }
    _lastWrite = _writeSeq++;
    _charts.clear();
    _afterWrite();
    try {
      // Önce başlamış istekler bitsin (yok sayılır), sonra taze veri.
      await Future.wait([
        ?_summaryInFlight,
        ..._chartsInFlight.values,
      ]).catchError((Object _) => <Object?>[]);
      await Future.wait([loadSummary(), loadChart(visibleRange)]);
    } on Object {
      // İyimser değer kalır; sonraki açılışta tazelenir.
      return;
    }
    if (_pendingKg == kg) _pendingKg = null;
    notifyListeners();
  }

  /// Hedef kilo; yanıt güncel özeti taşır.
  Future<void> setGoal(double kg) async {
    _pendingGoal = kg;
    notifyListeners();
    try {
      final summary = await _api.setGoal(kg);
      _lastWrite = _writeSeq++;
      _summary = summary;
      _afterWrite();
    } finally {
      if (_pendingGoal == kg) _pendingGoal = null;
      notifyListeners();
    }
  }

  /// Çıkış / hesap değişimi.
  void reset() {
    _summary = null;
    _charts.clear();
    _pendingKg = null;
    _pendingGoal = null;
    _lastWrite = -1;
    notifyListeners();
  }
}

/// [WeightStore]'un kullandığı uçlar (testte sahtelenir).
abstract interface class WeightApi {
  Future<WeightSummary> summary();
  Future<WeightChart> chart(String range);
  Future<void> create(double kg);
  Future<WeightSummary> setGoal(double kg);
}

final class _RepositoryWeightApi implements WeightApi {
  const _RepositoryWeightApi(this._repo);

  final TrackersRepository _repo;

  @override
  Future<WeightSummary> summary() => _repo.getWeightSummary();

  @override
  Future<WeightChart> chart(String range) => _repo.getWeightChart(range);

  @override
  Future<void> create(double kg) => _repo.createWeight(weightKg: kg);

  @override
  Future<WeightSummary> setGoal(double kg) => _repo.setWeightGoal(kg);
}
