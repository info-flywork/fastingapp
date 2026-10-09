part of '../steps_view.dart';

/// Steps ekranı state / animasyon yardımcıları.
mixin StepsViewMixin on State<StepsView>, TickerProvider {
  static const addStepAmount = 500;
  static const progressDurationMs = 900;

  TrackersRepository get _trackers => getIt<TrackersRepository>();

  late int currentSteps;
  late int dailyGoalSteps;
  late DateTime selectedDate;
  int caloriesKcal = 0;
  String distanceKm = '0.0';
  int durationMin = 0;

  /// Pazartesi→Pazar; seçili günün hafta index'i.
  late List<int> weeklySteps;
  late int todayWeekIndex;

  late AnimationController progressController;
  Animation<double> progressAnimation = const AlwaysStoppedAnimation(0);

  /// Gün geçiş yönü: +1 sonraki, -1 önceki (animasyon için).
  int dayNavDirection = 1;
  int _stepsLoadGen = 0;

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
    animateProgressTo(0, from: 0);
    unawaited(loadStepsWeek());
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
    final date = selectedDate;
    try {
      final range = await _trackers.getSteps(
        range: 'week',
        date: date,
      );
      if (!mounted || gen != _stepsLoadGen) return;
      if (!DateUtils.isSameDay(date, selectedDate)) return;
      _applyStepsRange(range);
    } on Object {
      // initialSteps / widget yedeği
    }
  }

  void _applyStepsRange(StepsRange range) {
    final focus = DateUtils.dateOnly(selectedDate);
    setState(() {
      dailyGoalSteps = range.goal;
      weeklySteps = List<int>.filled(7, 0);
      currentSteps = 0;
      caloriesKcal = 0;
      distanceKm = '0.0';
      durationMin = 0;
      todayWeekIndex = (focus.weekday - 1).clamp(0, 6);
      for (final day in range.days) {
        final d = DateUtils.dateOnly(day.date);
        final idx = (d.weekday - 1).clamp(0, 6);
        weeklySteps[idx] = day.steps;
        if (DateUtils.isSameDay(d, focus)) {
          todayWeekIndex = idx;
          currentSteps = day.steps;
          caloriesKcal = day.kcal;
          distanceKm = day.distanceKm.toStringAsFixed(1);
          durationMin = day.durationMin;
        }
      }
    });
    unawaited(runProgressAnimation(progress));
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
    final next = DateUtils.dateOnly(
      selectedDate.add(Duration(days: dayDelta)),
    );
    return _selectStepsDate(next);
  }

  Future<void> _selectStepsDate(DateTime date) async {
    final next = DateUtils.dateOnly(date);
    var clamped = next.isAfter(_today) ? _today : next;
    if (clamped.isBefore(_earliestStepsDay)) clamped = _earliestStepsDay;
    if (DateUtils.isSameDay(clamped, selectedDate)) return;

    final direction = clamped.isAfter(selectedDate) ? 1 : -1;
    setState(() {
      dayNavDirection = direction;
      selectedDate = clamped;
    });
    HapticFeedback.selectionClick();
    await loadStepsWeek();
  }

  Future<void> _persistSelectedDaySteps() async {
    final range = await _trackers.putSteps(
      date: selectedDate,
      steps: currentSteps,
    );
    if (!mounted) return;
    _applyStepsRange(range);
    DataSync.afterWrite();
  }

  void disposeStepsControllers() {
    progressController.dispose();
  }

  void animateProgressTo(double to, {required double from}) {
    progressAnimation = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: progressController, curve: Curves.easeOutCubic),
    );
  }

  Future<void> runProgressAnimation(double target) async {
    final from = progressAnimation.value;
    progressController.reset();
    animateProgressTo(target, from: from);
    await progressController.forward();
  }

  void _syncSelectedBar() {
    weeklySteps[todayWeekIndex] = currentSteps;
  }

  Future<void> addSteps() async {
    if (!isStepsToday) return;
    setState(() {
      currentSteps = (currentSteps + addStepAmount).clamp(0, 99999);
      _syncSelectedBar();
    });
    unawaited(runProgressAnimation(progress));
    try {
      await _persistSelectedDaySteps();
    } on Object {
      // Yerel sayaç korunur
    }
  }

  Future<void> removeSteps() async {
    if (!isStepsToday) return;
    if (currentSteps <= 0) return;
    setState(() {
      currentSteps = (currentSteps - addStepAmount).clamp(0, 99999);
      _syncSelectedBar();
    });
    unawaited(runProgressAnimation(progress));
    try {
      await _persistSelectedDaySteps();
    } on Object {
      // Yerel sayaç korunur
    }
  }
}
