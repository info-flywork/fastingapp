import 'dart:async';

import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/router/app_router.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_bloc.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_state.dart';

/// Push / widget derin bağlantısı açılmadan önce: oturum açık, onboarding
/// bitmiş ve router splash'ten çıkmış olmalı. Soğuk açılışta splash'in
/// `go(home)`'u bağlantıyı eziyordu (widget → Su yerine Home);
/// onboarding'i bitmemiş kullanıcıda korumalı ekran açılıyordu.
abstract final class DeepLinkGate {
  static Future<bool> ready() async {
    final bloc = getIt<AuthBloc>();
    final auth = bloc.state is! AuthInitial
        ? bloc.state
        : await bloc.stream
              .firstWhere((s) => s is! AuthInitial)
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () => const AuthUnauthenticated(),
              );
    if (auth is! AuthAuthenticated || !auth.user.isAnsweredQuestions) {
      return false;
    }
    return _leftSplash();
  }

  /// Router splash'ten çıkınca true (15 sn içinde çıkmazsa false).
  static Future<bool> _leftSplash() async {
    String location() => appRouter.routerDelegate.currentConfiguration.uri.path;
    bool landed() {
      final path = location();
      // Router henüz ilk konfigürasyonu kurmadıysa yol boştur.
      return path.isNotEmpty && path != RoutePaths.splash.path;
    }

    if (landed()) return true;
    final done = Completer<bool>();
    void listener() {
      if (landed() && !done.isCompleted) done.complete(true);
    }

    appRouter.routerDelegate.addListener(listener);
    try {
      return await done.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => false,
      );
    } finally {
      appRouter.routerDelegate.removeListener(listener);
    }
  }
}
