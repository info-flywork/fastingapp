part of '../steps_view.dart';

/// Steps ekranı state / animasyon yardımcıları.
mixin StepsViewMixin on State<StepsView>, TickerProvider {
  static const addStepAmount = 500;
  static const progressDurationMs = 420;

  TrackersRepository get _trackers => getIt<TrackersRepository>();

  late int currentSteps;
  late int dailyGoalSteps;
  late DateTime selectedDate;
  int caloriesKcal = 0;
  String distanceKm = '0.0';
  int durationMin = 0;

  /// Son sunucu gününden adım başına pay. Elle ekle/çıkar bunu kullanır.
  double? _kcalPerStep;
  double? _kmPerStep;
  double? _minPerStep;

  /// Pazartesi→Pazar; seçili günün hafta index'i.
  late List<int> weeklySteps;
  late int todayWeekIndex;

  late AnimationController progressController;
  Animation<double> progressAnimation = const AlwaysStoppedAnimation(0);

  /// Gün geçiş yönü: +1 sonraki, -1 önceki (animasyon için).
  int dayNavDirection = 1;
  int _stepsLoadGen = 0;

  /// +/- veya gün değişince artar. O sırada yolda olan eski GET/PUT
  /// cevabı ekrandaki sayıyı geri almasın.
  int _editGen = 0;

  static const _minHistoryYears = 2;

  double get progress =>
      dailyGoalSteps <= 0 ? 0 : (currentSteps / dailyGoalSteps).clamp(0.0, 1.0);

  bool get goalReached => currentSteps >= dailyGoalSteps;

  DateTime get _today => DateUtils.dateOnly(DateTime.now());

  DateTime get _earliestStepsDay =>
      DateTime(_today.year - _minHistoryYears, _today.month, _today.day);

  bool get canGoNextStepsDay => selectedDate.isBefore(_today);

  bool get canGoPrevStepsDay => selectedDate.isAfter(_earliestStepsDay);

  bool get isStepsToday => DateUtils.isSameDay(selectedDate, _today);

  /// Seçili gün sağlık uygulamasından: +/− gizlenir (sunucu elle yazmayı
  /// 409 ile reddediyordu).
  bool selectedDayHealthSynced = false;

  bool get canEditSteps => isStepsToday && !selectedDayHealthSynced;

  void initStepsControllers() {
    currentSteps = widget.initialSteps;
    dailyGoalSteps = widget.dailyGoalSteps;
    selectedDate = _today;
    todayWeekIndex = (selectedDate.weekday - 1).clamp(0, 6);
    weeklySteps = List<int>.filled(7, 0);
    weeklySteps[todayWeekIndex] = currentSteps;

    progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: progressDurationMs),
    );
    // Sayı ana sayfadaki adımla açılır; çember de aynı payda dolu gelsin.
    // Ağ cevabı farklıysa oradan animasyonla kayar.
    final seeded = progress;
    animateProgressTo(seeded, from: seeded);
    progressController.value = 1;
    unawaited(_syncThenLoad());
  }

  Future<void> _syncThenLoad() async {
    await getIt<HealthSyncService>().sync();
    await loadStepsWeek();
  }

  String stepsDateLabel(BuildContext context) {
    final today = _today;
    if (DateUtils.isSameDay(selectedDate, today)) {
      return 'steps_page.today'.tr();
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (DateUtils.isSameDay(selectedDate, yesterday)) {
      return 'steps_page.yesterday'.tr();
    }
    return DateFormat.MMMd(context.locale.toString()).format(selectedDate);
  }

  Future<void> loadStepsWeek() async {
    final gen = ++_stepsLoadGen;
    final editAtStart = _editGen;
    final date = selectedDate;
    try {
      final range = await _trackers.getSteps(range: 'week', date: date);
      if (!mounted || gen != _stepsLoadGen) return;
      if (!DateUtils.isSameDay(date, selectedDate)) return;
      _applyStepsRange(range, keepFocusDay: editAtStart != _editGen);
    } on Object {
      // initialSteps / widget yedeği
    }
  }

  void _applyStepsRange(StepsRange range, {bool keepFocusDay = false}) {
    final focus = DateUtils.dateOnly(selectedDate);
    final heldSteps = currentSteps;
    final heldKcal = caloriesKcal;
    final heldKm = distanceKm;
    final heldMin = durationMin;
    setState(() {
      dailyGoalSteps = range.goal;
      weeklySteps = List<int>.filled(7, 0);
      if (!keepFocusDay) {
        currentSteps = 0;
        selectedDayHealthSynced = false;
        caloriesKcal = 0;
        distanceKm = '0.0';
        durationMin = 0;
      }
      todayWeekIndex = (focus.weekday - 1).clamp(0, 6);
      for (final day in range.days) {
        final d = DateUtils.dateOnly(day.date);
        final idx = (d.weekday - 1).clamp(0, 6);
        weeklySteps[idx] = day.steps;
        if (!DateUtils.isSameDay(d, focus)) continue;
        todayWeekIndex = idx;
        _rememberRates(
          steps: day.steps,
          kcal: day.kcal,
          km: day.distanceKm,
          minutes: day.durationMin,
        );
        if (keepFocusDay) continue;
        currentSteps = day.steps;
        selectedDayHealthSynced = day.isHealthSynced;
        caloriesKcal = day.kcal;
        distanceKm = day.distanceKm.toStringAsFixed(1);
        durationMin = day.durationMin;
      }
      if (keepFocusDay) {
        currentSteps = heldSteps;
        caloriesKcal = heldKcal;
        distanceKm = heldKm;
        durationMin = heldMin;
        weeklySteps[todayWeekIndex] = heldSteps;
      }
    });
    if (!keepFocusDay) unawaited(runProgressAnimation(progress));
  }

  Future<void> onStepsDateTapped() async {
    final result = await AppDialogs.instance.showMealDatePicker(
      context,
      initialDate: selectedDate,
      accentColor: ColorName.colorStepsAction,
    );
    if (result == null || !mounted) return;
    await _selectStepsDate(DateUtils.dateOnly(result.date));
  }

  Future<void> onStepsPrevDay() {
    if (!canGoPrevStepsDay) return Future<void>.value();
    return _shiftStepsDate(-1);
  }

  Future<void> onStepsNextDay() {
    if (!canGoNextStepsDay) return Future<void>.value();
    return _shiftStepsDate(1);
  }

  Future<void> _shiftStepsDate(int dayDelta) {
    final next = DateUtils.dateOnly(selectedDate.add(Duration(days: dayDelta)));
    return _selectStepsDate(next);
  }

  Future<void> _selectStepsDate(DateTime date) async {
    final next = DateUtils.dateOnly(date);
    var clamped = next.isAfter(_today) ? _today : next;
    if (clamped.isBefore(_earliestStepsDay)) clamped = _earliestStepsDay;
    if (DateUtils.isSameDay(clamped, selectedDate)) return;
    // Bekleyen kayıt önce gönderilir (değer kendi gününe yazılır, kaybolmaz).
    // Eski günün yoldaki cevabı yeni güne yazılmasın.
    _editGen++;
    _flushPendingSteps();

    final direction = clamped.isAfter(selectedDate) ? 1 : -1;
    setState(() {
      dayNavDirection = direction;
      selectedDate = clamped;
    });
    HapticFeedback.selectionClick();
    await loadStepsWeek();
  }

  Timer? _persistTimer;
  ({DateTime date, int steps})? _pending;

  /// Art arda +/- dokunuşları tek PUT'a katlanır (yarışan istekler son
  /// değeri ezmesin). Tarih ve değer dokunuş anında yakalanır.
  void _schedulePersist() {
    _pending = (date: selectedDate, steps: currentSteps);
    _persistTimer?.cancel();
    _persistTimer = Timer(
      const Duration(milliseconds: 600),
      () => unawaited(_persistPending()),
    );
  }

  void _flushPendingSteps() {
    if (!(_persistTimer?.isActive ?? false)) return;
    _persistTimer!.cancel();
    unawaited(_persistPending());
  }

  /// `PUT /steps/:date` yalnızca o günü döner: haftalık grafik ezilmez; o
  /// günün kcal / km / dakika değerleri yanıttan güncellenir. Hata olursa
  /// sunucudan yeniden yüklenir.
  Future<void> _persistPending() async {
    final pending = _pending;
    _pending = null;
    _persistTimer = null;
    if (pending == null) return;
    final editAtStart = _editGen;
    try {
      final range = await _trackers.putSteps(
        date: pending.date,
        steps: pending.steps,
      );
      DataSync.afterWrite();
      if (!mounted || !DateUtils.isSameDay(pending.date, selectedDate)) return;
      if (editAtStart != _editGen || currentSteps != pending.steps) return;
      for (final day in range.days) {
        if (!DateUtils.isSameDay(day.date, pending.date)) continue;
        setState(() {
          caloriesKcal = day.kcal;
          distanceKm = day.distanceKm.toStringAsFixed(1);
          durationMin = day.durationMin;
          _rememberRates(
            steps: day.steps,
            kcal: day.kcal,
            km: day.distanceKm,
            minutes: day.durationMin,
          );
        });
      }
    } on Object catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, e);
      await loadStepsWeek();
    }
  }

  void disposeStepsControllers() {
    // Bekleyen kayıt kaybolmasın (ekran kapanırken sessizce gönderilir).
    final pending = _pending;
    if ((_persistTimer?.isActive ?? false) && pending != null) {
      _persistTimer!.cancel();
      unawaited(
        _trackers
            .putSteps(date: pending.date, steps: pending.steps)
            .then((_) => DataSync.afterWrite())
            .catchError((Object _) {}),
      );
    }
    progressController.dispose();
  }

  void animateProgressTo(double to, {required double from}) {
    progressAnimation = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: progressController, curve: Curves.easeOut),
    );
  }

  Future<void> runProgressAnimation(double target) async {
    final from = progressAnimation.value;
    // Önce yeni aralık kurulur. reset() eski aralığın başına düşürüp
    // çemberi bir kare geri alıyordu.
    animateProgressTo(target, from: from);
    progressController.value = 0;
    await progressController.forward();
  }

  void _syncSelectedBar() {
    weeklySteps[todayWeekIndex] = currentSteps;
  }

  void _rememberRates({
    required int steps,
    required int kcal,
    required double km,
    required int minutes,
  }) {
    if (steps <= 0) return;
    _kcalPerStep = kcal / steps;
    _kmPerStep = km / steps;
    _minPerStep = minutes / steps;
  }

  /// Sunucu formülü: kcal ve km kilo/boya göre, süre 100 adım/dk.
  /// Oran bilinince son yanıttaki pay kullanılır.
  void _applyDerivedMetrics() {
    final steps = currentSteps;
    if (steps <= 0) {
      caloriesKcal = 0;
      distanceKm = '0.0';
      durationMin = 0;
      return;
    }
    final kg = _weightKg();
    caloriesKcal = (steps * (_kcalPerStep ?? 0.04 * (kg / 70))).round();
    distanceKm = (steps * (_kmPerStep ?? 0.70 / 1000)).toStringAsFixed(1);
    durationMin = (steps * (_minPerStep ?? 0.01)).round();
  }

  double _weightKg() {
    final home = getIt<HomeBloc>().state;
    if (home is HomeLoaded) {
      final kg = home.summary?.weightCurrentKg;
      if (kg != null && kg > 0) return kg;
    }
    return 70;
  }

  Future<void> addSteps() async {
    if (!canEditSteps) return;
    _editGen++;
    setState(() {
      currentSteps = (currentSteps + addStepAmount).clamp(0, 99999);
      _syncSelectedBar();
      _applyDerivedMetrics();
    });
    getIt<HomeBloc>().add(HomeMetricsOptimistic(steps: currentSteps));
    unawaited(runProgressAnimation(progress));
    _schedulePersist();
  }

  Future<void> removeSteps() async {
    if (!canEditSteps) return;
    if (currentSteps <= 0) return;
    _editGen++;
    setState(() {
      currentSteps = (currentSteps - addStepAmount).clamp(0, 99999);
      _syncSelectedBar();
      _applyDerivedMetrics();
    });
    getIt<HomeBloc>().add(HomeMetricsOptimistic(steps: currentSteps));
    unawaited(runProgressAnimation(progress));
    _schedulePersist();
  }

  /// Günlük adım hedefi (1.000–50.000): `PATCH /user/goals {stepsGoal}`.
  /// Önceden hedef değiştirilemiyordu.
  Future<void> editStepsGoal() async {
    final goal = await AppDialogs.instance.showGoalStepper(
      context,
      title: 'steps_page.goal_title'.tr(),
      initial: dailyGoalSteps,
      min: 1000,
      max: 50000,
      step: 500,
      format: (v) => '$v',
    );
    if (goal == null || goal == dailyGoalSteps || !mounted) return;
    final previous = dailyGoalSteps;
    setState(() => dailyGoalSteps = goal);
    unawaited(runProgressAnimation(progress));
    try {
      await _trackers.updateGoals({'stepsGoal': goal});
      DataSync.afterWrite();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => dailyGoalSteps = previous);
      AppSnackbar.showError(context, e);
    }
  }
}
