import 'dart:async';

import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/domain/onboarding/onboarding_draft.dart';
import 'package:fastingapp/domain/profile/profile_repository.dart';
import 'package:fastingapp/domain/revenue_cat/revenue_cat_service.dart';
import 'package:fastingapp/presentation/auth/onboard/fasting_plan/bloc/fasting_plan_bloc.dart';
import 'package:fastingapp/presentation/fasting/bloc/fasting_session_cubit.dart';
import 'package:fastingapp/presentation/home/bloc/home_bloc.dart';
import 'package:fastingapp/presentation/home/bloc/home_event.dart';
import 'package:fastingapp/presentation/profile/bloc/profile_event.dart';
import 'package:fastingapp/presentation/profile/bloc/profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'profile_event.dart';
export 'profile_state.dart';

/// Kullanıcı profili (global singleton). Splash / ana sayfa açılışında
/// ısıtılır, Profili Düzenle'ye girildiğinde hazırdır; çıkışta temizlenir.
///
/// Düzenlemeler iyimserdir: değer hemen state'e yazılır, sunucu yanıtı
/// gelince yerine geçer; hata olursa eski değer döner ve [ProfileSaveError]
/// yayılır. Yazmalar sırayla işlenir (araya giren tazeleme ezmesin).
final class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._repository, this._revenueCat, this._homeBloc)
    : super(const ProfileState()) {
    on<ProfileStarted>(_onStarted);
    on<ProfileCleared>((_, emit) => emit(const ProfileState()));
    on<ProfileNameChanged>(_tracked(_onNameChanged), transformer: _sequential);
    on<ProfilePhotoPicked>(_tracked(_onPhotoPicked), transformer: _sequential);
    on<ProfileFieldsChanged>(
      _tracked(_onFieldsChanged),
      transformer: _sequential,
    );
    on<ProfilePlanChanged>(_tracked(_onPlanChanged), transformer: _sequential);
  }

  /// Her yazmanın başında ve sonunda artar. Yazmadan önce başlamış bir
  /// tazelemenin yanıtı (eski ad / avatar / alan) yeni değeri ezmesin.
  var _writes = 0;

  /// Yükleme sürerken gelen zorunlu tazeleme bitince yapılır (önceden
  /// düşüyordu).
  var _refreshAgain = false;

  EventHandler<E, ProfileState> _tracked<E>(
    EventHandler<E, ProfileState> handler,
  ) => (event, emit) async {
    _writes++;
    try {
      await handler(event, emit);
    } finally {
      _writes++;
    }
  };

  final ProfileRepository _repository;
  final RevenueCatService _revenueCat;
  final HomeBloc _homeBloc;
  var _errorSeq = 0;

  static Stream<E> _sequential<E>(Stream<E> events, EventMapper<E> mapper) =>
      events.asyncExpand(mapper);

  Future<void> _onStarted(
    ProfileStarted event,
    Emitter<ProfileState> emit,
  ) async {
    if (_loading) {
      if (event.force) _refreshAgain = true;
      return;
    }
    if (state.isLoaded && !event.force) return;
    _loading = true;
    try {
      await _load(emit);
    } finally {
      _loading = false;
    }
    if (_refreshAgain && !isClosed) {
      _refreshAgain = false;
      add(const ProfileStarted(force: true));
    }
  }

  var _loading = false;

  Future<void> _load(Emitter<ProfileState> emit) async {
    final writes = _writes;
    // Tazelemede mevcut veri ekranda kalır.
    final keepLoaded = state.isLoaded;
    if (!keepLoaded) {
      emit(
        state.copyWith(status: ProfileStatus.loading, loadError: () => null),
      );
    }
    try {
      final results = await Future.wait<Object?>([
        _repository.getAccount(),
        _repository.getProfile(),
        _repository.getCurrentPlanCode(),
      ]);
      final account = results[0]! as ProfileAccount;
      // Araya bir düzenleme girdi: yanıt eski olabilir, sonra yeniden çek.
      if (writes != _writes) {
        _refreshAgain = true;
        return;
      }
      emit(
        state.copyWith(
          status: ProfileStatus.loaded,
          name: () => account.name,
          avatarUrl: () => account.avatarUrl,
          profile: results[1]! as UserProfile,
          plan: () => ProfileRepository.planFromCode(results[2] as String?),
          planCode: () => results[2] as String?,
        ),
      );
    } on Object catch (e) {
      if (keepLoaded) return;
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          loadError: () => e is NetworkException ? e.message : null,
        ),
      );
    }
  }

  Future<void> _onNameChanged(
    ProfileNameChanged event,
    Emitter<ProfileState> emit,
  ) async {
    final previous = state.name;
    emit(state.copyWith(name: () => event.name));
    try {
      final saved = await _repository.updateName(event.name);
      emit(state.copyWith(name: () => saved ?? event.name));
    } on Object catch (e) {
      emit(state.copyWith(name: () => previous, saveError: _error(e)));
    }
  }

  Future<void> _onPhotoPicked(
    ProfilePhotoPicked event,
    Emitter<ProfileState> emit,
  ) async {
    final previous = state.localPhotoPath;
    emit(state.copyWith(localPhotoPath: () => event.path));
    try {
      final url = await _repository.uploadAvatar(event.path);
      emit(state.copyWith(avatarUrl: () => url ?? state.avatarUrl));
    } on Object catch (e) {
      emit(
        state.copyWith(localPhotoPath: () => previous, saveError: _error(e)),
      );
    }
  }

  Future<void> _onFieldsChanged(
    ProfileFieldsChanged event,
    Emitter<ProfileState> emit,
  ) async {
    final previous = state.profile;
    emit(state.copyWith(profile: event.optimistic));
    try {
      final saved = await _repository.updateProfile(event.fields);
      emit(state.copyWith(profile: saved));
      // Kilo ve hedef ana sayfa kartlarında da görünür.
      _homeBloc.add(const HomeRefreshRequested());
    } on Object catch (e) {
      emit(state.copyWith(profile: previous, saveError: _error(e)));
    }
  }

  /// Premium plan premium değilken 402 → paywall; satın alınırsa tekrar
  /// denenir, vazgeçilirse sessizce eski plana dönülür.
  Future<void> _onPlanChanged(
    ProfilePlanChanged event,
    Emitter<ProfileState> emit,
  ) async {
    final previous = state.plan;
    final previousCode = state.planCode;
    String? codeOf(OnboardingFastingPlan? p) =>
        p == null ? null : OnboardingDraft.planCodes[p];
    emit(
      state.copyWith(
        plan: () => event.plan,
        planCode: () => codeOf(event.plan),
      ),
    );
    try {
      final saved = await _trySetPlan(
        event.plan,
        safetyAcknowledged: event.safetyAcknowledged,
      );
      if (saved == null) {
        emit(
          state.copyWith(plan: () => previous, planCode: () => previousCode),
        );
        return;
      }
      emit(state.copyWith(plan: () => saved, planCode: () => codeOf(saved)));
      _homeBloc.add(const HomeRefreshRequested());
      // Oruç sekmesi / Planlar seçili kartı yeni planı göstersin.
      unawaited(getIt<FastingSessionCubit>().refresh(showLoading: false));
    } on Object catch (e) {
      emit(
        state.copyWith(
          plan: () => previous,
          planCode: () => previousCode,
          saveError: _error(e),
        ),
      );
    }
  }

  /// Plan değişince mevcut yeme zamanlaması korunur (önceden sunucu
  /// varsayılanına sıfırlanıyordu). Özel pencere isteyen planlarda (OMAD,
  /// 23:1) sunucu varsayılan başlangıcı (18:00) gönderilir; yoksa reddediliyordu.
  ({String? timing, String? eatStart}) _timingFor(OnboardingFastingPlan plan) {
    const preset = {'skipBreakfast', 'skipDinner', 'earlyWindow', 'lateWindow'};
    final code = OnboardingDraft.planCodes[plan];
    final oneMeal = code == 'omad' || code == '23_1';
    final current = getIt<FastingSessionCubit>().state.plan;
    final timing = current?.timing;
    if (timing != null &&
        preset.contains(timing) &&
        (!oneMeal || timing == 'skipBreakfast' || timing == 'skipDinner')) {
      return (timing: timing, eatStart: null);
    }
    final start = current?.eatWindow?.start;
    if (timing == 'custom' && start != null) {
      return (timing: 'custom', eatStart: start);
    }
    if (oneMeal) return (timing: 'custom', eatStart: '18:00');
    return (timing: null, eatStart: null);
  }

  Future<OnboardingFastingPlan?> _trySetPlan(
    OnboardingFastingPlan plan, {
    required bool safetyAcknowledged,
  }) async {
    final t = _timingFor(plan);
    Future<OnboardingFastingPlan?> put() => _repository.setCurrentPlan(
      plan,
      safetyAcknowledged: safetyAcknowledged,
      timing: t.timing,
      eatStart: t.eatStart,
    );
    try {
      return await put();
    } on NetworkException catch (e) {
      if (!RevenueCatService.needsUpgrade(e)) rethrow;
      if (!await _revenueCat.presentPaywall()) return null;
      return _revenueCat.retryAfterUpgrade(put);
    }
  }

  ProfileSaveError _error(Object e) =>
      ProfileSaveError(++_errorSeq, e is NetworkException ? e.message : null);
}
