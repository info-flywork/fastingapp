import 'package:bloc/bloc.dart';
import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/core/sync/data_sync.dart';
import 'package:fastingapp/domain/fasting/fasting_repository.dart';
import 'package:fastingapp/domain/revenue_cat/revenue_cat_service.dart';
import 'package:fastingapp/presentation/fasting/bloc/fasting_session_state.dart';

/// Aktif oruç + plan; oruç sekmesi ve widget senkronu. Başlatma / bitirme /
/// plan değişikliğinden sonra ana sayfa (seri, hafta, kart) da tazelenir.
final class FastingSessionCubit extends Cubit<FastingSessionState> {
  FastingSessionCubit(this._repository, this._revenueCat)
    : super(const FastingSessionState());

  final FastingRepository _repository;
  final RevenueCatService _revenueCat;

  Future<void> refresh({bool showLoading = true}) async {
    if (showLoading) emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final results = await Future.wait([
        _repository.getActive(),
        _repository.getCurrentPlan(),
      ]);
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
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
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

  Future<void> startFast({DateTime? startedAt}) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _repository.startFast(startedAt: startedAt);
      await refresh(showLoading: false);
      DataSync.afterWrite();
    } on NetworkException catch (e) {
      if (e.code == 'ACTIVE_FAST_EXISTS') {
        await refresh(showLoading: false);
        return;
      }
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    } on Object catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<FinishFastResult?> finishFast({
    required String fastId,
    DateTime? endedAt,
    DateTime? startedAt,
    String? feeling,
    String? notes,
    double? weightKg,
  }) async {
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
      emit(
        state.copyWith(isLoading: false, clearFast: true, eatingWindow: null),
      );
      await refresh(showLoading: false);
      // Seri, hafta şeridi, XP; bitişte kilo girildiyse profil de.
      DataSync.afterWrite(profile: weightKg != null);
      return result;
    } on NetworkException catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
      return null;
    } on Object catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      return null;
    }
  }

  /// Planı sunucuda değiştirir (bir sonraki oruçtan geçerli). Premium plan
  /// için paywall; vazgeçilirse false (hata yok). Hata mesajı state'te.
  Future<bool> changePlan({
    required String planCode,
    String? timing,
    String? eatStart,
    String? eatEnd,
  }) async {
    Future<CurrentPlanEnvelope> put() => _repository.setCurrentPlan(
      planCode: planCode,
      timing: timing,
      eatStart: eatStart,
      eatEnd: eatEnd,
    );
    // Önceki hata bu çağrının sonucu sanılmasın.
    if (state.errorMessage != null) emit(state.copyWith(clearError: true));
    try {
      CurrentPlanEnvelope env;
      try {
        env = await put();
      } on NetworkException catch (e) {
        if (!RevenueCatService.needsUpgrade(e)) rethrow;
        if (!await _revenueCat.presentPaywall()) return false;
        env = await put();
      }
      emit(state.copyWith(plan: env.plan, clearError: true));
      DataSync.afterWrite(profile: true);
      return true;
    } on NetworkException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
      return false;
    } on Object catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  /// Aktif orucu iptal eder (`POST /fasts/:id/cancel`).
  Future<bool> cancelActiveFast() async {
    final id = state.fast?.id;
    if (id == null || id.isEmpty) return false;
    if (state.errorMessage != null) emit(state.copyWith(clearError: true));
    try {
      await _repository.cancelFast(id);
      await refresh(showLoading: false);
      DataSync.afterWrite();
      return true;
    } on NetworkException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
      return false;
    } on Object catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  /// Aktif orucu iptal + plan kaydı; [restartWithSameData] ise aynı
  /// [startedAt] ile yeni oruç başlatır.
  Future<bool> changePlanWhileFasting({
    required String planCode,
    String? timing,
    String? eatStart,
    String? eatEnd,
    required bool restartWithSameData,
  }) async {
    final startedAt = state.fast?.startedAt;
    final cancelled = await cancelActiveFast();
    if (!cancelled) return false;
    final changed = await changePlan(
      planCode: planCode,
      timing: timing,
      eatStart: eatStart,
      eatEnd: eatEnd,
    );
    if (!changed) return false;
    if (!restartWithSameData) return true;
    try {
      await _repository.startFast(startedAt: startedAt);
      await refresh(showLoading: false);
      DataSync.afterWrite();
      return true;
    } on NetworkException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
      return false;
    } on Object catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  void applyFromSummary({
    ActiveFast? fast,
    EatingWindow? eatingWindow,
    UserFastingPlan? plan,
    DateTime? serverTime,
  }) {
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
