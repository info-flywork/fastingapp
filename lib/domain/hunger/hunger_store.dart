import 'dart:async';

import 'package:fastingapp/core/sync/data_sync.dart';
import 'package:fastingapp/domain/hunger/hunger_repository.dart';
import 'package:fastingapp/presentation/hunger_tracker/hunger_symptom.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateUtils;

/// Açlık kayıtlarının tek kaynağı (Açlık geçmişi + ana sayfa açlık kartı).
///
/// - Liste ve hafta şeridi bellekte kalır; ekran tekrar açılınca beklemeden
///   dolu gelir, arkadan sessizce tazelenir.
/// - Yeni check-in kaydedilince liste, şerit ve bugünkü sayılar anında
///   güncellenir; sunucudan taze veri gelince iyimser hal kalkar (arada
///   eskiye düşmez). Yazmadan önce başlamış eski GET geri almaz.
final class HungerStore extends ChangeNotifier {
  HungerStore(HungerRepository repo)
    : this.withApi(_RepositoryHungerApi(repo), afterWrite: DataSync.afterWrite);

  /// Testler sahte API ve yazma sonrası kancası verir.
  @visibleForTesting
  HungerStore.withApi(this._api, {void Function()? afterWrite})
    : _afterWrite = afterWrite ?? (() {});

  final HungerApi _api;
  final void Function() _afterWrite;

  List<HungerCheckinItem>? _entries;
  HungerCheckinSummary? _summary;
  Future<void>? _inFlight;

  /// Onaylı yazma sırası: yazmadan önce başlamış GET sonucu yok sayılır.
  int _writeSeq = 0;
  int _lastWrite = -1;

  /// Kaydedildi ama taze liste/özet henüz gelmedi: ana sayfa sayıları bu
  /// sırada store'dan okunur (eski özet geri almasın).
  bool _awaitingFresh = false;

  List<HungerCheckinItem>? get entries => _entries;

  List<HungerWeekDay> get week => _summary?.week ?? const [];

  /// Bugünkü sayılar yalnızca taze veri beklenirken (ana sayfa üstüne biner).
  ({int physical, int emotional})? get pendingToday {
    final s = _summary;
    if (!_awaitingFresh || s == null) return null;
    return (physical: s.todayPhysical, emotional: s.todayEmotional);
  }

  /// Liste + özet paralel. Süren istek paylaşılır.
  Future<void> load() {
    final running = _inFlight;
    if (running != null) return running;
    final seqAtStart = _writeSeq;
    return _inFlight = Future.wait([_api.list(), _api.summary()])
        .then((r) {
          if (_lastWrite >= seqAtStart) return;
          _entries = r[0] as List<HungerCheckinItem>;
          _summary = r[1] as HungerCheckinSummary;
          _awaitingFresh = false;
          notifyListeners();
        })
        .whenComplete(() => _inFlight = null);
  }

  /// Check-in kaydeder; listeye, şeride ve bugünkü sayılara anında eklenir.
  Future<HungerEvaluation> save({
    required HungerFlowArgs flow,
    required String mode,
    String? notes,
  }) async {
    final evaluation = await _api.save(flow: flow, mode: mode, notes: notes);
    _lastWrite = _writeSeq++;
    _insertLocally(evaluation.resultType ?? 'physical');
    _afterWrite();
    unawaited(_refreshAfterWrite());
    return evaluation;
  }

  void _insertLocally(String type) {
    final now = DateTime.now();
    final emotional = type == 'emotional';
    _entries = [
      HungerCheckinItem(id: 'local-$now', loggedAt: now, resultType: type),
      ...?_entries,
    ];
    final s = _summary ?? const HungerCheckinSummary();
    final today = DateUtils.dateOnly(now);
    _summary = HungerCheckinSummary(
      todayTotal: s.todayTotal + 1,
      todayPhysical: s.todayPhysical + (emotional ? 0 : 1),
      todayEmotional: s.todayEmotional + (emotional ? 1 : 0),
      week: [
        for (final d in s.week)
          DateUtils.isSameDay(DateTime.tryParse(d.date), today)
              ? HungerWeekDay(
                  date: d.date,
                  physical: d.physical + (emotional ? 0 : 1),
                  emotional: d.emotional + (emotional ? 1 : 0),
                  fastedMinutes: d.fastedMinutes,
                )
              : d,
      ],
    );
    _awaitingFresh = true;
    notifyListeners();
  }

  Future<void> _refreshAfterWrite() async {
    try {
      await _inFlight; // yazmadan önce başlamış GET bitsin (yok sayılır)
      await load();
    } on Object {
      // İyimser hal kalır; sonraki açılışta tazelenir.
    }
  }

  /// Çıkış / hesap değişimi.
  void reset() {
    _entries = null;
    _summary = null;
    _awaitingFresh = false;
    _lastWrite = -1;
    notifyListeners();
  }
}

/// [HungerStore]'un kullandığı uçlar (testte sahtelenir).
abstract interface class HungerApi {
  Future<List<HungerCheckinItem>> list();
  Future<HungerCheckinSummary> summary();
  Future<HungerEvaluation> save({
    required HungerFlowArgs flow,
    required String mode,
    String? notes,
  });
}

final class _RepositoryHungerApi implements HungerApi {
  const _RepositoryHungerApi(this._repo);

  final HungerRepository _repo;

  @override
  Future<List<HungerCheckinItem>> list() => _repo.listCheckins();

  @override
  Future<HungerCheckinSummary> summary() => _repo.getSummary();

  @override
  Future<HungerEvaluation> save({
    required HungerFlowArgs flow,
    required String mode,
    String? notes,
  }) => _repo.saveCheckin(flow: flow, mode: mode, notes: notes);
}
