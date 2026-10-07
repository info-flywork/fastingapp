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
    if (!mounted) return;
    context.go(RoutePaths.login.path);
  }
}
