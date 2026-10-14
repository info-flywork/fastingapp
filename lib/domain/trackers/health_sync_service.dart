import 'dart:async';
import 'dart:io';

import 'package:fastingapp/core/sync/data_sync.dart';
import 'package:fastingapp/domain/profile/profile_repository.dart';
import 'package:fastingapp/domain/trackers/trackers_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// Apple Health / Health Connect → `POST /steps/sync`.
///
/// Android'de Google Fit kaldırıldı; kaynak alanı API sözleşmesi gereği
/// `googleFit` kalır (Health Connect).
final class HealthSyncService {
  HealthSyncService(this._trackers, this._profile);

  final TrackersRepository _trackers;
  final ProfileRepository _profile;

  final Health _health = Health();
  var _configured = false;
  var _syncing = false;
  DateTime? _lastSync;

  static const _types = [HealthDataType.STEPS];

  /// Yalnızca okuma: Apple Health / Health Connect'e hiçbir şey yazılmaz.
  static const _read = [HealthDataAccess.READ];
  static const _minInterval = Duration(minutes: 15);

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Profil anahtarı açıkken izin iste; reddedilirse false.
  Future<bool> enable() async {
    await _ensureConfigured();
    if (Platform.isAndroid) {
      final available = await _health.isHealthConnectAvailable();
      if (!available) {
        await _health.installHealthConnect();
        return false;
      }
    }
    final ok = await _health.requestAuthorization(_types, permissions: _read);
    if (!ok) return false;
    // Health Connect geçmişi (30 günden eski) için ek izin.
    if (Platform.isAndroid) {
      try {
        await _health.requestHealthDataHistoryAuthorization();
      } on Object {
        // Opsiyonel; yoksa son 30 gün yine okunur.
      }
    }
    await _profile.updateSettings(healthSyncEnabled: true);
    unawaited(sync(force: true));
    return true;
  }

  Future<void> disable() async {
    await _profile.updateSettings(healthSyncEnabled: false);
  }

  Future<void>? _running;

  /// Ayar açıksa son 31 günü sunucuya yazar. Sessiz; hata yutulur.
  /// Süren bir senkron varsa onu bekler (Adım ekranı senkron öncesi veriyi
  /// göstermesin); yazınca ana sayfa / adım verisi tazelenir.
  Future<void> sync({bool force = false}) {
    final running = _running;
    if (running != null) return running;
    return _running = _sync(force: force).whenComplete(() => _running = null);
  }

  /// Çıkış / hesap değişimi: önceki hesabın kısıtı yeni hesaba taşınmasın.
  void reset() => _lastSync = null;

  Future<void> _sync({required bool force}) async {
    if (_syncing) return;
    if (!force &&
        _lastSync != null &&
        DateTime.now().difference(_lastSync!) < _minInterval) {
      return;
    }
    _syncing = true;
    try {
      final settings = await _profile.getSettings();
      if (!settings.healthSyncEnabled) return;

      await _ensureConfigured();
      if (Platform.isAndroid && !await _health.isHealthConnectAvailable()) {
        return;
      }

      // Arka plan senkronu izin istemez: izin geri alınmışsa Android her ön
      // plana dönüşte Health Connect izin ekranını açıyordu. İzin yalnızca
      // Profil anahtarında (`enable`) istenir. iOS okuma iznini söylemez
      // (null): okunur, izin yoksa veri boş gelir.
      final granted = await _health.hasPermissions(_types, permissions: _read);
      if (granted == false) {
        _lastSync = DateTime.now();
        return;
      }

      final days = await _readLastDays(31);
      if (days.isEmpty) return;

      final result = await _trackers.syncSteps(
        source: Platform.isIOS ? 'appleHealth' : 'googleFit',
        days: days,
      );
      _lastSync = DateTime.now();
      // Önceden ana sayfa adım kartı senkron öncesi sayıda kalıyordu.
      if (result.updated > 0) DataSync.afterWrite();
    } on Object catch (e, st) {
      debugPrint('HealthSyncService.sync: $e\n$st');
    } finally {
      _syncing = false;
    }
  }

  Future<List<({String date, int steps})>> _readLastDays(int count) async {
    final today = DateTime.now();
    final startDay = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: count - 1));
    final out = <({String date, int steps})>[];

    for (var i = 0; i < count; i++) {
      final day = startDay.add(Duration(days: i));
      final from = DateTime(day.year, day.month, day.day);
      final to = from
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));
      try {
        final steps = await _health.getTotalStepsInInterval(from, to);
        if (steps == null || steps <= 0) continue;
        out.add((date: _ymd(from), steps: steps));
      } on Object {
        // Gün atlanır.
      }
    }
    return out;
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
