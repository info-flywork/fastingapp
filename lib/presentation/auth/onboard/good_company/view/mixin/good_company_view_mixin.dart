part of '../good_company_view.dart';

mixin GoodCompanyViewMixin on State<GoodCompanyView> {
  /// Cevaplar BuildingPlan'da gönderildi; gönderilemediyse burada tekrar
  /// denenir. Sonra giriş ekranı: Apple/Google misafir hesabı (verileriyle)
  /// yükseltir, "misafir olarak devam" aynı hesapla sürer.
  Future<void> onContinue() async {
    final onboarding = getIt<OnboardingRepository>();
    try {
      if (onboarding.lastResult == null) {
        final result = await onboarding.submit().withLoading(context);
        getIt<AuthBloc>().add(AuthUserUpdated(result.user));
      }
    } on Exception catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context: context,
        text: e is NetworkException ? e.message : e.toString(),
        type: SnackBarType.failure,
      );
      return;
    }
    // Bildirim izni: plan hazırken (hedef/yeme penceresi hatırlatmaları).
    // Yanıt ne olursa olsun cihaz kaydı izni/token'ı sunucuya bildirir.
    await getIt<PushService>().requestPermission().catchError(
      (Object _) => false,
    );
    unawaited(getIt<AuthRepository>().registerDevice());
    if (!mounted) return;
    context.go(RoutePaths.login.path);
  }
}
