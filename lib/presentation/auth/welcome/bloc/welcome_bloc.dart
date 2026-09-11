import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/domain/auth/auth_repository.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_bloc.dart';
import 'package:fastingapp/presentation/auth/welcome/bloc/welcome_event.dart';
import 'package:fastingapp/presentation/auth/welcome/bloc/welcome_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Karşılama / login: sosyal ve misafir girişi. (Doküman 17)
///
/// Uzun süren işler Future döner; loading [withLoading] ile view/mixin'de
/// gösterilir — BLoC içinde loading UI yok. (Doküman 9.6)
final class WelcomeBloc extends Bloc<WelcomeEvent, WelcomeState> {
  WelcomeBloc(this._authRepository, this._authBloc)
    : super(const WelcomeInitial()) {
    on<WelcomeGoogleTapped>(_onGoogleTapped);
    on<WelcomeAppleTapped>(_onAppleTapped);
    on<WelcomeGuestTapped>(_onGuestTapped);
  }

  // ignore: unused_field — gerçek API bağlanınca kullanılacak
  final AuthRepository _authRepository;
  // ignore: unused_field — gerçek API bağlanınca kullanılacak
  final AuthBloc _authBloc;

  /// Google ile giriş. Başarıda yönlenecek path döner.
  Future<String> loginWithGoogle() => _fakeLogin();

  /// Apple ile giriş. Başarıda yönlenecek path döner.
  Future<String> loginWithApple() => _fakeLogin();

  /// Misafir girişi. Başarıda yönlenecek path döner.
  Future<String> loginAsGuest() => _fakeLogin();

  /// UI geliştirme: ağ isteği yok, sadece withLoading'i göstermek için delay.
  /// TODO(team): AuthRepository.login + AuthLoggedIn ile değiştir.
  Future<String> _fakeLogin() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return RoutePaths.home.path;
  }

  Future<void> _onGoogleTapped(
    WelcomeGoogleTapped event,
    Emitter<WelcomeState> emit,
  ) async {
    try {
      final navigateTo = await loginWithGoogle();
      emit(WelcomeSuccess(navigateTo: navigateTo));
    } on Exception catch (e) {
      emit(WelcomeError(message: e.toString()));
    }
  }

  Future<void> _onAppleTapped(
    WelcomeAppleTapped event,
    Emitter<WelcomeState> emit,
  ) async {
    try {
      final navigateTo = await loginWithApple();
      emit(WelcomeSuccess(navigateTo: navigateTo));
    } on Exception catch (e) {
      emit(WelcomeError(message: e.toString()));
    }
  }

  Future<void> _onGuestTapped(
    WelcomeGuestTapped event,
    Emitter<WelcomeState> emit,
  ) async {
    try {
      final navigateTo = await loginAsGuest();
      emit(WelcomeSuccess(navigateTo: navigateTo));
    } on Exception catch (e) {
      emit(WelcomeError(message: e.toString()));
    }
  }
}
