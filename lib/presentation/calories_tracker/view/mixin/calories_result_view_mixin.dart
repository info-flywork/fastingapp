part of '../calories_result_view.dart';

mixin CaloriesResultViewMixin on State<CaloriesResultView> {
  PhotoAnalysisResult? analysis;
  String? errorMessage;
  bool saving = false;
  bool _upgradeOffered = false;

  MealsRepository get _meals => getIt<MealsRepository>();

  @override
  void initState() {
    super.initState();
    if (widget.photoPath.isNotEmpty) {
      unawaited(_runAnalysis());
    }
  }

  Future<void> _runAnalysis() async {
    try {
      final result = await _meals.analyzePhoto(widget.photoPath);
      if (!mounted) return;
      setState(() {
        analysis = result;
        errorMessage = result.succeeded
            ? null
            : 'calories_result.recalculate'.tr();
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = e.message);
      await _offerUpgrade(e);
    } on Object {
      if (!mounted) return;
      setState(() => errorMessage = 'calories_camera.capture_failed'.tr());
    }
  }

  /// Günlük fotoğraf kotası doldu ve premium'da artar → paywall; satın
  /// alındıysa analiz tekrar denenir.
  Future<void> _offerUpgrade(NetworkException e) async {
    if (_upgradeOffered || !RevenueCatService.needsUpgrade(e)) return;
    _upgradeOffered = true;
    final premium = await getIt<RevenueCatService>().presentPaywall();
    if (!premium || !mounted) return;
    setState(() => errorMessage = null);
    await _runAnalysis();
  }

  Future<void> onSaveMeal() async {
    final a = analysis;
    if (a == null || !a.succeeded || saving) return;
    setState(() => saving = true);
    try {
      await _meals.createMealFromAnalysis(
        analysisId: a.id,
        title: a.mealTitle,
        kcal: a.kcal,
        proteinG: a.proteinG,
        carbsG: a.carbsG,
        fatG: a.fatG,
      );
      if (!mounted) return;
      DataSync.afterWrite();
      context.pop(true);
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = e.message);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
