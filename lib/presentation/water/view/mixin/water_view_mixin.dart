part of '../water_view.dart';

/// Water ekranı: görünen her değer [WaterStore]'dan okunur. Ekran kendi
/// kopyasını tutmaz; yoldaki GET / özet cevabı onaylanmamış bardağı geri
/// alamaz, gün değişince başka günün değeri görünmez.
mixin WaterViewMixin on State<WaterView>, TickerProvider {
  TrackersRepository get _trackers => getIt<TrackersRepository>();
  WaterStore get _store => getIt<WaterStore>();

  /// Gün geçiş yönü: +1 sonraki, -1 önceki (animasyon için).
  int dayNavDirection = 1;

  static const _minHistoryYears = 2;
  static const bubblesPerAdd = 6;
  static const maxSpawnedBubbles = 48;
  static const hiRevealStart = 0.28;
  static const hiRevealFull = 0.60;
  static const fillDurationMs = 1200;
  static const goalFillDurationMs = 2000;
  static const minGoalMl = 500;
  static const maxGoalMl = 6000;
  static const minGlassMl = 50;
  static const maxGlassMl = 2000;

  late DateTime selectedDate;

  String _waterUnit = 'ml';
  bool _waterNotifications = false;
  List<int> _customGlassSizes = [];

  late AnimationController fillController;
  late AnimationController waveController;
  late AnimationController mascotBobController;
  late AnimationController bubbleController;
  late AnimationController celebrationController;

  Animation<double> fillAnimation = const AlwaysStoppedAnimation(0);

  final bubbleRandom = math.Random();
  final List<_SpawnedBubble> _spawnedBubbles = [];
  int nextBubbleId = 0;

  StreamSubscription<Object>? _errors;

  /// Son çizilen değerler: store değişince yalnızca fark varsa animasyon.
  double _shownProgress = 0;
  bool _shownGoalReached = false;
  DateTime? _shownDate;

  double get celebrationT => celebrationController.value;

  WaterDay? get _day => _store.dayFor(selectedDate);

  int get currentMl => _day?.totalMl ?? 0;

  int get dailyGoalMl => _day?.goalMl ?? widget.dailyGoalMl;

  int get addMl => _day?.glassSizeMl ?? 300;

  /// Widget için son üç yudum (yeniden eskiye).
  List<WaterWidgetSip> get waterSips => [
    for (final e in (_day?.entries ?? const <WaterEntry>[]).reversed.take(3))
      WaterWidgetSip(ml: e.amountMl, at: e.loggedAt),
  ];

  double get progress =>
      dailyGoalMl <= 0 ? 0 : (currentMl / dailyGoalMl).clamp(0.0, 1.0);

  bool get goalReached => currentMl >= dailyGoalMl;

  void initWaterControllers() {
    selectedDate = DateUtils.dateOnly(DateTime.now());
    _shownToday = selectedDate;
    _dayTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(_onClockTick());
    });
    _seedLocalWater();
    _store.addListener(_onStoreChanged);
    _errors = _store.errors.stream.listen((e) {
      if (mounted) AppSnackbar.showError(context, e);
    });

    fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: fillDurationMs),
    );
    waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    mascotBobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat();
    celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: goalFillDurationMs),
      value: goalReached ? 1 : 0,
    );

    reconcileBubbles();
    // Bilinen gün / ana sayfa özeti ile anında dolu aç; ağ sessiz tazeleyecek.
    _shownProgress = progress;
    _shownGoalReached = goalReached;
    _shownDate = selectedDate;
    animateFillTo(progress, from: progress);
    fillController.value = 1;
  }

  /// Repo önbelleği ya da ana sayfa özeti — ilk frame boş gelmesin.
  void _seedLocalWater() {
    final cached = _trackers.cachedWaterDay(date: selectedDate);
    if (cached != null) {
      _store.seedToday(totalMl: cached.totalMl, goalMl: cached.goalMl);
      return;
    }
    final home = getIt<HomeBloc>().state;
    final s = home is HomeLoaded ? home.summary : null;
    _store.seedToday(
      totalMl: s?.waterMl ?? widget.initialMl,
      goalMl: s?.waterGoalMl ?? widget.dailyGoalMl,
    );
  }

  /// Store değişti: sayı / dolma / kutlama / baloncuk / widget hizalanır.
  void _onStoreChanged() {
    if (!mounted) return;
    final shown = _shownDate;
    final sameDay = shown != null && DateUtils.isSameDay(shown, selectedDate);
    setState(reconcileBubbles);
    final target = progress;
    if ((target - _shownProgress).abs() > 0.0001) {
      _shownProgress = target;
      unawaited(runFillAnimation(target));
    }
    if (goalReached != _shownGoalReached) {
      _shownGoalReached = goalReached;
      // Aynı günde hedef geçilirse kutlama oynar; gün değişiminde anında.
      _syncCelebrationFromProgress(animate: sameDay);
    }
    _shownDate = selectedDate;
    unawaited(pushWaterWidget());
  }

  String waterDateLabel(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    if (DateUtils.isSameDay(selectedDate, today)) {
      return 'water_page.today'.tr();
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (DateUtils.isSameDay(selectedDate, yesterday)) {
      return 'water_page.yesterday'.tr();
    }
    return DateFormat.MMMd(context.locale.toString()).format(selectedDate);
  }

  /// Birim / hatırlatma / özel bardaklar sunucudan.
  Future<void> _loadWaterPrefs() async {
    try {
      final prefs = await _trackers.getWaterPrefs();
      if (!mounted) return;
      setState(() {
        _waterUnit = prefs.unit;
        _waterNotifications = prefs.notifications;
        _customGlassSizes = prefs.customGlassSizes;
      });
    } on Object {
      // Varsayılanlar kalır.
    }
  }

  Future<void> bootstrapWaterDay() async {
    unawaited(_loadWaterPrefs());
    await _loadDay(selectedDate);
  }

  /// Seçili günü yükler; bir önceki günü de arka planda hazırlar (geri
  /// gidince beklemesin).
  Future<void> _loadDay(DateTime date) async {
    try {
      await _store.load(date);
    } on Object {
      // Bilinen değer ekranda kalır.
    }
    final prev = date.subtract(const Duration(days: 1));
    if (!_store.isLoaded(prev) && !prev.isBefore(_earliestWaterDay)) {
      unawaited(_store.load(prev).catchError((Object _) {}));
    }
  }

  void _syncCelebrationFromProgress({required bool animate}) {
    if (goalReached) {
      if (celebrationController.value >= 1 &&
          !celebrationController.isAnimating) {
        return;
      }
      if (animate) {
        onGoalCrossed();
      } else {
        celebrationController.value = 1;
        fillController.duration = const Duration(milliseconds: fillDurationMs);
      }
    } else {
      if (celebrationController.value <= 0 &&
          !celebrationController.isAnimating) {
        return;
      }
      if (animate) {
        onGoalLeft();
      } else {
        celebrationController.value = 0;
        fillController.duration = const Duration(milliseconds: fillDurationMs);
      }
    }
  }

  Future<void> pushWaterWidget() async {
    // Geçmiş bir gün geziliyorsa widget (bugün) ezilmesin.
    if (!DateUtils.isSameDay(selectedDate, _today)) return;
    return WaterWidgetSync.publish(
      currentMl: currentMl,
      goalMl: dailyGoalMl,
      addMl: addMl,
      sips: waterSips,
      goalLabel: 'water_reminder.daily_goal'.tr(context: context),
      unitLabel: 'water_reminder.unit_ml'.tr(context: context),
      timelineLabel: 'water_page.timeline'.tr(context: context),
      addTemplate: 'water_page.widget_add'.tr(context: context),
      localeName: context.locale.languageCode,
      largeTitle: 'water_page.widget_title'.tr(context: context),
      largeSubtitle: 'water_page.widget_subtitle'.tr(context: context),
      intakeLabel: 'water_page.current_intake'.tr(context: context),
      percentTemplate: 'water_page.percent_reached'.tr(context: context),
      weeklyLabel: 'water_page.weekly'.tr(context: context),
      historyLabel: 'water_page.view_history'.tr(context: context),
      reminderLabel: 'water_page.next_reminder'.tr(context: context),
      addWaterLabel: 'water_page.add_water'.tr(context: context),
      weekdays: 'water_page.weekdays'.tr(context: context),
    );
  }

  /// Ekran açıkken gece yarısı geçerse "bugün" yeni güne geçer.
  DateTime _shownToday = DateUtils.dateOnly(DateTime.now());
  Timer? _dayTimer;

  Future<void> _onClockTick() async {
    final today = _today;
    if (!mounted || DateUtils.isSameDay(today, _shownToday)) return;
    final wasToday = DateUtils.isSameDay(selectedDate, _shownToday);
    _shownToday = today;
    if (wasToday) await _selectWaterDate(today);
  }

  DateTime get _today => DateUtils.dateOnly(DateTime.now());

  DateTime get _earliestWaterDay =>
      DateTime(_today.year - _minHistoryYears, _today.month, _today.day);

  bool get canGoNextWaterDay => selectedDate.isBefore(_today);

  bool get canGoPrevWaterDay => selectedDate.isAfter(_earliestWaterDay);

  bool get isWaterToday => DateUtils.isSameDay(selectedDate, _today);

  Future<void> onWaterDateTapped() async {
    final result = await AppDialogs.instance.showMealDatePicker(
      context,
      initialDate: selectedDate,
      accentColor: ColorName.colorWaterAction,
    );
    if (result == null || !mounted) return;
    await _selectWaterDate(DateUtils.dateOnly(result.date));
  }

  Future<void> onWaterPrevDay() {
    if (!canGoPrevWaterDay) return Future<void>.value();
    return _shiftWaterDate(-1);
  }

  Future<void> onWaterNextDay() {
    if (!canGoNextWaterDay) return Future<void>.value();
    return _shiftWaterDate(1);
  }

  Future<void> _shiftWaterDate(int dayDelta) {
    final next = DateUtils.dateOnly(selectedDate.add(Duration(days: dayDelta)));
    return _selectWaterDate(next);
  }

  Future<void> _selectWaterDate(DateTime date) async {
    final next = DateUtils.dateOnly(date);
    final today = _today;
    var clamped = next.isAfter(today) ? today : next;
    if (clamped.isBefore(_earliestWaterDay)) clamped = _earliestWaterDay;
    if (DateUtils.isSameDay(clamped, selectedDate)) return;
    // Bekleyen bardaklar kendi gününe (bugün) hemen yazılsın.
    _store.flush();
    final direction = clamped.isAfter(selectedDate) ? 1 : -1;
    setState(() {
      dayNavDirection = direction;
      selectedDate = clamped;
    });
    _onStoreChanged();
    unawaited(HapticFeedback.selectionClick());
    // Gün biliniyorsa sayı anında doğru; sessizce tazelenir.
    await _loadDay(clamped);
  }

  void disposeWaterControllers() {
    _dayTimer?.cancel();
    // Bekleyen bardaklar kaybolmasın (ekran kapanırken hemen gönderilir).
    _store
      ..flush()
      ..removeListener(_onStoreChanged);
    unawaited(_errors?.cancel());
    fillController.dispose();
    waveController.dispose();
    mascotBobController.dispose();
    bubbleController.dispose();
    celebrationController.dispose();
  }

  void reconcileBubbles() {
    final glass = addMl <= 0 ? 300 : addMl;
    var target = (currentMl ~/ glass) * bubblesPerAdd;
    if (currentMl > 0 && target == 0) {
      target = bubblesPerAdd;
    }
    target = target.clamp(0, maxSpawnedBubbles);
    while (_spawnedBubbles.length < target) {
      _spawnedBubbles.add(_createRandomBubble());
    }
    while (_spawnedBubbles.length > target) {
      _spawnedBubbles.removeLast();
    }
  }

  _SpawnedBubble _createRandomBubble() {
    const sizes = <double>[11, 12, 14, 16, 18, 20, 22, 26, 28, 34];
    final size = sizes[bubbleRandom.nextInt(sizes.length)];
    final band = bubbleRandom.nextInt(3);
    final y = switch (band) {
      0 => 0.04 + bubbleRandom.nextDouble() * 0.28,
      1 => 0.34 + bubbleRandom.nextDouble() * 0.28,
      _ => 0.64 + bubbleRandom.nextDouble() * 0.30,
    };
    return _SpawnedBubble(
      id: nextBubbleId++,
      x: 0.06 + bubbleRandom.nextDouble() * 0.88,
      y: y,
      size: size,
      kind: bubbleRandom.nextBool() ? _BubbleKind.type1 : _BubbleKind.type2,
      phase: bubbleRandom.nextDouble(),
    );
  }

  void onGoalCrossed() {
    fillController.duration = const Duration(milliseconds: goalFillDurationMs);
    celebrationController.duration = const Duration(
      milliseconds: goalFillDurationMs,
    );
    unawaited(celebrationController.forward());
  }

  void onGoalLeft() {
    fillController.duration = const Duration(milliseconds: goalFillDurationMs);
    celebrationController.duration = const Duration(
      milliseconds: goalFillDurationMs,
    );
    unawaited(celebrationController.reverse());
  }

  void animateFillTo(double to, {required double from}) {
    fillAnimation = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: fillController, curve: Curves.easeOutCubic),
    );
  }

  Future<void> runFillAnimation(double target) async {
    final from = fillAnimation.value;
    fillController.reset();
    animateFillTo(target, from: from);
    await fillController.forward();
  }

  /// Sunucu kuralı `HIGH_WATER_INTAKE` (> 6000 ml): eşik geçilince bir kez
  /// uyarı.
  static const _highDailyMl = 6000;

  void addWater() {
    if (!isWaterToday) return;
    final amount = addMl;
    if (currentMl <= _highDailyMl && currentMl + amount > _highDailyMl) {
      AppSnackbar.show(
        context: context,
        text: 'water_page.high_intake_warning'.tr(),
        type: SnackBarType.info,
      );
    }
    _store.add(amount);
  }

  void removeWater() {
    if (!isWaterToday || currentMl <= 0) return;
    _store.removeLast();
  }

  Future<void> openReminder() async {
    // Ayar çekmeden hemen git; bildirim toggle'ı reminder sayfasında tazelenir.
    final result = await context.pushNamed<WaterReminderResult>(
      RoutePaths.waterReminder.name,
      extra: WaterReminderArgs(
        dailyGoalMl: dailyGoalMl,
        glassSizeMl: addMl,
        unit: _waterUnit,
        notificationsEnabled: _waterNotifications,
        customGlassSizes: _customGlassSizes,
      ),
    );
    if (result == null || !mounted) return;
    await _persistReminder(result);
  }

  Future<void> _persistReminder(WaterReminderResult result) async {
    final prevUnit = _waterUnit;
    final prevNotif = _waterNotifications;
    final prevCustom = List<int>.of(_customGlassSizes);

    final goal = result.dailyGoalMl.clamp(minGoalMl, maxGoalMl);
    final glass = result.glassSizeMl.clamp(minGlassMl, maxGlassMl);
    if (result.dailyGoalMl != goal || result.glassSizeMl != glass) {
      AppSnackbar.show(
        context: context,
        text: 'water_page.goal_range_error'.tr(
          args: ['$minGoalMl', '$maxGoalMl'],
        ),
        type: SnackBarType.failure,
      );
    }

    setState(() {
      _waterUnit = result.unit;
      _waterNotifications = result.notificationsEnabled;
      _customGlassSizes = List<int>.of(result.customGlassSizes);
    });

    try {
      // Hedef / bardak store'dan: anında görünür, hata olursa geri döner.
      await Future.wait([
        if (goal != dailyGoalMl || glass != addMl)
          _store.setGoals(
            goalMl: goal != dailyGoalMl ? goal : null,
            glassMl: glass != addMl ? glass : null,
          ),
        if (!_listEq(result.customGlassSizes, prevCustom))
          _trackers.updateGoals({'customGlassSizes': result.customGlassSizes}),
        if (result.notificationsEnabled != prevNotif)
          _trackers.updateSettings({
            'notifications': {'water': result.notificationsEnabled},
          }),
        if (result.unit != prevUnit) _trackers.updateWaterUnit(result.unit),
      ]);
      DataSync.afterWrite();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _waterUnit = prevUnit;
        _waterNotifications = prevNotif;
        _customGlassSizes = prevCustom;
      });
      AppSnackbar.showError(context, e);
    }
  }

  bool _listEq(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Hedef ve bardak boyu (`PATCH /user/goals`); anında görünür, hata olursa
  /// eskisine döner.
  Future<void> _saveGoals({int? goalMl, int? glassMl}) async {
    final nextGoal = goalMl?.clamp(minGoalMl, maxGoalMl);
    final nextGlass = glassMl?.clamp(minGlassMl, maxGlassMl);

    if (goalMl != null && goalMl != nextGoal) {
      AppSnackbar.show(
        context: context,
        text: 'water_page.goal_range_error'.tr(
          args: ['$minGoalMl', '$maxGoalMl'],
        ),
        type: SnackBarType.failure,
      );
      return;
    }
    if (glassMl != null && glassMl != nextGlass) {
      AppSnackbar.show(
        context: context,
        text: 'water_page.glass_range_error'.tr(
          args: ['$minGlassMl', '$maxGlassMl'],
        ),
        type: SnackBarType.failure,
      );
      return;
    }
    final goal = nextGoal != dailyGoalMl ? nextGoal : null;
    final glass = nextGlass != addMl ? nextGlass : null;
    if (goal == null && glass == null) return;
    try {
      await _store.setGoals(goalMl: goal, glassMl: glass);
    } on Object catch (e) {
      if (mounted) AppSnackbar.showError(context, e);
    }
  }

  Future<void> editDailyGoal() async {
    final result = await AppDialogs.instance.showEditWaterValue(
      context,
      titleKey: 'water_reminder.daily_goal',
      subtitleKey: 'water_reminder.goal_dialog_subtitle',
      initialValueMl: dailyGoalMl,
      initialUnit: _waterUnit == 'oz' ? WaterVolumeUnit.oz : WaterVolumeUnit.ml,
      headerImage: AppImages.waterBottle,
    );
    if (result == null || !mounted) return;
    final prevUnit = _waterUnit;
    _waterUnit = result.unit == WaterVolumeUnit.oz ? 'oz' : 'ml';
    await _saveGoals(goalMl: result.valueMl);
    if (_waterUnit != prevUnit) {
      try {
        await _trackers.updateWaterUnit(_waterUnit);
      } on Object {
        // Hedef kaydı asıl iş; birim ikincil.
      }
    }
  }
}
