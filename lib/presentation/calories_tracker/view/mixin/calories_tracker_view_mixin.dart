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

  /// Sunucudaki gün; üstüne onaylanmamış elle kalori / hedef biner.
  int _dayKcal = 0;
  int? _dayGoal;

  /// Kaydı süren elle kaloriler ve hedef: anında görünür, yoldaki eski gün
  /// cevabı geri alamaz. Onay + taze gün gelince kalkar.
  int _pendingKcal = 0;
  int? _pendingGoal;

  int get eatenKcal => _dayKcal + _pendingKcal;

  /// Günlük hedef; yeme bozukluğu geçmişinde sunucu null döner (hedef ve
  /// "fazla" hiç gösterilmez).
  int? get kcalGoal => _dayGoal == null ? null : _pendingGoal ?? _dayGoal;
  int burnedKcal = 0;
  int manualKcal = 0;

  double carbsG = 0;
  double proteinG = 0;
  double fatG = 0;
  double carbsProgress = 0;
  double proteinProgress = 0;
  double fatProgress = 0;

  /// Kilo: [WeightStore] (kilo ekranı / ana sayfa ile aynı değer), yoksa
  /// ana sayfa özeti.
  WeightStore get _weight => getIt<WeightStore>();

  ({double? start, double? goal, double? current}) get _homeWeight {
    final home = getIt<HomeBloc>().state;
    final s = home is HomeLoaded ? home.summary : null;
    return (
      start: s?.weightStartKg,
      goal: s?.weightGoalKg,
      current: s?.weightCurrentKg,
    );
  }

  double? get startKg => _weight.summary?.startKg ?? _homeWeight.start;

  double? get goalKg => _weight.goalKg ?? _homeWeight.goal;

  double get weightProgress => weightProgressOf(
    start: startKg,
    goal: goalKg,
    current: _weight.currentKg ?? _homeWeight.current,
  );

  /// Yeni yükleme başlayınca artar: eski yüklemenin cevabı yenisini ezmesin.
  int _loadGen = 0;

  @override
  void initState() {
    super.initState();
    _seedLocal();
    _weight.addListener(_onWeightChanged);
    // Cache varsa anında göster; ağ tazelemesi sessiz (spinner yok).
    unawaited(loadDay());
  }

  @override
  void dispose() {
    _weight.removeListener(_onWeightChanged);
    super.dispose();
  }

  void _onWeightChanged() {
    if (mounted) setState(() {});
  }

  void _seedLocal() {
    final cached = _nutrition.cachedDay();
    if (cached != null) {
      _applyDay(cached);
      hasContent = true;
    }
  }

  void _applyDay(NutritionDay day) {
    _dayKcal = day.kcal;
    _dayGoal = day.kcalGoal;
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

    final gen = ++_loadGen;
    final seqAtStart = _nutrition.writeSeq;
    try {
      final day = await _nutrition.getDay(force: force);
      // Protein tracker açılınca week beklemesin.
      unawaited(_nutrition.getWeek());
      if (!mounted || gen != _loadGen) return;
      // İstek sürerken bir yazma oldu: cevap eski; yazmanın tetiklediği
      // yükleme doğru değeri getirecek.
      if (seqAtStart != _nutrition.writeSeq && hasContent) return;
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

  /// Elle kalori → `POST /meals` (`quickKcal`). Anında eklenmiş görünür;
  /// kaydedilemezse geri alınır.
  Future<void> onManualAdd() async {
    final kcal = manualKcal;
    if (kcal <= 0 || savingManual) return;
    setState(() {
      savingManual = true;
      _pendingKcal += kcal;
      manualKcal = 0;
    });
    try {
      final result = await getIt<MealsRepository>().createQuickKcal(kcal: kcal);
      if (!mounted) return;
      // Oruç sürerken yenen kalori: "orucu bitir?" (elle öğün kaydıyla aynı).
      if (result.suggestEndFast) {
        final choice = await AppDialogs.instance.showEndFast(context);
        if (choice == false) {
          final id = result.meal?.id;
          if (id != null && id.isNotEmpty) {
            await getIt<MealsRepository>().deleteMeal(id);
          }
          DataSync.afterWrite();
          await _confirm(() => _pendingKcal -= kcal);
          return;
        }
        if (!mounted) return;
        if (choice ?? false) {
          DataSync.afterWrite();
          await _confirm(() => _pendingKcal -= kcal);
          await FastingFinishFlow.open();
          if (mounted) await loadDay();
          return;
        }
      }
      DataSync.afterWrite();
      await _confirm(() => _pendingKcal -= kcal);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _pendingKcal -= kcal;
        manualKcal = kcal;
      });
      AppSnackbar.showError(context, e);
    } finally {
      if (mounted) setState(() => savingManual = false);
    }
  }

  /// Yazma onaylandı: taze gün yüklenir, sonra iyimser değer kalkar (arada
  /// eski değere düşüp zıplamasın).
  Future<void> _confirm(void Function() clearPending) async {
    await loadDay();
    if (mounted) setState(clearPending);
  }

  /// Günlük kalori hedefi (800–5000, `PATCH /user/goals {kcalGoal}`).
  /// Anında görünür; kaydedilemezse eski hedefe döner.
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
    setState(() => _pendingGoal = value);
    try {
      await getIt<TrackersRepository>().updateGoals({'kcalGoal': value});
      DataSync.afterWrite();
      await _confirm(() {
        if (_pendingGoal == value) _pendingGoal = null;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        if (_pendingGoal == value) _pendingGoal = null;
      });
      AppSnackbar.showError(context, e);
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
