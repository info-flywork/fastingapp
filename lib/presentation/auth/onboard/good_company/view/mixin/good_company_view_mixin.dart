part of '../good_company_view.dart';

mixin GoodCompanyViewMixin on State<GoodCompanyView> {
  Future<void> onContinue() async {
    // Onboarding misafir oturumu: /home korumalı rota, auth şart.
    const user = User(name: 'Squish', isAnsweredQuestions: true);
    const token = Token(
      accessToken: 'local-onboarding-session',
      refreshToken: 'local-onboarding-session',
    );
    final cache = getIt<AuthCacheManager>();
    await cache.saveToken(token);
    await cache.saveUser(user);
    getIt<AuthBloc>().add(
      const AuthLoggedIn(AuthResponse(token: token, user: user)),
    );
    if (!mounted) return;
    context.go(RoutePaths.home.path);
  }
}
