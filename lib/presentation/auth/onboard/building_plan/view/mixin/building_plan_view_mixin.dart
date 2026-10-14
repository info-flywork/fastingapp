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
      // Gönderim çoğunlukla animasyon sırasında biter: dialog yanıp sönmesin.
      final result = await submission.withLoading(
        context,
        showAfter: const Duration(milliseconds: 300),
      );
      getIt<AuthBloc>().add(AuthUserUpdated(result.user));
      if (!mounted) return;
      await context.push(
        RoutePaths.weightProjection.path,
        extra: result.projection,
      );
    } on AccountPendingDeletionException<AuthResponse> catch (e) {
      _submission = null;
      if (!mounted) return;
      await _onPendingDeletion(e);
    } on Exception catch (e) {
      // Tekrar denenebilsin: başarısız gönderim saklanmaz.
      _submission = null;
      if (!mounted) return;
      AppSnackbar.show(
        context: context,
        text: errorMessageOf(e),
        type: SnackBarType.failure,
      );
    }
  }

  /// Bu cihazın misafir hesabı silinmek üzere: geri al (cevaplar o hesaba
  /// yazılır) ya da yeni misafirle devam. Önceden sabit "Hesap silinmek
  /// üzere" hatasında kalınıyordu.
  Future<void> _onPendingDeletion(
    AccountPendingDeletionException<AuthResponse> pending,
  ) async {
    final restore = await AppDialogs.instance.showRestoreAccount(
      context,
      scheduledFor: pending.scheduledFor,
    );
    if (!mounted || restore == null) return;
    try {
      await (restore
              ? pending.restore()
              : getIt<AuthRepository>().loginAsNewGuest())
          .withLoading(context);
    } on Exception catch (e) {
      if (!mounted) return;
      AppSnackbar.show(
        context: context,
        text: errorMessageOf(e),
        type: SnackBarType.failure,
      );
      return;
    }
    if (mounted) await onContinue();
  }
}
