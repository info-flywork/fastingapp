part of '../water_view.dart';

/// Water ekranı state / animasyon / navigasyon yardımcıları.
mixin WaterViewMixin on State<WaterView>, TickerProvider {
  static const bubblesPerAdd = 6;
  static const maxSpawnedBubbles = 48;
  static const hiRevealStart = 0.28;
  static const hiRevealFull = 0.60;
  static const fillDurationMs = 1200;
  static const goalFillDurationMs = 2000;

  late int addMl;
  late int currentMl;
  late int dailyGoalMl;
  late DateTime selectedDate;

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
    animateFillTo(progress, from: 0);
    fillController.forward();
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

  Future<void> onWaterDateTapped() async {
    final result = await AppDialogs.instance.showMealDatePicker(
      context,
      initialDate: selectedDate,
    );
    if (result == null || !mounted) return;
    setState(() => selectedDate = DateUtils.dateOnly(result.date));
  }

  void disposeWaterControllers() {
    fillController.dispose();
    waveController.dispose();
    mascotBobController.dispose();
    bubbleController.dispose();
    celebrationController.dispose();
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

  void addWater() {
    final wasGoal = goalReached;
    setState(() {
      currentMl = (currentMl + addMl).clamp(0, 99999);
      reconcileBubbles();
    });
    if (!wasGoal && goalReached) {
      onGoalCrossed();
    } else if (goalReached && celebrationController.value < 1) {
      unawaited(celebrationController.forward());
    }
    unawaited(runFillAnimation(progress));
  }

  void removeWater() {
    if (currentMl <= 0) return;
    final wasGoal = goalReached;
    setState(() {
      currentMl = (currentMl - addMl).clamp(0, 99999);
      reconcileBubbles();
    });
    if (wasGoal && !goalReached) {
      onGoalLeft();
    } else {
      resetCelebrationIfNeeded();
    }
    unawaited(runFillAnimation(progress));
  }

  Future<void> openReminder() async {
    final result = await context.pushNamed<WaterReminderResult>(
      RoutePaths.waterReminder.name,
      extra: WaterReminderArgs(dailyGoalMl: dailyGoalMl, glassSizeMl: addMl),
    );
    if (result == null || !mounted) return;
    setState(() {
      dailyGoalMl = result.dailyGoalMl;
      addMl = result.glassSizeMl;
      reconcileBubbles();
    });
    unawaited(runFillAnimation(progress));
  }

  Future<void> editDailyGoal() async {
    final result = await AppDialogs.instance.showEditWaterValue(
      context,
      titleKey: 'water_reminder.daily_goal',
      subtitleKey: 'water_reminder.goal_dialog_subtitle',
      initialValueMl: dailyGoalMl,
      initialUnit: WaterVolumeUnit.ml,
      headerImage: Assets.images.waterBottle,
    );
    if (result == null || !mounted) return;
    setState(() => dailyGoalMl = result.valueMl);
    unawaited(runFillAnimation(progress));
  }
}
