import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/domain/profile/profile_repository.dart';
import 'package:fastingapp/domain/revenue_cat/revenue_cat_service.dart';
import 'package:fastingapp/presentation/auth/onboard/fasting_plan/bloc/fasting_plan_bloc.dart';
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
    on<ProfileNameChanged>(_onNameChanged, transformer: _sequential);
    on<ProfilePhotoPicked>(_onPhotoPicked, transformer: _sequential);
    on<ProfileFieldsChanged>(_onFieldsChanged, transformer: _sequential);
    on<ProfilePlanChanged>(_onPlanChanged, transformer: _sequential);
  }

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
    if (state.status == ProfileStatus.loading) return;
    if (state.isLoaded && !event.force) return;
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
        _repository.getCurrentPlan(),
      ]);
      final account = results[0]! as ProfileAccount;
      emit(
        state.copyWith(
          status: ProfileStatus.loaded,
          name: () => account.name,
          avatarUrl: () => account.avatarUrl,
          profile: results[1]! as UserProfile,
          plan: () => results[2] as OnboardingFastingPlan?,
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
    emit(state.copyWith(plan: () => event.plan));
    try {
      final saved = await _trySetPlan(event.plan);
      if (saved == null) {
        emit(state.copyWith(plan: () => previous));
        return;
      }
      emit(state.copyWith(plan: () => saved));
      _homeBloc.add(const HomeRefreshRequested());
    } on Object catch (e) {
      emit(state.copyWith(plan: () => previous, saveError: _error(e)));
    }
  }

  Future<OnboardingFastingPlan?> _trySetPlan(OnboardingFastingPlan plan) async {
    try {
      return await _repository.setCurrentPlan(plan);
    } on NetworkException catch (e) {
      if (!RevenueCatService.needsUpgrade(e)) rethrow;
      if (!await _revenueCat.presentPaywall()) return null;
      return _repository.setCurrentPlan(plan);
    }
  }

  ProfileSaveError _error(Object e) =>
      ProfileSaveError(++_errorSeq, e is NetworkException ? e.message : null);
}
