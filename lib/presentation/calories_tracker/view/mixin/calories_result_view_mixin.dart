part of '../calories_result_view.dart';

mixin CaloriesResultViewMixin on State<CaloriesResultView> {
  PhotoAnalysisResult? analysis;
  String? errorMessage;
  bool saving = false;
  bool _upgradeOffered = false;

  /// Süre dolduğunda sunucuda süren analiz; "Tekrar kontrol et" bunu
  /// yoklar (yeni fotoğraf / yeni hak gerekmez).
  String? pendingAnalysisId;

  MealsRepository get _meals => getIt<MealsRepository>();

  @override
  void initState() {
    super.initState();
    if (widget.photoPath.isNotEmpty) {
      unawaited(_runAnalysis());
    }
  }

  Future<void> _runAnalysis() async {
    if (!await AiConsent.ensure(context)) {
      if (mounted) context.pop();
      return;
    }
    if (!mounted) return;
    await _track(() => _meals.analyzePhoto(widget.photoPath));
  }

  /// Bekleyen analizi yeniden yokla.
  Future<void> onCheckAgain() async {
    final id = pendingAnalysisId;
    if (id == null) return;
    setState(() => errorMessage = null);
    await _track(() => _meals.pollAnalysis(id, 1500));
  }

  Future<void> _track(Future<PhotoAnalysisResult> Function() run) async {
    try {
      final result = await run();
      if (!mounted) return;
      setState(() {
        pendingAnalysisId = null;
        analysis = result;
        errorMessage = switch (result.status) {
          'succeeded' => null,
          'notFood' => 'calories_result.not_food'.tr(),
          _ => 'calories_result.analysis_failed'.tr(),
        };
      });
    } on PhotoAnalysisPending catch (e) {
      if (!mounted) return;
      setState(() {
        pendingAnalysisId = e.analysisId;
        errorMessage = 'calories_result.still_processing'.tr();
      });
    } on NetworkException catch (e) {
      AiConsent.onError(e);
      if (!mounted) return;
      setState(() => errorMessage = e.message);
      await _offerUpgrade(e);
    } on Object {
      if (!mounted) return;
      setState(() => errorMessage = 'calories_result.analysis_failed'.tr());
    }
  }

  /// Günlük fotoğraf kotası doldu ve premium'da artar → paywall; satın
  /// alındıysa analiz tekrar denenir.
  Future<void> _offerUpgrade(NetworkException e) async {
    if (_upgradeOffered || !RevenueCatService.needsUpgrade(e)) return;
    _upgradeOffered = true;
    final revenueCat = getIt<RevenueCatService>();
    if (!await revenueCat.presentPaywall() || !mounted) return;
    setState(() => errorMessage = null);
    await _track(
      () => revenueCat.retryAfterUpgrade(
        () => _meals.analyzePhoto(widget.photoPath),
      ),
    );
  }

  Future<void> onSaveMeal() async {
    final a = analysis;
    if (a == null || !a.succeeded || saving) return;
    setState(() => saving = true);
    try {
      final result = await _meals.createMealFromAnalysis(
        analysisId: a.id,
        title: a.mealTitle,
        kcal: a.kcal,
        proteinG: a.proteinG,
        carbsG: a.carbsG,
        fatG: a.fatG,
      );
      if (!mounted) return;
      // Oruç sürerken öğün: "orucu bitir?" (elle öğün kaydıyla aynı).
      var endFast = false;
      if (result.suggestEndFast) {
        final choice = await AppDialogs.instance.showEndFast(context);
        if (choice == false) {
          final id = result.meal?.id;
          if (id != null && id.isNotEmpty) await _meals.deleteMeal(id);
          return;
        }
        if (!mounted) return;
        endFast = choice ?? false;
      }
      DataSync.afterWrite();
      context.pop(true);
      if (endFast) await FastingFinishFlow.open();
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = e.message);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
