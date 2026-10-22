part of '../body_history_view.dart';

mixin BodyHistoryViewMixin on State<BodyHistoryView> {
  TrackersRepository get _trackers => getIt<TrackersRepository>();

  double? currentKg;
  double? startKg;
  double? targetKg;
  double? bmi;
  double? heightCm;

  _HistoryRange selectedRange = _HistoryRange.day;

  /// Son kilo kayıtları (`GET /weights`).
  List<WeightEntry> entries = const [];
  int selectedPointIndex = 0;
  List<_ChartPoint> chartPoints = const [];
  double chartYMin = 65;
  double chartYMax = 120;

  /// Yalnızca grafik alanı; sayfa iskeleti anında açılır.
  bool chartLoading = true;

  /// Aralık başına grafik: sekme değişiminde iskelet yok, diğer aralıklar
  /// arka planda önceden yüklenir. Kilo yazılınca boşaltılır.
  final Map<_HistoryRange, WeightChart> _charts = {};

  /// Kilo yazılınca artar: yazmadan önce başlamış ön yüklemeler eski
  /// grafiği önbelleğe koymasın.
  int _chartGeneration = 0;

  Future<WeightChart> _chartFor(_HistoryRange range) async {
    final generation = _chartGeneration;
    final chart = await _fetchChart(range);
    if (generation == _chartGeneration) _charts[range] = chart;
    return chart;
  }

  void _prefetchOtherRanges() {
    for (final range in _HistoryRange.values) {
      if (range == selectedRange || _charts.containsKey(range)) continue;
      unawaited(_chartFor(range).then((_) {}, onError: (Object _) {}));
    }
  }

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
    _weightUnit = s?.weightUnit ?? 'kg';
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

  Future<void> _loadEntries() async {
    try {
      final list = await _trackers.listWeights();
      if (mounted) setState(() => entries = list);
    } on Object {
      // Liste ikincil; grafik ve özet yine görünür.
    }
  }

  Future<void> onEditEntry(WeightEntry entry) async {
    final result = await AppDialogs.instance.showEditWeight(
      context,
      initialWeightKg: entry.weightKg,
    );
    if (result == null || !mounted) return;
    await _writeEntry(() => _trackers.updateWeight(entry.id, result.weightKg));
  }

  Future<void> onDeleteEntry(WeightEntry entry) async {
    final ok = await AppDialogs.instance.showDeleteWeight(context);
    if (ok != true || !mounted) return;
    await _writeEntry(() => _trackers.deleteWeight(entry.id));
  }

  Future<void> _writeEntry(Future<void> Function() call) async {
    try {
      await call();
      DataSync.afterWrite(profile: true);
      if (!mounted) return;
      await Future.wait([_loadEntries(), _refreshAfterWrite()]);
    } on Object catch (e) {
      if (mounted) AppSnackbar.showError(context, e);
    }
  }

  Future<void> _loadSummaryAndChart() async {
    unawaited(_loadEntries());
    setState(() => chartLoading = true);
    // Özet (BMI) ile grafik paralel — BMI kartı grafik bitmeden dolar.
    final summaryFuture = _trackers.getWeightSummary();
    final chartFuture = _chartFor(selectedRange);

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
      _prefetchOtherRanges();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => chartPoints = const []);
      AppSnackbar.showError(context, e);
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
    _currentBucketLabel = chart.buckets.lastOrNull?.label;
    final points = <_ChartPoint>[
      for (var i = 0; i < chart.buckets.length; i++)
        if (chart.buckets[i].weightKg case final kg?)
          _ChartPoint(
            label: chart.buckets[i].label,
            kg: kg,
            isCurrent: i == chart.buckets.length - 1,
          ),
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

  /// Bugünün kovasının etiketi (iyimser nokta için).
  String? _currentBucketLabel;

  /// Bugünün kovası doluysa değeri güncellenir, yoksa yeni nokta eklenir.
  /// Önceden son dolu kova (ör. geçen haftaki) eziliyordu.
  void _upsertTodayChartPoint(double kg) {
    final today = _ChartPoint(
      label: _currentBucketLabel ?? '—',
      kg: kg,
      isCurrent: true,
    );
    chartPoints = [
      for (final p in chartPoints)
        if (!p.isCurrent) p,
      today,
    ];
    selectedPointIndex = chartPoints.length - 1;
    final lo = chartPoints.map((p) => p.kg).reduce(math.min);
    final hi = chartPoints.map((p) => p.kg).reduce(math.max);
    chartYMin = math.min(chartYMin, lo - 2);
    chartYMax = math.max(chartYMax, hi + 2);
  }

  void onRangeChanged(_HistoryRange range) {
    final cached = _charts[range];
    setState(() {
      selectedRange = range;
      selectedPointIndex = 0;
      chartLoading = cached == null;
    });
    if (cached != null) {
      _applyChart(cached);
      return;
    }
    unawaited(() async {
      try {
        final chart = await _chartFor(range);
        if (!mounted || range != selectedRange) return;
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
      DataSync.afterWrite(profile: true);
      if (!mounted) return;
      // Sunucu özeti / grafik arka planda; ekran zaten güncel.
      unawaited(_refreshAfterWrite());
      unawaited(_loadEntries());
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
      _chartGeneration++;
      _charts.clear();
      // Yanıt gelene kadar sekme değişmiş olabilir: yanlış aralığın grafiği
      // gösterilmesin.
      final range = selectedRange;
      final chart = await _chartFor(range);
      if (!mounted || range != selectedRange) return;
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
      DataSync.afterWrite(profile: true);
      if (!mounted) return;
      setState(() {
        if (summary.goalKg != null) targetKg = summary.goalKg;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => targetKg = prev);
      AppSnackbar.showError(context, e);
    }
  }
}
