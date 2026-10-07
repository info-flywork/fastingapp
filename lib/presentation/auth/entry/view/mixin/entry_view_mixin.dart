part of '../entry_view.dart';

mixin EntryViewMixin on State<EntryView> {
  /// Onboarding başı: cevaplar sıfırlanır, misafir oturumu arka planda açılır
  /// (backend doküman 13 §2 #3). Açılamazsa gönderimde tekrar denenir.
  void onGetStarted() {
    getIt<OnboardingDraft>().reset();
    final onboarding = getIt<OnboardingRepository>()..lastResult = null;
    unawaited(onboarding.ensureSession().catchError((Object _) {}));
    context.go(RoutePaths.onboarding.path);
  }

  void onAlreadyHaveAccount() {
    context.go(RoutePaths.login.path);
  }
}
