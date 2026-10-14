part of '../water_view.dart';

/// Water ekranı state / animasyon / navigasyon yardımcıları.
mixin WaterViewMixin on State<WaterView>, TickerProvider {
  TrackersRepository get _trackers => getIt<TrackersRepository>();

  List<String> _waterEntryIds = [];
  final Map<String, int> _entryAmounts = {};
  final List<_PendingWaterOp> _pendingOps = [];
  Timer? _waterDebounce;
  bool _waterFlushing = false;
  int _waterLoadGen = 0;

  /// Gün geçiş yönü: +1 sonraki, -1 önceki (animasyon için).
  int dayNavDirection = 1;

  static const _waterDebounceMs = 450;
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

  late int addMl;
  late int currentMl;
  late int dailyGoalMl;
  late DateTime selectedDate;
  final waterSips = <WaterWidgetSip>[];

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

  double get celebrationT => celebrationController.value;

  double get progress =>
      dailyGoalMl <= 0 ? 0 : (currentMl / dailyGoalMl).clamp(0.0, 1.0);

  bool get goalReached => currentMl >= dailyGoalMl;

  void initWaterControllers() {
    addMl = 300;
    currentMl = widget.initialMl;
    dailyGoalMl = widget.dailyGoalMl;
    selectedDate = DateUtils.dateOnly(DateTime.now());
    _shownToday = selectedDate;
    _dayTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(_onClockTick());
    });
    _seedLocalWater();

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
    // Cache / home özeti ile anında dolu aç; ağ sessiz tazeleyecek.
    animateFillTo(progress, from: progress);
    fillController.value = 1;
  }

  /// Home özeti + bellek cache — ilk frame boş gelmesin.
  void _seedLocalWater() {
    final cached = _trackers.cachedWaterDay(date: selectedDate);
    if (cached != null) {
      currentMl = cached.totalMl;
      dailyGoalMl = cached.goalMl;
      addMl = cached.glassSizeMl;
      _waterEntryIds = cached.entries.map((e) => e.id).toList();
      _entryAmounts
        ..clear()
        ..addEntries(cached.entries.map((e) => MapEntry(e.id, e.amountMl)));
      waterSips
        ..clear()
        ..addAll(
          cached.entries.reversed
              .take(3)
              .map((e) => WaterWidgetSip(ml: e.amountMl, at: e.loggedAt)),
        );
      return;
    }

    final home = getIt<HomeBloc>().state;
    if (home is! HomeLoaded) return;
    final s = home.summary;
    if (s == null) return;
    currentMl = s.waterMl;
    dailyGoalMl = s.waterGoalMl ?? dailyGoalMl;
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

  /// Seed yoksa yerel widget verisi, sonra ağ — ilk frame boş kalmasın.
  /// Birim / hatırlatma / özel bardaklar sunucudan (önceden hiç
  /// yüklenmiyordu, ekran hep varsayılanla açılıyordu).
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
    if (currentMl <= 0) {
      await bindWaterWidgetLocalOnly();
    }
    await loadWaterDay();
  }

  Future<void> loadWaterDay({bool animateFill = false}) async {
    final gen = ++_waterLoadGen;
    final date = selectedDate;
    try {
      final day = await _trackers.getWaterDay(date: date);
      if (!mounted || gen != _waterLoadGen) return;
      if (!DateUtils.isSameDay(date, selectedDate)) return;
      // Bekleyen yerel işlem varken sunucu cevabı ezmesin.
      if (_pendingOps.isNotEmpty || _waterFlushing) return;
      _applyWaterDay(day, animateFill: animateFill);
    } on Object {
      if (!mounted || gen != _waterLoadGen) return;
      if (DateUtils.isSameDay(selectedDate, _today)) {
        await bindWaterWidgetLocalOnly();
      }
    }
  }

  void _applyWaterDay(WaterDay day, {bool animateFill = false}) {
    final fromFill = fillAnimation.value.clamp(0.0, 1.0);
    setState(() {
      currentMl = day.totalMl;
      dailyGoalMl = day.goalMl;
      addMl = day.glassSizeMl;
      _waterEntryIds = day.entries.map((e) => e.id).toList();
      _entryAmounts
        ..clear()
        ..addEntries(day.entries.map((e) => MapEntry(e.id, e.amountMl)));
      waterSips
        ..clear()
        ..addAll(
          day.entries.reversed
              .take(3)
              .map((e) => WaterWidgetSip(ml: e.amountMl, at: e.loggedAt)),
        );
      reconcileBubbles();
    });
    if (animateFill) {
      unawaited(runFillAnimation(progress));
    } else {
      fillController.value = 1;
      animateFillTo(progress, from: fromFill);
    }
    // Sayfa dönüşünde / sunucu senkronunda tamamlanma durumunu anında uygula.
    _syncCelebrationFromProgress(animate: animateFill);
    unawaited(pushWaterWidget());
  }

  /// [goalReached] ile celebration UI'sını hizala.
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

  Future<void> bindWaterWidgetLocalOnly() async {
    final saved = await WaterWidgetSync.read();
    if (!mounted) return;
    if (saved != null) {
      setState(() {
        currentMl = saved.currentMl;
        dailyGoalMl = saved.goalMl;
        addMl = saved.addMl;
        waterSips
          ..clear()
          ..addAll(saved.sips);
        reconcileBubbles();
      });
      fillController.value = 1;
      animateFillTo(progress, from: progress);
      _syncCelebrationFromProgress(animate: false);
    }
    await pushWaterWidget();
  }

  Future<void> pushWaterWidget() async {
    // Geçmiş bir gün geziliyorsa widget (bugün) ezilmesin.
    if (!DateUtils.isSameDay(selectedDate, _today)) return;
    return WaterWidgetSync.publish(
      currentMl: currentMl,
      goalMl: dailyGoalMl,
      addMl: addMl,
      sips: List<WaterWidgetSip>.of(waterSips),
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

  /// Ekran açıkken gece yarısı geçerse "bugün" yeni güne geçer; önceden
  /// seçili gün dünde kalıyor, + düğmesi gizleniyordu.
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

    final direction = clamped.isAfter(selectedDate) ? 1 : -1;
    await _flushWaterOps(force: true);
    if (!mounted) return;

    final cached = _trackers.cachedWaterDay(date: clamped);
    setState(() {
      dayNavDirection = direction;
      selectedDate = clamped;
      if (cached != null) {
        currentMl = cached.totalMl;
        dailyGoalMl = cached.goalMl;
        addMl = cached.glassSizeMl;
        _waterEntryIds = cached.entries.map((e) => e.id).toList();
        _entryAmounts
          ..clear()
          ..addEntries(cached.entries.map((e) => MapEntry(e.id, e.amountMl)));
        waterSips
          ..clear()
          ..addAll(
            cached.entries.reversed
                .take(3)
                .map((e) => WaterWidgetSip(ml: e.amountMl, at: e.loggedAt)),
          );
        reconcileBubbles();
      }
    });
    if (cached != null) {
      unawaited(runFillAnimation(progress));
      _syncCelebrationFromProgress(animate: false);
    }
    HapticFeedback.selectionClick();
    await loadWaterDay(animateFill: cached == null);
  }

  void disposeWaterControllers() {
    _dayTimer?.cancel();
    _waterDebounce?.cancel();
    final ops = List<_PendingWaterOp>.of(_pendingOps);
    _pendingOps.clear();
    if (ops.isNotEmpty) {
      unawaited(_persistOpsInBackground(ops));
    }
    fillController.dispose();
    waveController.dispose();
    mascotBobController.dispose();
    bubbleController.dispose();
    celebrationController.dispose();
  }

  Future<void> _persistOpsInBackground(List<_PendingWaterOp> ops) async {
    try {
      for (final op in ops) {
        if (op.isAdd) {
          await _trackers.addWater(id: op.id, amountMl: op.amountMl);
        } else {
          await _trackers.deleteWaterEntry(op.id);
        }
      }
      DataSync.afterWrite();
    } on Object {
      // Ekran kapalı; sonraki açılışta sunucu durumu yüklenir.
    }
  }

  void reconcileBubbles() {
    var target = (currentMl ~/ addMl) * bubblesPerAdd;
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

  void resetCelebrationIfNeeded() {
    if (!goalReached && !celebrationController.isAnimating) {
      fillController.duration = const Duration(milliseconds: fillDurationMs);
      if (celebrationController.value > 0) {
        celebrationController.value = 0;
      }
    }
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

  void _scheduleWaterSync() {
    _waterDebounce?.cancel();
    _waterDebounce = Timer(
      const Duration(milliseconds: _waterDebounceMs),
      () => unawaited(_flushWaterOps()),
    );
  }

  Future<void> _flushWaterOps({bool force = false}) async {
    _waterDebounce?.cancel();
    _waterDebounce = null;
    if (_pendingOps.isEmpty || _waterFlushing) return;
    _waterFlushing = true;
    final ops = _coalesceWaterOps(_pendingOps);
    _pendingOps.clear();
    try {
      WaterDay? day;
      for (final op in ops) {
        if (op.isAdd) {
          day = await _trackers.addWater(id: op.id, amountMl: op.amountMl);
        } else {
          day = await _trackers.deleteWaterEntry(op.id);
        }
      }
      // Ekrandan çıkılmış olsa da diğer ekranlar tazelensin.
      DataSync.afterWrite();
      if (!mounted) return;
      if (_pendingOps.isEmpty && day != null) {
        _applyWaterDay(day);
      }
    } on Object catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, e);
      _pendingOps.clear();
      // Bayrak açıkken loadWaterDay sunucu cevabını yok sayar; iyimser
      // (kaydedilmemiş) değer ekranda kalırdı. Önce kapat, sonra hizala.
      _waterFlushing = false;
      await loadWaterDay();
    } finally {
      _waterFlushing = false;
      if (_pendingOps.isNotEmpty && mounted) {
        if (force) {
          await _flushWaterOps(force: true);
        } else {
          _scheduleWaterSync();
        }
      }
    }
  }

  /// Aynı id için add+remove iptal; gereksiz ardışık isteği azaltır.
  List<_PendingWaterOp> _coalesceWaterOps(List<_PendingWaterOp> raw) {
    final byId = <String, _PendingWaterOp>{};
    for (final op in raw) {
      final prev = byId[op.id];
      if (prev == null) {
        byId[op.id] = op;
        continue;
      }
      // add sonra remove (veya tersi) → net sıfır
      if (prev.isAdd != op.isAdd) {
        byId.remove(op.id);
      } else {
        byId[op.id] = op;
      }
    }
    // Orijinal sırayı koru.
    final seen = <String>{};
    final out = <_PendingWaterOp>[];
    for (final op in raw) {
      final kept = byId[op.id];
      if (kept == null || !seen.add(op.id)) continue;
      out.add(kept);
    }
    return out;
  }

  /// UI anında güncellenir; ağ isteği debounce ile gider.
  static const _highDailyMl = 6000;

  void addWater() {
    if (!isWaterToday) return;
    final wasGoal = goalReached;
    final id = _trackers.newWaterEntryId();
    final amount = addMl;
    // Sunucu kuralı `HIGH_WATER_INTAKE` (> 6000 ml): eşik geçilince bir kez
    // uyarı (önceden hiç gösterilmiyordu).
    if (currentMl <= _highDailyMl && currentMl + amount > _highDailyMl) {
      AppSnackbar.show(
        context: context,
        text: 'water_page.high_intake_warning'.tr(),
        type: SnackBarType.info,
      );
    }
    setState(() {
      currentMl += amount;
      _waterEntryIds.add(id);
      _entryAmounts[id] = amount;
      waterSips.insert(0, WaterWidgetSip(ml: amount, at: DateTime.now()));
      if (waterSips.length > 3) waterSips.removeLast();
      reconcileBubbles();
    });
    _pendingOps.add(_PendingWaterOp.add(id: id, amountMl: amount));
    _scheduleWaterSync();
    unawaited(pushWaterWidget());

    if (!wasGoal && goalReached) {
      onGoalCrossed();
    } else if (goalReached && celebrationController.value < 1) {
      unawaited(celebrationController.forward());
    }
    unawaited(runFillAnimation(progress));
  }

  void removeWater() {
    if (!isWaterToday) return;
    if (_waterEntryIds.isEmpty || currentMl <= 0) return;
    final wasGoal = goalReached;
    final id = _waterEntryIds.last;
    final amount = _entryAmounts[id] ?? addMl;

    final pendingAdd = _pendingOps.indexWhere((o) => o.isAdd && o.id == id);
    if (pendingAdd >= 0) {
      _pendingOps.removeAt(pendingAdd);
    } else {
      _pendingOps.add(_PendingWaterOp.remove(id: id, amountMl: amount));
    }

    setState(() {
      _waterEntryIds.removeLast();
      _entryAmounts.remove(id);
      currentMl = (currentMl - amount).clamp(0, 100000);
      if (waterSips.isNotEmpty) waterSips.removeAt(0);
      reconcileBubbles();
    });
    _scheduleWaterSync();
    unawaited(pushWaterWidget());

    if (wasGoal && !goalReached) {
      onGoalLeft();
    } else {
      resetCelebrationIfNeeded();
    }
    unawaited(runFillAnimation(progress));
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
    final prevGoal = dailyGoalMl;
    final prevGlass = addMl;
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
      dailyGoalMl = goal;
      addMl = glass;
      _waterUnit = result.unit;
      _waterNotifications = result.notificationsEnabled;
      _customGlassSizes = List<int>.of(result.customGlassSizes);
      reconcileBubbles();
    });
    unawaited(runFillAnimation(progress));
    _syncCelebrationFromProgress(animate: true);
    unawaited(pushWaterWidget());

    try {
      final goalFields = <String, dynamic>{
        if (goal != prevGoal) 'waterGoalMl': goal,
        if (glass != prevGlass) 'glassSizeMl': glass,
        if (!_listEq(result.customGlassSizes, prevCustom))
          'customGlassSizes': result.customGlassSizes,
      };
      final futures = <Future<void>>[
        if (goalFields.isNotEmpty) _trackers.updateGoals(goalFields),
        if (result.notificationsEnabled != prevNotif)
          _trackers.updateSettings({
            'notifications': {'water': result.notificationsEnabled},
          }),
        if (result.unit != prevUnit) _trackers.updateWaterUnit(result.unit),
      ];
      if (futures.isNotEmpty) await Future.wait(futures);
      DataSync.afterWrite();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        dailyGoalMl = prevGoal;
        addMl = prevGlass;
        _waterUnit = prevUnit;
        _waterNotifications = prevNotif;
        _customGlassSizes = prevCustom;
        reconcileBubbles();
      });
      unawaited(runFillAnimation(progress));
      _syncCelebrationFromProgress(animate: false);
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

  /// Hedef ve bardak boyu sunucuya yazılır (`PATCH /user/goals`); hemen
  /// gösterilir, hata olursa eskisine döner.
  Future<void> _saveGoals({int? goalMl, int? glassMl}) async {
    final prevGoal = dailyGoalMl;
    final prevGlass = addMl;
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

    final fields = <String, dynamic>{
      if (nextGoal != null && nextGoal != prevGoal) 'waterGoalMl': nextGoal,
      if (nextGlass != null && nextGlass != prevGlass) 'glassSizeMl': nextGlass,
    };
    if (fields.isEmpty) return;

    void apply(int goal, int glass, {required bool animateCelebration}) {
      setState(() {
        dailyGoalMl = goal;
        addMl = glass;
        reconcileBubbles();
      });
      unawaited(runFillAnimation(progress));
      _syncCelebrationFromProgress(animate: animateCelebration);
      unawaited(pushWaterWidget());
    }

    apply(
      nextGoal ?? prevGoal,
      nextGlass ?? prevGlass,
      animateCelebration: true,
    );
    try {
      await _trackers.updateGoals(fields);
      DataSync.afterWrite();
    } on Object catch (e) {
      if (!mounted) return;
      apply(prevGoal, prevGlass, animateCelebration: false);
      AppSnackbar.showError(context, e);
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

final class _PendingWaterOp {
  const _PendingWaterOp._({
    required this.id,
    required this.amountMl,
    required this.isAdd,
  });

  factory _PendingWaterOp.add({required String id, required int amountMl}) =>
      _PendingWaterOp._(id: id, amountMl: amountMl, isAdd: true);

  factory _PendingWaterOp.remove({required String id, required int amountMl}) =>
      _PendingWaterOp._(id: id, amountMl: amountMl, isAdd: false);

  final String id;
  final int amountMl;
  final bool isAdd;
}
