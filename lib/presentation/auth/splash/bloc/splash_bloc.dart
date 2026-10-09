import 'dart:async';

import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/domain/nutrition/nutrition_repository.dart';
import 'package:fastingapp/domain/trackers/trackers_repository.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_bloc.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_state.dart';
import 'package:fastingapp/presentation/auth/splash/bloc/splash_event.dart';
import 'package:fastingapp/presentation/auth/splash/bloc/splash_state.dart';
import 'package:fastingapp/presentation/home/bloc/home_bloc.dart';
import 'package:fastingapp/presentation/home/bloc/home_event.dart';
import 'package:fastingapp/presentation/home/bloc/home_state.dart';
import 'package:fastingapp/presentation/profile/bloc/profile_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Açılış yönlendirmesi: oturum varsa home, yoksa entry. (Doküman 17)
///
/// Home'a gidecekse [HomeBloc] özetini splash'te ısıtır; nutrition/su
/// cache'i arka planda dolar (sayfalar boş flash göstermesin diye).
final class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc(this._authBloc, this._homeBloc, this._profileBloc)
    : super(const SplashInitial()) {
    on<SplashStarted>(_onStarted);
  }

  final AuthBloc _authBloc;
  final HomeBloc _homeBloc;
  final ProfileBloc _profileBloc;

  static const _minVisible = Duration(milliseconds: 1400);
  static const _homeWarmupTimeout = Duration(seconds: 8);

  Future<void> _onStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    final authFuture = _waitForAuthResolved();
    final minDelay = Future<void>.delayed(_minVisible);
    final auth = await authFuture;

    final goHome = auth is AuthAuthenticated && auth.user.isAnsweredQuestions;

    // Auth netleşir netleşmez home ısıt; nutrition cache splash'i uzatmadan.
    final homeWarmup = goHome ? _warmupHome() : null;
    if (goHome) {
      _profileBloc.add(const ProfileStarted());
      unawaited(_warmupNutrition());
      unawaited(_warmupWater());
    }
    await minDelay;
    if (homeWarmup != null) await homeWarmup;

    emit(
      SplashNavigateTo(goHome ? RoutePaths.home.path : RoutePaths.entry.path),
    );
  }

  Future<void> _warmupHome() async {
    final current = _homeBloc.state;
    if (current is HomeLoaded) return;
    if (current is! HomeLoading) {
      _homeBloc.add(const HomeStarted());
    }
    try {
      await _homeBloc.stream
          .firstWhere((s) => s is HomeLoaded || s is HomeError)
          .timeout(_homeWarmupTimeout);
    } on Object {
      // Timeout / hata: home ekranı kendi loading/error akışına düşer.
    }
  }

  Future<void> _warmupNutrition() async {
    final nutrition = getIt<NutritionRepository>();
    try {
      await Future.wait([
        nutrition.getDay(),
        nutrition.getWeek(metric: 'protein'),
      ]);
    } on Object {
      // Kalori/protein sayfaları kendi shimmer/error akışına düşer.
    }
  }

  Future<void> _warmupWater() async {
    try {
      await getIt<TrackersRepository>().getWaterDay();
    } on Object {
      // Su sayfası home özeti / kendi yüklemesiyle açılır.
    }
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
