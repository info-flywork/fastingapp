import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/core/sync/data_sync.dart';
import 'package:fastingapp/domain/fasting/fasting_repository.dart';
import 'package:fastingapp/domain/fasting/plan_catalog_repository.dart';
import 'package:fastingapp/domain/fasting/weekly_schedule.dart';
import 'package:fastingapp/domain/revenue_cat/revenue_cat_service.dart';
import 'package:fastingapp/presentation/fasting/bloc/fasting_session_state.dart';

/// Aktif oruç + plan; oruç sekmesi ve widget senkronu. Başlatma / bitirme /
/// plan değişikliğinden sonra ana sayfa (seri, hafta, kart) da tazelenir.
final class FastingSessionCubit extends Cubit<FastingSessionState> {
  FastingSessionCubit(this._repository, this._revenueCat)
    : super(const FastingSessionState());

  final FastingRepository _repository;
  final RevenueCatService _revenueCat;

  /// Süren yazma (başlat / bitir / iptal / plan) sayısı ve onaylı yazma
  /// sırası. Yazma sürerken ya da yazmadan önce başlamış bir okumanın
  /// (`refresh`, ana sayfa özeti) cevabı ekranı geri almaz: başlatılan oruç
  /// bir an kaybolup, bitirilen oruç bir an geri gelmez.
  int _pendingWrites = 0;
  int _writeSeq = 0;

  Future<T> _write<T>(Future<T> Function() body) async {
    _pendingWrites++;
    try {
      return await body();
    } finally {
      _pendingWrites--;
      _writeSeq++;
    }
  }

  bool _isStale(int seqAtStart) =>
      _pendingWrites > 0 || seqAtStart != _writeSeq;

  /// Çıkış / hesap değişimi: önceki kullanıcının orucu ekranda kalmasın.
  void reset() => emit(const FastingSessionState());

  Future<void> refresh({bool showLoading = true}) =>
      _load(showLoading: showLoading, guard: true);

