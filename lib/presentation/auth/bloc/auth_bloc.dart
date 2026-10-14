import 'dart:async';

import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/domain/content/content_repository.dart';
import 'package:fastingapp/domain/trackers/health_sync_service.dart';
import 'package:fastingapp/core/legal/legal_consent_prompt.dart';
import 'package:fastingapp/presentation/fasting/bloc/fasting_session_cubit.dart';
import 'package:fastingapp/presentation/chat/bloc/chat_session_cubit.dart';
import 'package:fastingapp/domain/trackers/trackers_repository.dart';
import 'package:fastingapp/domain/chat/chat_repository.dart';
import 'package:fastingapp/core/home_widgets/water_widget_sync.dart';
import 'package:fastingapp/core/home_widgets/fasting_widget_sync.dart';
import 'package:fastingapp/data/model/auth/account_deletion.dart';
import 'package:fastingapp/domain/auth/auth_repository.dart';
import 'package:fastingapp/domain/gamification/world_repository.dart';
import 'package:fastingapp/domain/notification/notifications_repository.dart';
import 'package:fastingapp/domain/nutrition/meals_repository.dart';
import 'package:fastingapp/domain/nutrition/nutrition_repository.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_event.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_state.dart';
import 'package:fastingapp/presentation/home/bloc/home_bloc.dart';
import 'package:fastingapp/presentation/home/bloc/home_event.dart';
import 'package:fastingapp/presentation/profile/bloc/profile_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Uygulama geneli oturum durumu (global singleton). Router guard bu state'i
/// kullanır. (Doküman 11 / 12)
final class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._authRepository) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoggedIn>(_onLoggedIn);
    on<AuthLoggedOut>(_onLoggedOut);
    on<AuthSessionEnded>(_onSessionEnded);
    on<AuthUserUpdated>((event, emit) => emit(AuthAuthenticated(event.user)));
  }

  final AuthRepository _authRepository;

  /// Hesap silme talebi; başarıda oturum kapanır. Apple penceresi kapatılırsa
  /// `AuthCancelledException`. (Uzun iş: Future döner, loading view'da.)
  Future<AccountDeletion> deleteAccount() async {
    final result = await _authRepository.deleteAccount();
    add(const AuthLoggedOut());
    return result;
  }

  /// Açılış: token varsa önbellekteki kullanıcıyla oturum açık sayılır;
  /// sunucu doğrulaması ilk API çağrısında olur (geçersizse ağ katmanı
  /// [AuthSessionEnded] tetikler).
  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await _authRepository.cachedSession().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      emit(
        user != null ? AuthAuthenticated(user) : const AuthUnauthenticated(),
      );
      // Cihaz kaydı (saat dilimi, dil, sürüm) arka planda.
      if (user != null) unawaited(_authRepository.registerDevice());
    } on Object {
      emit(const AuthUnauthenticated());
    }
  }

  void _onLoggedIn(AuthLoggedIn event, Emitter<AuthState> emit) {
    final user = event.authResponse.user;
    if (user == null) {
      emit(const AuthUnauthenticated());
      return;
    }
    // Başka hesaba geçildiyse (ör. misafirden mevcut hesaba) önceki
    // kullanıcının ekran verisi bırakılır.
    final previous = state;
    if (previous is AuthAuthenticated && previous.user.id != user.id) {
      _clearHomeCache();
    }
    emit(AuthAuthenticated(user));
    unawaited(_authRepository.registerDevice());
  }

  Future<void> _onLoggedOut(
    AuthLoggedOut event,
    Emitter<AuthState> emit,
  ) async {
    // Yalnızca yerel temizlik beklenir; sunucu çağrısı arka planda.
    await _authRepository.logout();
    _clearHomeCache();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onSessionEnded(
    AuthSessionEnded event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthUnauthenticated) return;
    await _authRepository.endLocalSession();
    _clearHomeCache();
    emit(const AuthUnauthenticated());
  }

  /// Önceki kullanıcının ekran verisi bırakılır (ana sayfa + profil).
  void _clearHomeCache() {
    if (getIt.isRegistered<HomeBloc>()) {
      getIt<HomeBloc>().add(const HomeCleared());
    }
    if (getIt.isRegistered<ProfileBloc>()) {
      getIt<ProfileBloc>().add(const ProfileCleared());
    }
    if (getIt.isRegistered<NutritionRepository>()) {
      getIt<NutritionRepository>().clear();
    }
    if (getIt.isRegistered<MealsRepository>()) {
      getIt<MealsRepository>().clearCache();
    }
    if (getIt.isRegistered<WorldRepository>()) {
      getIt<WorldRepository>().clear();
      LegalConsentPrompt.reset();
    }
    if (getIt.isRegistered<NotificationsRepository>()) {
      getIt<NotificationsRepository>().clearCache();
    }
    if (getIt.isRegistered<ChatSessionCubit>()) {
      getIt<ChatSessionCubit>().reset();
    }
    if (getIt.isRegistered<ChatRepository>()) {
      getIt<ChatRepository>().clearSuggestions();
    }
    if (getIt.isRegistered<FastingSessionCubit>()) {
      getIt<FastingSessionCubit>().reset();
    }
    if (getIt.isRegistered<TrackersRepository>()) {
      getIt<TrackersRepository>().clearSession();
    }
    if (getIt.isRegistered<ContentRepository>()) {
      getIt<ContentRepository>().clearInsights();
    }
    if (getIt.isRegistered<HealthSyncService>()) {
      getIt<HealthSyncService>().reset();
    }
    // Ana ekran widget'ları önceki kullanıcının verisini göstermesin.
    unawaited(FastingWidgetSync.clear());
    unawaited(WaterWidgetSync.clear());
  }
}
