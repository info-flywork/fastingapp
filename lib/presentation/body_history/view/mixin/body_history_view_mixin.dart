part of '../body_history_view.dart';

mixin BodyHistoryViewMixin on State<BodyHistoryView> {
  TrackersRepository get _trackers => getIt<TrackersRepository>();

  double? currentKg;
  double? startKg;
  double? targetKg;
  double? bmi;
  double? heightCm;

  _HistoryRange selectedRange = _HistoryRange.day;
  int selectedPointIndex = 0;
  List<_ChartPoint> chartPoints = const [];
  double chartYMin = 65;
  double chartYMax = 120;

  /// Yalnızca grafik alanı; sayfa iskeleti anında açılır.
  bool chartLoading = true;

  void initBodyHistory() {
    currentKg = widget.currentKg;
    startKg = widget.startKg;
    targetKg = widget.targetKg;
    bmi = widget.bmi;
    heightCm = widget.heightCm;
    _seedFromHomeSummary();
    _recomputeBmi();
    unawaited(_loadSummaryAndChart());
  }

  void _seedFromHomeSummary() {
    final home = getIt<HomeBloc>().state;
    if (home is! HomeLoaded) return;
    final s = home.summary;
    currentKg ??= s?.weightCurrentKg;
    startKg ??= s?.weightStartKg;
    targetKg ??= s?.weightGoalKg;
  }

  double? _bmiFor(double? kg) {
    final h = heightCm;
    if (kg == null || h == null || h <= 0) return null;
    final m = h / 100;
    return double.parse((kg / (m * m)).toStringAsFixed(1));
  }

  void _recomputeBmi() {
    bmi = _bmiFor(currentKg) ?? bmi;
  }

  Future<void> _loadSummaryAndChart() async {
    setState(() => chartLoading = true);
    // Özet (BMI) ile grafik paralel — BMI kartı grafik bitmeden dolar.
    final summaryFuture = _trackers.getWeightSummary();
    final chartFuture = _fetchChart(selectedRange);

    try {
      final summary = await summaryFuture;
      if (!mounted) return;
      setState(() {
        currentKg = summary.currentKg ?? currentKg;
        startKg = summary.startKg ?? startKg;
        targetKg = summary.goalKg ?? targetKg;
        heightCm = summary.heightCm ?? heightCm;
        bmi = summary.bmi ?? _bmiFor(currentKg) ?? bmi;
      });
    } on Object {
      // Seed / yerel BMI kalsın.
    }

    try {
      final chart = await chartFuture;
      if (!mounted) return;
      _applyChart(chart);
    } on Object {
      if (mounted) setState(() => chartPoints = const []);
    } finally {
      if (mounted) setState(() => chartLoading = false);
    }
  }

  Future<WeightChart> _fetchChart(_HistoryRange range) {
    final apiRange = switch (range) {
      _HistoryRange.day => 'day',
      _HistoryRange.week => 'week',
      _HistoryRange.month => 'month',
    };
    return _trackers.getWeightChart(apiRange);
  }

  void _applyChart(WeightChart chart) {
    final points = <_ChartPoint>[
      for (final b in chart.buckets)
        if (b.weightKg != null) _ChartPoint(label: b.label, kg: b.weightKg!),
    ];
    setState(() {
      chartYMin = chart.yMin ?? chartYMin;
      chartYMax = chart.yMax ?? chartYMax;
      chartPoints = points;
      selectedPointIndex = points.isEmpty
          ? 0
          : math.min(selectedPointIndex, points.length - 1);
    });
  }

  void _upsertTodayChartPoint(double kg) {
    if (chartPoints.isEmpty) {
      chartPoints = [_ChartPoint(label: '—', kg: kg)];
      selectedPointIndex = 0;
      return;
    }
    final last = chartPoints.length - 1;
    chartPoints = [
      for (var i = 0; i < chartPoints.length; i++)
        i == last ? _ChartPoint(label: chartPoints[i].label, kg: kg) : chartPoints[i],
    ];
    selectedPointIndex = last;
    final lo = chartPoints.map((p) => p.kg).reduce(math.min);
    final hi = chartPoints.map((p) => p.kg).reduce(math.max);
    chartYMin = math.min(chartYMin, lo - 2);
    chartYMax = math.max(chartYMax, hi + 2);
  }

  void onRangeChanged(_HistoryRange range) {
    setState(() {
      selectedRange = range;
      selectedPointIndex = 0;
      chartLoading = true;
    });
    unawaited(() async {
      try {
        final chart = await _fetchChart(range);
        if (!mounted) return;
        _applyChart(chart);
      } on Object {
        if (mounted) setState(() => chartPoints = const []);
      } finally {
        if (mounted) setState(() => chartLoading = false);
      }
    }());
  }

  void onPointSelected(int index) {
    setState(() => selectedPointIndex = index);
  }

  void onUpdateTapped() {
    _openWeightDialog();
  }

  Future<void> _openWeightDialog() async {
    final result = await AppDialogs.instance.showEditWeight(
      context,
      initialWeightKg: currentKg ?? 70,
    );
    if (result == null || !mounted) return;

    final kg = result.weightKg;
    final prevCurrent = currentKg;
    final prevBmi = bmi;
    final prevPoints = chartPoints;
    final prevIndex = selectedPointIndex;
    final prevYMin = chartYMin;
    final prevYMax = chartYMax;

    // Anında UI — API cevabını bekleme.
    setState(() {
      currentKg = kg;
      bmi = _bmiFor(kg) ?? bmi;
      _upsertTodayChartPoint(kg);
    });

    try {
      await _trackers.createWeight(weightKg: kg);
      if (!mounted) return;
      DataSync.afterWrite(profile: true);
      // Sunucu özeti / grafik arka planda; ekran zaten güncel.
      unawaited(_refreshAfterWrite());
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        currentKg = prevCurrent;
        bmi = prevBmi;
        chartPoints = prevPoints;
        selectedPointIndex = prevIndex;
        chartYMin = prevYMin;
        chartYMax = prevYMax;
      });
      AppSnackbar.showError(context, e);
    }
  }

  Future<void> _refreshAfterWrite() async {
    try {
      final summary = await _trackers.getWeightSummary();
      if (!mounted) return;
      setState(() {
        currentKg = summary.currentKg ?? currentKg;
        startKg = summary.startKg ?? startKg;
        targetKg = summary.goalKg ?? targetKg;
        heightCm = summary.heightCm ?? heightCm;
        bmi = summary.bmi ?? _bmiFor(currentKg) ?? bmi;
      });
      final chart = await _fetchChart(selectedRange);
      if (!mounted) return;
      _applyChart(chart);
    } on Object {
      // Optimistic UI yeterli.
    }
  }

  Future<void> onEditTargetTapped() async {
    final result = await AppDialogs.instance.showEditWeight(
      context,
      initialWeightKg: targetKg ?? currentKg ?? 70,
    );
    if (result == null || !mounted) return;

    final prev = targetKg;
    setState(() => targetKg = result.weightKg);

    try {
      final summary = await _trackers.setWeightGoal(result.weightKg);
      if (!mounted) return;
      setState(() {
        if (summary.goalKg != null) targetKg = summary.goalKg!;
      });
      DataSync.afterWrite(profile: true);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => targetKg = prev);
      AppSnackbar.showError(context, e);
    }
  }
}
