import 'dart:async';

import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/data/model/auth/auth_response.dart';
import 'package:fastingapp/domain/auth/auth_exception.dart';
import 'package:fastingapp/domain/auth/auth_repository.dart';
import 'package:fastingapp/domain/notification/push_service.dart';
import 'package:fastingapp/domain/onboarding/onboarding_draft.dart';
import 'package:fastingapp/domain/onboarding/onboarding_repository.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_bloc.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_event.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_state.dart';
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
  /// [afterOnboarding]: onboarding sonundaki giriş (bkz. [_complete]).
  Future<String> loginWithGoogle({bool afterOnboarding = false}) => _complete(
    _authRepository.loginWithGoogle(),
    afterOnboarding: afterOnboarding,
  );

  /// Apple ile giriş. Başarıda yönlenecek path döner.
  Future<String> loginWithApple({bool afterOnboarding = false}) => _complete(
    _authRepository.loginWithApple(),
    afterOnboarding: afterOnboarding,
  );

  /// Onboarding sonunda "misafir olarak devam": oturum zaten misafir
  /// hesabında (cevaplar gönderildi). Oturum yoksa (ör. düşmüşse) açılır.
  Future<String> continueAsGuest() async {
    if (_authBloc.state is AuthAuthenticated) return RoutePaths.home.path;
    return _complete(_authRepository.loginAsGuest(), afterOnboarding: true);
  }

  /// Misafir girişi. Başarıda yönlenecek path döner.
  Future<String> loginAsGuest() => _complete(_authRepository.loginAsGuest());

  /// Silme talebi bekleyen hesabı geri açıp girişi tamamlar.
  Future<String> restoreAccount(
    AccountPendingDeletionException<AuthResponse> pending, {
    bool afterOnboarding = false,
  }) => _complete(pending.restore(), afterOnboarding: afterOnboarding);

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
  ///
  /// [afterOnboarding]: Apple/Google kimliği yeniyse sunucu misafir hesabı
  /// yükseltir (cevaplar, plan, kayıtlar aynen kalır). Kimlik başka bir
  /// hesaba bağlıysa o hesaba geçilir; o hesapta onboarding yoksa az önce
  /// verilen cevaplar ona gönderilir (onboarding baştan sorulmaz).
  Future<String> _complete(
    Future<AuthResponse> login, {
    bool afterOnboarding = false,
  }) async {
    var response = await login;
    final user = response.user;
    if (afterOnboarding && user != null && !user.isAnsweredQuestions) {
      // Token kaydedildi: gönderim yeni hesabın oturumuyla gider.
      final result = await getIt<OnboardingRepository>().submit();
      response = AuthResponse(
        token: response.token,
        user: result.user,
        guestSecret: response.guestSecret,
      );
    }
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
