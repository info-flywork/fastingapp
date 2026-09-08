import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/utils/enum/auth_provider_type.dart';
import 'package:fastingapp/domain/auth/auth_repository.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_bloc.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_event.dart';
import 'package:fastingapp/presentation/auth/welcome/bloc/welcome_event.dart';
import 'package:fastingapp/presentation/auth/welcome/bloc/welcome_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Karşılama ekranı: sosyal giriş ve misafir girişi. (Doküman 17)
final class WelcomeBloc extends Bloc<WelcomeEvent, WelcomeState> {
  WelcomeBloc(this._authRepository, this._authBloc)
    : super(const WelcomeInitial()) {
    on<WelcomeGoogleTapped>(_onGoogleTapped);
    on<WelcomeGuestTapped>(_onGuestTapped);
  }

  final AuthRepository _authRepository;
  final AuthBloc _authBloc;

  Future<void> _onGoogleTapped(
    WelcomeGoogleTapped event,
    Emitter<WelcomeState> emit,
  ) async {
    emit(const WelcomeLoading());
    try {
      // TODO(team): Google SDK ile idToken al.
      const googleToken = 'google-id-token';

      final authResponse = await _authRepository.login(
        providerType: AuthProviderType.google,
        token: googleToken,
      );

      _authBloc.add(AuthLoggedIn(authResponse));

      final answered = authResponse.user?.isAnsweredQuestions ?? false;
      emit(
        WelcomeSuccess(
          navigateTo: answered
              ? RoutePaths.home.path
              : RoutePaths.languageLevel.path,
        ),
      );
    } on Exception catch (e) {
      emit(WelcomeError(message: e.toString()));
    }
  }

  Future<void> _onGuestTapped(
    WelcomeGuestTapped event,
    Emitter<WelcomeState> emit,
  ) async {
    emit(const WelcomeLoading());
    try {
      final authResponse = await _authRepository.login(
        providerType: AuthProviderType.guest,
        token: '',
      );
      _authBloc.add(AuthLoggedIn(authResponse));
      emit(WelcomeSuccess(navigateTo: RoutePaths.languageLevel.path));
    } on Exception catch (e) {
      emit(WelcomeError(message: e.toString()));
    }
  }
}
