part of '../steps_view.dart';

/// Steps ekranı state / animasyon yardımcıları.
mixin StepsViewMixin on State<StepsView>, TickerProvider {
  static const addStepAmount = 500;
  static const progressDurationMs = 900;

  /// ~0.04 kcal / adım, ~0.0007 km / adım, ~0.01 dk / adım (mock türetim).
  static const kcalPerStep = 0.04;
  static const kmPerStep = 0.0007;
  static const minPerStep = 0.01;

  late int currentSteps;
  late int dailyGoalSteps;

  /// Pazartesi→Pazar; bugünün index'i canlı güncellenir.
  late List<int> weeklySteps;
  late int todayWeekIndex;

  late AnimationController progressController;
  Animation<double> progressAnimation = const AlwaysStoppedAnimation(0);

  double get progress =>
      dailyGoalSteps <= 0 ? 0 : (currentSteps / dailyGoalSteps).clamp(0.0, 1.0);

  bool get goalReached => currentSteps >= dailyGoalSteps;

  int get caloriesKcal => (currentSteps * kcalPerStep).round();

  String get distanceKm => (currentSteps * kmPerStep).toStringAsFixed(1);

  int get durationMin => (currentSteps * minPerStep).round();

  void initStepsControllers() {
    currentSteps = widget.initialSteps;
    dailyGoalSteps = widget.dailyGoalSteps;
    todayWeekIndex = (DateTime.now().weekday - 1).clamp(0, 6);
    weeklySteps = List<int>.from(const [
      4200,
      6100,
      3800,
      7200,
      5400,
      2900,
      1000,
    ]);
    weeklySteps[todayWeekIndex] = currentSteps;

    progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: progressDurationMs),
    );
    animateProgressTo(progress, from: 0);
    progressController.forward();
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

  void _syncTodayBar() {
    weeklySteps[todayWeekIndex] = currentSteps;
  }

  void addSteps() {
    setState(() {
      currentSteps = (currentSteps + addStepAmount).clamp(0, 99999);
      _syncTodayBar();
    });
    unawaited(runProgressAnimation(progress));
  }

  void removeSteps() {
    if (currentSteps <= 0) return;
    setState(() {
      currentSteps = (currentSteps - addStepAmount).clamp(0, 99999);
      _syncTodayBar();
    });
    unawaited(runProgressAnimation(progress));
  }
}
