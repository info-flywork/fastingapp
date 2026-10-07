import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_bloc.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_state.dart';
import 'package:fastingapp/presentation/auth/splash/bloc/splash_event.dart';
import 'package:fastingapp/presentation/auth/splash/bloc/splash_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Açılış yönlendirmesi: oturum varsa home, yoksa entry. (Doküman 17)
///
/// [AuthBloc] oturumu çözene kadar bekler.
final class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc(this._authBloc) : super(const SplashInitial()) {
    on<SplashStarted>(_onStarted);
  }

  final AuthBloc _authBloc;

  Future<void> _onStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    final auth = await _waitForAuthResolved();
    // Oturum varsa doğrudan uygulama; yoksa landing (entry).
    emit(
      SplashNavigateTo(
        // Onboarding'i bitmemiş misafir baştan başlar (cevaplar sunucuda yok).
        auth is AuthAuthenticated && auth.user.isAnsweredQuestions
            ? RoutePaths.home.path
            : RoutePaths.entry.path,
      ),
    );
  }

  Future<AuthState> _waitForAuthResolved() async {
    final current = _authBloc.state;
    if (current is! AuthInitial) return current;
    return _authBloc.stream
        .firstWhere((state) => state is! AuthInitial)
        .timeout(
          const Duration(seconds: 6),
          onTimeout: () => const AuthUnauthenticated(),
        );
  }
}
