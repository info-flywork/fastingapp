import 'dart:async';

import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/data/model/auth/auth_response.dart';
import 'package:fastingapp/domain/auth/auth_exception.dart';
import 'package:fastingapp/domain/auth/auth_repository.dart';
import 'package:fastingapp/domain/notification/push_service.dart';
import 'package:fastingapp/domain/onboarding/onboarding_draft.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_bloc.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_event.dart';
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

  final AuthRepository _authRepository;
  final AuthBloc _authBloc;

  /// Google ile giriş. Başarıda yönlenecek path döner.
  Future<String> loginWithGoogle() =>
      _complete(_authRepository.loginWithGoogle());

  /// Apple ile giriş. Başarıda yönlenecek path döner.
  Future<String> loginWithApple() =>
      _complete(_authRepository.loginWithApple());

  /// Misafir girişi. Başarıda yönlenecek path döner.
  Future<String> loginAsGuest() => _complete(_authRepository.loginAsGuest());

  /// Silme talebi bekleyen hesabı geri açıp girişi tamamlar.
  Future<String> restoreAccount(
    AccountPendingDeletionException<AuthResponse> pending,
  ) => _complete(pending.restore());

  Future<void> _requestPushPermission() async {
    try {
      await getIt<PushService>().requestPermission();
      await _authRepository.registerDevice();
    } on Object {
      // İzin / kayıt sonra yine denenir (açılışta cihaz kaydı).
    }
  }

  /// Geri almayı reddetti: Firebase/Google oturumu da kapanır.
  Future<void> discardPendingLogin() => _authRepository.discardSocialSignIn();

  /// Onboarding'i bitmiş hesap ana sayfaya; bitmemiş (ör. çıkış sonrası
  /// açılan yeni misafir) onboarding'e, cevaplar baştan (splash'teki kural).
  Future<String> _complete(Future<AuthResponse> login) async {
    final response = await login;
    _authBloc.add(AuthLoggedIn(response));
    if (response.user?.isAnsweredQuestions ?? false) {
      // Onboarding'i olan hesapla (ör. yeni cihaz) giriş: izin onboarding
      // sonunda isteniyordu, bu yolda hiç istenmiyordu. Sistem diyaloğu
      // yalnızca ilk seferde çıkar; sonuç cihaz kaydıyla sunucuya gider.
      unawaited(_requestPushPermission());
      return RoutePaths.home.path;
    }
    getIt<OnboardingDraft>().reset();
    return RoutePaths.onboarding.path;
  }

  Future<void> _onGoogleTapped(
    WelcomeGoogleTapped event,
    Emitter<WelcomeState> emit,
  ) async {
    try {
      final navigateTo = await loginWithGoogle();
      emit(WelcomeSuccess(navigateTo: navigateTo));
    } on Exception catch (e) {
      emit(WelcomeError(message: errorMessageOf(e)));
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
      emit(WelcomeError(message: errorMessageOf(e)));
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
      emit(WelcomeError(message: errorMessageOf(e)));
    }
  }
}