  /// [guard] false: bir yazmanın içinden, sunucu onayladıktan sonra
  /// çağrılır (cevap taze; yok sayılmaz).
  Future<void> _load({required bool showLoading, required bool guard}) async {
    final seqAtStart = _writeSeq;
    if (showLoading) emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final results = await Future.wait([
        _repository.getActive(),
        _repository.getCurrentPlan(),
      ]);
      if (guard && _isStale(seqAtStart)) {
        if (showLoading) emit(state.copyWith(isLoading: false));
        return;
      }
      final active = results[0] as ActiveFastingSnapshot;
      final planEnv = results[1] as CurrentPlanEnvelope;
      final fetchedAt = DateTime.now();
      final offset = clockOffsetFromServer(active.serverTime, fetchedAt);
      emit(
        state.copyWith(
          isLoading: false,
          fast: active.fast,
          eatingWindow: active.eatingWindow,
          plan: planEnv.plan,
          fetchedAt: fetchedAt,
          clockOffset: offset,
          clearFast: active.fast == null,
          clearEating: active.eatingWindow == null,
        ),
      );
    } on NetworkException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } on Object catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: errorMessageOf(e)));
    }
  }

  Future<void> ensureBodyStages() async {
    if (state.bodyStages.isNotEmpty) return;
    try {
      final items = await _repository.getBodyStages();
      emit(state.copyWith(bodyStages: items));
    } on Object {
      // Katalog yüklenemezse yerel fallback kullanılır.
    }
  }

  Future<void> startFast({DateTime? startedAt, int? targetMinutes}) => _write(
    () => _startFast(startedAt: startedAt, targetMinutes: targetMinutes),
  );

  Future<void> _startFast({DateTime? startedAt, int? targetMinutes}) async {
    final start = startedAt ?? DateTime.now();
    final minutes =
        targetMinutes ??
        state.plan?.fastMinutes ??
        state.fast?.targetMinutes ??
        16 * 60;
    final fetchedAt = DateTime.now();
    // Optimistic: UI ve ana sayfa kartı sunucu yanıtını beklemeden güncellenir.
    final optimistic = ActiveFast(
      id: '_local',
      planCode: state.plan?.planCode,
      targetMinutes: minutes,
      startedAt: start,
      plannedEndAt: start.add(Duration(minutes: minutes)),
      serverTime: fetchedAt,
    );
    final previous = state;
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        fast: optimistic,
        fetchedAt: fetchedAt,
        clockOffset: Duration.zero,
        clearEating: true,
      ),
    );
    try {
      // POST yanıtı oruç DTO'sunu taşır: ayrıca /fasts/active + /plans/current
      // istenmez; seri/hafta için özet (afterWrite) yenilenir.
      final fast = await _repository.startFast(
        startedAt: start,
        targetMinutes: targetMinutes,
      );
      final at = DateTime.now();
      emit(
        state.copyWith(
          isLoading: false,
          fast: fast,
          fetchedAt: at,
          clockOffset: clockOffsetFromServer(fast.serverTime, at),
          clearEating: true,
        ),
      );
      DataSync.afterWrite();
    } on NetworkException catch (e) {
      if (e.code == 'ACTIVE_FAST_EXISTS') {
        await _load(showLoading: false, guard: false);
        return;
      }
      emit(previous.copyWith(isLoading: false, errorMessage: e.message));
    } on Object catch (e) {
      emit(
        previous.copyWith(isLoading: false, errorMessage: errorMessageOf(e)),
      );
    }
  }

  Future<FinishFastResult?> finishFast({
    required String fastId,
    DateTime? endedAt,
    DateTime? startedAt,
    String? feeling,
    String? notes,
    double? weightKg,
  }) => _write(() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final result = await _repository.finishFast(
        fastId,
        endedAt: endedAt,
        startedAt: startedAt,
        feeling: feeling,
        notes: notes,
        weightKg: weightKg,
      );
      emit(state.copyWith(isLoading: false, clearFast: true));
      await _load(showLoading: false, guard: false);
      // Seri, hafta şeridi, XP; bitişte kilo girildiyse profil de.
      DataSync.afterWrite(profile: weightKg != null);
      return result;
    } on NetworkException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
      return null;
    } on Object catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: errorMessageOf(e)));
      return null;
    }
  });

  /// Planı sunucuda değiştirir (bir sonraki oruçtan geçerli). Premium plan
  /// için paywall; vazgeçilirse false (hata yok). Hata mesajı state'te.
  /// Uzun planlarda [safetyAcknowledged] kullanıcı onayından gelmeli.
  Future<bool> changePlan({
    required String planCode,
    String? timing,
    String? eatStart,
    String? eatEnd,
    List<WeeklyDay>? weeklySchedule,
    bool safetyAcknowledged = false,
  }) async {
    final changed = await _write(
      () => _putPlan(
        planCode: planCode,
        timing: timing,
        eatStart: eatStart,
        eatEnd: eatEnd,
        weeklySchedule: weeklySchedule,
        safetyAcknowledged: safetyAcknowledged,
      ),
    );
    if (changed) DataSync.afterWrite(profile: true);
    return changed;
  }

  Future<bool> _putPlan({
    required String planCode,
    required bool safetyAcknowledged,
    String? timing,
    String? eatStart,
    String? eatEnd,
    List<WeeklyDay>? weeklySchedule,
  }) async {
    Future<CurrentPlanEnvelope> put() => _repository.setCurrentPlan(
      planCode: planCode,
      timing: timing,
      eatStart: eatStart,
      eatEnd: eatEnd,
      weeklySchedule: weeklySchedule,
      safetyAcknowledged: safetyAcknowledged,
    );
    // Seçilen plan anında görünür (Planlar kartı, oruç sekmesi); sunucu
    // reddederse / paywall kapatılırsa eski plana dönülür. Önceki hata bu
    // çağrının sonucu sanılmasın.
    final previous = state.plan;
    emit(
      state.copyWith(
        plan: _optimisticPlan(
          previous: previous,
          planCode: planCode,
          timing: timing,
          eatStart: eatStart,
          eatEnd: eatEnd,
          weeklySchedule: weeklySchedule,
        ),
        clearError: true,
      ),
    );
    void revert({String? error}) => emit(
      state.copyWith(
        plan: previous,
        clearPlan: previous == null,
        errorMessage: error,
      ),
    );
    try {
      CurrentPlanEnvelope env;
      try {
        env = await put();
      } on NetworkException catch (e) {
        if (!RevenueCatService.needsUpgrade(e)) rethrow;
        if (!await _revenueCat.presentPaywall()) {
          revert();
          return false;
        }
        env = await _revenueCat.retryAfterUpgrade(put);
      }
      emit(state.copyWith(plan: env.plan, clearError: true));
      return true;
    } on NetworkException catch (e) {
      revert(error: e.message);
      return false;
    } on Object catch (e) {
      revert(error: errorMessageOf(e));
      return false;
    }
  }

  /// Sunucu yanıtı gelene kadar gösterilecek plan: süre katalogdan, pencere
  /// / zamanlama seçimden; aynı plan kalıyorsa bilinen alanlar korunur.
  static UserFastingPlan _optimisticPlan({
    required UserFastingPlan? previous,
    required String planCode,
    String? timing,
    String? eatStart,
    String? eatEnd,
    List<WeeklyDay>? weeklySchedule,
  }) {
    final same = previous?.planCode == planCode ? previous : null;
    final entry = getIt.isRegistered<PlanCatalogRepository>()
        ? getIt<PlanCatalogRepository>().entry(planCode)
        : null;
    final fastHours = entry?.fastHours;
    return UserFastingPlan(
      planCode: planCode,
      displayName: same?.displayName,
      fastMinutes: fastHours != null
          ? fastHours * 60
          : same?.fastMinutes ?? 960,
      timing: timing ?? same?.timing ?? entry?.defaultTiming,
      eatWindow: eatStart != null && eatEnd != null
          ? EatWindow(start: eatStart, end: eatEnd)
          : same?.eatWindow,
      weeklySchedule: weeklySchedule ?? same?.weeklySchedule ?? const [],
    );
  }

  /// Aktif orucu iptal eder (`POST /fasts/:id/cancel`).
  Future<bool> cancelActiveFast() => _write(() async {
    final id = state.fast?.id;
    if (id == null || id.isEmpty) return false;
    if (state.errorMessage != null) emit(state.copyWith(clearError: true));
    try {
      await _repository.cancelFast(id);
      await _load(showLoading: false, guard: false);
      DataSync.afterWrite();
      return true;
    } on NetworkException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
      return false;
    } on Object catch (e) {
      emit(state.copyWith(errorMessage: errorMessageOf(e)));
      return false;
    }
  });

  /// Aktif oruçta plan değişikliği: önce plan kaydedilir (paywall / ret
  /// olursa oruç bozulmaz), sonra aktif oruç iptal edilir;
  /// [restartWithSameData] ise aynı [startedAt] ile yeni planda yeniden başlar.
  Future<bool> changePlanWhileFasting({
    required String planCode,
    required bool restartWithSameData,
    String? timing,
    String? eatStart,
    String? eatEnd,
    List<WeeklyDay>? weeklySchedule,
    bool safetyAcknowledged = false,
  }) => _write(() async {
    final fastId = state.fast?.id;
    final startedAt = state.fast?.startedAt;
    final changed = await _putPlan(
      planCode: planCode,
      timing: timing,
      eatStart: eatStart,
      eatEnd: eatEnd,
      weeklySchedule: weeklySchedule,
      safetyAcknowledged: safetyAcknowledged,
    );
    if (!changed) return false;
    try {
      if (fastId != null && fastId.isNotEmpty) {
        await _repository.cancelFast(fastId);
      }
      if (restartWithSameData) {
        await _repository.startFast(startedAt: startedAt);
      }
      return true;
    } on NetworkException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
      return false;
    } on Object catch (e) {
      emit(state.copyWith(errorMessage: errorMessageOf(e)));
      return false;
    } finally {
      // Başarılı ya da yarım kalmış olsun, ekran sunucudaki gerçek durumu
      // göstersin; loading dialog'u bunu beklemez.
      unawaited(_load(showLoading: false, guard: false));
      DataSync.afterWrite(profile: true);
    }
  });

  void applyFromSummary({
    ActiveFast? fast,
    EatingWindow? eatingWindow,
    UserFastingPlan? plan,
    DateTime? serverTime,
  }) {
    // Yazma sürerken gelen özet, yazmadan önceki durumu taşır.
    if (_pendingWrites > 0) return;
    final fetchedAt = DateTime.now();
    emit(
      state.copyWith(
        fast: fast,
        eatingWindow: eatingWindow,
        plan: plan,
        fetchedAt: fetchedAt,
        clockOffset: clockOffsetFromServer(serverTime, fetchedAt),
        clearFast: fast == null,
        clearEating: eatingWindow == null,
      ),
    );
  }
}
