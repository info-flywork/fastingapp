import 'package:fastingapp/data/model/user/user.dart';
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
  }

  final AuthRepository _authRepository;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final isAuthenticated = await _authRepository
          .isAuthenticated()
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
      emit(
        isAuthenticated
            ? const AuthAuthenticated(User())
            : const AuthUnauthenticated(),
      );
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
  }

  Future<void> _onLoggedOut(
    AuthLoggedOut event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(const AuthUnauthenticated());
  }
}
