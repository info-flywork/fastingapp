part of '../steps_view.dart';

/// Steps ekranı: görünen her değer [StepsStore]'dan okunur. Ekran kendi
/// kopyasını tutmaz; GET / PUT / özet yarışları sayıyı geri alamaz, gün
/// değişince başka günün değeri görünmez.
mixin StepsViewMixin on State<StepsView>, TickerProvider {
  static const addStepAmount = 500;
  static const progressDurationMs = 420;

  StepsStore get _store => getIt<StepsStore>();

  late DateTime selectedDate;

  late AnimationController progressController;
  Animation<double> progressAnimation = const AlwaysStoppedAnimation(0);

  /// Gün geçiş yönü: +1 sonraki, -1 önceki (animasyon için).
  int dayNavDirection = 1;

  StreamSubscription<Object>? _errors;
  double _shownProgress = 0;

  static const _minHistoryYears = 2;

  int get currentSteps => _store.stepsFor(selectedDate);

  int get dailyGoalSteps => _store.goalFor(selectedDate);

  bool get selectedDayHealthSynced => _store.isHealthSynced(selectedDate);

  double get progress =>
      dailyGoalSteps <= 0 ? 0 : (currentSteps / dailyGoalSteps).clamp(0.0, 1.0);

  bool get goalReached => currentSteps >= dailyGoalSteps;

  DateTime get _monday => StepsStore.mondayOf(selectedDate);

  /// Pazartesi→Pazar adımlar (seçili günün haftası).
  List<int> get weeklySteps => [
    for (var i = 0; i < 7; i++) _store.stepsFor(_monday.add(Duration(days: i))),
  ];

  int get todayWeekIndex => selectedDate.weekday - 1;

  /// Haftalık çubukların tavanı: haftadaki en yüksek hedef (gün değişince
  /// çubuklar zıplamasın).
  int get weekChartScale {
    var scale = dailyGoalSteps;
    for (var i = 0; i < 7; i++) {
      final goal = _store.goalFor(_monday.add(Duration(days: i)));
      if (goal > scale) scale = goal;
    }
    return scale;
  }

  /// O günün sunucu değerinden adım başına pay (yoksa kişisel formül).
  ({int kcal, String km, int minutes}) get _metrics {
    final steps = currentSteps;
    if (steps <= 0) return (kcal: 0, km: '0.0', minutes: 0);
    final day = _store.serverDay(selectedDate);
    if (day != null && day.steps > 0) {
      return (
        kcal: (steps * day.kcal / day.steps).round(),
        km: (steps * day.distanceKm / day.steps).toStringAsFixed(1),
        minutes: (steps * day.durationMin / day.steps).round(),
      );
    }
    final height = _heightCm();
    final stride = height == null ? 0.7 : height * 0.415 / 100;
    return (
      kcal: (steps * 0.04 * (_weightKg() / 70)).round(),
      km: ((steps * stride) / 1000).toStringAsFixed(1),
      minutes: (steps / 100).round(),
    );
  }

  int get caloriesKcal => _metrics.kcal;
  String get distanceKm => _metrics.km;
  int get durationMin => _metrics.minutes;

  DateTime get _today => DateUtils.dateOnly(DateTime.now());

  DateTime get _earliestStepsDay =>
      DateTime(_today.year - _minHistoryYears, _today.month, _today.day);

  bool get canGoNextStepsDay => selectedDate.isBefore(_today);

  bool get canGoPrevStepsDay => selectedDate.isAfter(_earliestStepsDay);

  bool get isStepsToday => DateUtils.isSameDay(selectedDate, _today);

  /// Elle yalnızca bugün ve sağlık uygulamasından gelmeyen günde girilir.
  bool get canEditSteps => isStepsToday && !selectedDayHealthSynced;

  void initStepsControllers() {
    selectedDate = _today;
    // Ana sayfa özetiyle tohumla: ekran 0 ile açılıp zıplamasın.
    _store
      ..seedToday(steps: widget.initialSteps, goal: widget.dailyGoalSteps)
      ..addListener(_onStoreChanged);
    _errors = _store.errors.stream.listen((e) {
      if (mounted) AppSnackbar.showError(context, e);
    });

    progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: progressDurationMs),
    );
    _shownProgress = progress;
    animateProgressTo(_shownProgress, from: _shownProgress);
    progressController.value = 1;
    unawaited(_syncThenLoad());
  }

  void _onStoreChanged() {
    if (!mounted) return;
    setState(() {});
    final target = progress;
    if ((target - _shownProgress).abs() > 0.0001) {
      _shownProgress = target;
      unawaited(runProgressAnimation(target));
    }
  }

  Future<void> _syncThenLoad() async {
    // Sağlık okuması yazdıysa hafta yeniden okunur (store o günü günceller;
    // bu sırada yapılan +/- yerel kaldığı için ezilmez).
    await getIt<HealthSyncService>().sync();
    if (!mounted) return;
    await _loadWeek(selectedDate);
  }

  Future<void> _loadWeek(DateTime date) async {
    try {
      await _store.loadWeek(date);
      // Önceki haftayı da arka planda hazırla: geri gidince beklemesin.
      final prev = StepsStore.mondayOf(date).subtract(const Duration(days: 1));
      if (!_store.isWeekLoaded(prev) && prev.isAfter(_earliestStepsDay)) {
        unawaited(_store.loadWeek(prev).catchError((Object _) {}));
      }
    } on Object {
      // Ekranda bilinen değer kalır; sonraki açılışta tekrar denenir.
    }
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
    // Bekleyen kayıt kendi gününe hemen yazılsın.
    _store.flush();
    final direction = clamped.isAfter(selectedDate) ? 1 : -1;
    setState(() {
      dayNavDirection = direction;
      selectedDate = clamped;
    });
    _onStoreChanged();
    unawaited(HapticFeedback.selectionClick());
    // Hafta biliniyorsa sayı anında doğru; sessizce tazelenir.
    await _loadWeek(clamped);
  }

  void disposeStepsControllers() {
    // Bekleyen kayıt kaybolmasın (ekran kapanırken hemen gönderilir).
    _store
      ..flush()
      ..removeListener(_onStoreChanged);
    unawaited(_errors?.cancel());
    progressController.dispose();
  }

  void animateProgressTo(double to, {required double from}) {
    progressAnimation = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: progressController, curve: Curves.easeOut),
    );
  }

  Future<void> runProgressAnimation(double target) async {
    final from = progressAnimation.value.clamp(0.0, 1.0);
    final to = target.clamp(0.0, 1.0);
    if ((from - to).abs() < 0.0001) {
      animateProgressTo(to, from: to);
      progressController.value = 1;
      return;
    }
    // Önce yeni aralık kurulur. reset() eski aralığın başına düşürüp
    // çemberi bir kare geri alıyordu.
    animateProgressTo(to, from: from);
    progressController.value = 0;
    await progressController.forward();
  }

  int? _heightCm() {
    final cm = getIt<ProfileBloc>().state.profile.heightCm;
    if (cm == null || cm <= 0) return null;
    return cm;
  }

  double _weightKg() {
    final home = getIt<HomeBloc>().state;
    if (home is HomeLoaded) {
      final kg = home.summary?.weightCurrentKg;
      if (kg != null && kg > 0) return kg;
    }
    return 70;
  }

  void _changeSteps(int delta) {
    if (!canEditSteps) return;
    final next = (currentSteps + delta).clamp(0, 99999);
    if (next == currentSteps) return;
    getIt<HealthSyncService>().keepManual(selectedDate);
    _store.setSteps(selectedDate, next);
  }

  Future<void> addSteps() async => _changeSteps(addStepAmount);

  Future<void> removeSteps() async => _changeSteps(-addStepAmount);

  /// Bugünün adım hedefi (1.000–50.000). Yalnızca bugün değişir; geçmiş
  /// günler kendi kayıtlı hedefini tutar.
  Future<void> editStepsGoal() async {
    if (!isStepsToday) return;
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
    try {
      await _store.setTodayGoal(goal);
    } on Object catch (e) {
      if (mounted) AppSnackbar.showError(context, e);
    }
  }
}
