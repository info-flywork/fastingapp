part of '../building_plan_view.dart';

mixin BuildingPlanViewMixin on State<BuildingPlanView> {
  OnboardingDraft get _draft => getIt<OnboardingDraft>();

  /// Animasyonla paralel: cevaplar sunucuya gider, plan ve projeksiyon gelir.
  Future<OnboardingResult>? _submission;

  void startSubmission() {
    _submission = getIt<OnboardingRepository>().submit()
      // Hata devam butonunda ele alınır; burada yakalanmazsa işlenmemiş
      // future hatası loglanır.
      ..ignore();
  }

  String _kg(double? v) => v == null
      ? '–'
      : NumberFormat('#.#', context.locale.toString()).format(v);

  List<String> get bodyChips => [
    if (_draft.gender != null)
      GenderOptionsCatalog.titleKeyFor(_draft.gender!).tr(),
    'onboarding.building_chip_weight'.tr(args: [_kg(_draft.weightKg)]),
    'onboarding.building_chip_height'.tr(args: ['${_draft.heightCm ?? '–'}']),
    'onboarding.building_chip_age'.tr(args: ['${_draft.age ?? '–'}']),
    'onboarding.building_chip_weight'.tr(args: [_kg(_draft.goalWeightKg)]),
  ];

  List<String> get lifestyleChips => [
    if (_draft.foodLoves.isNotEmpty)
      FoodLovesOptionsCatalog.titleKeyFor(_draft.foodLoves.first).tr(),
    if (_draft.foodSkips.isNotEmpty)
      FoodSkipsOptionsCatalog.titleKeyFor(_draft.foodSkips.first).tr(),
    if (_draft.plan != null)
      FastingPlanOptionsCatalog.titleKeyFor(_draft.plan!).tr(),
    if (_draft.weightHistory == OnboardingWeightHistory.firstTime)
      'onboarding.building_chip_first_if'.tr(),
    if (_draft.fastingReason == OnboardingFastingReason.specialDate)
      'onboarding.building_chip_special_target'.tr(),
  ];

  Future<void> onContinue() async {
    final submission = _submission ??= getIt<OnboardingRepository>().submit();
    try {
      final result = await submission.withLoading(context);
      getIt<AuthBloc>().add(AuthUserUpdated(result.user));
      if (!mounted) return;
      await context.push(
        RoutePaths.weightProjection.path,
        extra: result.projection,
      );
    } on Exception catch (e) {
      // Tekrar denenebilsin: başarısız gönderim saklanmaz.
      _submission = null;
      if (!mounted) return;
      AppSnackbar.show(
        context: context,
        text: e is NetworkException ? e.message : e.toString(),
        type: SnackBarType.failure,
      );
    }
  }
}
