part of '../calories_tracker_view.dart';

mixin CaloriesTrackerViewMixin on State<CaloriesTrackerView> {
  static const _manualStep = 50;
  static const _manualMin = 0;
  static const _manualMax = 5000;

  final _nutrition = getIt<NutritionRepository>();

  /// İlk açılışta cache yoksa shimmer; cache varsa asla full-page loading yok.
  bool showShimmer = false;
  bool hasContent = false;
  String? errorMessage;

  int eatenKcal = 0;

  /// Günlük hedef; yeme bozukluğu geçmişinde sunucu null döner (hedef ve
  /// "fazla" hiç gösterilmez).
  int? kcalGoal;
  int burnedKcal = 0;
  int manualKcal = 0;

  double carbsG = 0;
  double proteinG = 0;
  double fatG = 0;
  double carbsProgress = 0;
  double proteinProgress = 0;
  double fatProgress = 0;

  double? startKg;
  double? goalKg;
  double weightProgress = 0;

  @override
  void initState() {
    super.initState();
    _seedLocal();
    // Cache varsa anında göster; ağ tazelemesi sessiz (spinner yok).
    unawaited(loadDay());
  }

  void _seedLocal() {
    final cached = _nutrition.cachedDay();
    if (cached != null) {
      _applyDay(cached);
      hasContent = true;
    }
    _seedWeightFromHome();
  }

  void _seedWeightFromHome() {
    final home = getIt<HomeBloc>().state;
    if (home is! HomeLoaded) return;
    final s = home.summary;
    final start = s?.weightStartKg;
    final goal = s?.weightGoalKg;
    final current = s?.weightCurrentKg;
    final wProgress = weightProgressOf(
      start: start,
      goal: goal,
      current: current,
    );
    startKg = start ?? startKg;
    goalKg = goal ?? goalKg;
    weightProgress = wProgress;
  }

  void _applyDay(NutritionDay day) {
    eatenKcal = day.kcal;
    kcalGoal = day.kcalGoal;
    burnedKcal = day.burnedKcal;
    carbsG = day.macros.carbs.g;
    proteinG = day.macros.protein.g;
    fatG = day.macros.fat.g;
    carbsProgress = day.macros.carbs.progressOrZero;
    proteinProgress = day.macros.protein.progressOrZero;
    fatProgress = day.macros.fat.progressOrZero;
  }

  Future<void> loadDay({bool force = true}) async {
    final needShimmer = !hasContent;
    if (needShimmer && mounted) {
      setState(() {
        showShimmer = true;
        errorMessage = null;
      });
    } else if (mounted) {
      setState(() => errorMessage = null);
    }

    try {
      final day = await _nutrition.getDay(force: force);
      // Protein tracker açılınca week beklemesin.
      unawaited(_nutrition.getWeek());
      if (!mounted) return;
      _seedWeightFromHome();
      setState(() {
        _applyDay(day);
        hasContent = true;
        showShimmer = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        showShimmer = false;
        errorMessage = e.message;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        showShimmer = false;
        errorMessage = errorMessageOf(e);
      });
    }
  }

  void onManualDecrement() {
    if (manualKcal <= _manualMin) return;
    setState(() {
      manualKcal = (manualKcal - _manualStep).clamp(_manualMin, _manualMax);
    });
  }

  void onManualIncrement() {
    if (manualKcal >= _manualMax) return;
    setState(() {
      manualKcal = (manualKcal + _manualStep).clamp(_manualMin, _manualMax);
    });
  }

  bool savingManual = false;

  /// Elle kalori → `POST /meals` (`quickKcal`); önceden yalnızca ekranda
  /// kalıyordu.
  Future<void> onManualAdd() async {
    if (manualKcal <= 0 || savingManual) return;
    setState(() => savingManual = true);
    try {
      final result = await getIt<MealsRepository>().createQuickKcal(
        kcal: manualKcal,
      );
      if (!mounted) return;
      // Oruç sürerken yenen kalori: "orucu bitir?" (elle öğün kaydıyla aynı).
      if (result.suggestEndFast) {
        final choice = await AppDialogs.instance.showEndFast(context);
        if (choice == false) {
          final id = result.meal?.id;
          if (id != null && id.isNotEmpty) {
            await getIt<MealsRepository>().deleteMeal(id);
          }
          return;
        }
        if (!mounted) return;
        if (choice ?? false) {
          DataSync.afterWrite();
          setState(() => manualKcal = 0);
          await FastingFinishFlow.open();
          if (mounted) await loadDay();
          return;
        }
      }
      DataSync.afterWrite();
      setState(() => manualKcal = 0);
      if (mounted) await loadDay();
    } on Object catch (e) {
      if (mounted) AppSnackbar.showError(context, e);
    } finally {
      if (mounted) setState(() => savingManual = false);
    }
  }

  /// Günlük kalori hedefi (800–5000, `PATCH /user/goals {kcalGoal}`).
  Future<void> onEditKcalGoal() async {
    final current = kcalGoal;
    if (current == null) return;
    final value = await AppDialogs.instance.showGoalStepper(
      context,
      title: 'calories_page.goal_title'.tr(),
      initial: current,
      min: 800,
      max: 5000,
      step: 50,
      format: (v) => '$v kcal',
    );
    if (value == null || value == current || !mounted) return;
    try {
      await getIt<TrackersRepository>().updateGoals({'kcalGoal': value});
      DataSync.afterWrite();
      if (mounted) await loadDay();
    } on Object catch (e) {
      if (mounted) AppSnackbar.showError(context, e);
    }
  }

  /// Protein ekranından öğün eklenebilir: dönünce tazele.
  Future<void> onProteinTracker() async {
    await context.pushNamed(RoutePaths.proteinTracker.name);
    if (mounted) await loadDay();
  }

  /// Kamera → analiz → kayıt; dönünce sessiz taze (spinner yok).
  Future<void> onCalculate() async {
    await context.pushNamed(RoutePaths.caloriesCamera.name);
    if (mounted) await loadDay();
  }
}
