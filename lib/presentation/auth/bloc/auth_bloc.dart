import 'dart:async';

import 'package:fastingapp/data/model/auth/account_deletion.dart';
import 'package:fastingapp/domain/auth/auth_repository.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_event.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_state.dart';
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
    emit(AuthAuthenticated(user));
    unawaited(_authRepository.registerDevice());
  }

  Future<void> _onLoggedOut(
    AuthLoggedOut event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onSessionEnded(
    AuthSessionEnded event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthUnauthenticated) return;
    await _authRepository.endLocalSession();
    emit(const AuthUnauthenticated());
  }
}
