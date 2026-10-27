part of '../body_history_view.dart';

/// Kilo geçmişi: görünen her değer [WeightStore]'dan okunur. Ekran kendi
/// kopyasını tutmaz; yoldaki eski cevap yeni tartıyı geri alamaz, ana sayfa
/// kartıyla aynı değer görünür.
mixin BodyHistoryViewMixin on State<BodyHistoryView> {
  WeightStore get _store => getIt<WeightStore>();

  _HistoryRange selectedRange = _HistoryRange.day;

  int selectedPointIndex = 0;

  /// Bilinen ilk değerler (store'da özet yoksa ana sayfa özetinden).
  double? _seedCurrent;
  double? _seedStart;
  double? _seedGoal;

  double? get currentKg => _store.currentKg ?? _seedCurrent;

  double? get startKg => _store.summary?.startKg ?? _seedStart;

  double? get targetKg => _store.goalKg ?? _seedGoal;

  double? get heightCm => _store.summary?.heightCm ?? widget.heightCm;

  /// Yeni tartı onaylanmamışken BMI yerelde hesaplanır.
  double? get bmi =>
      (_store.pendingKg != null ? _bmiFor(currentKg) : null) ??
      _store.summary?.bmi ??
      _bmiFor(currentKg) ??
      widget.bmi;

  String get _apiRange => switch (selectedRange) {
    _HistoryRange.day => 'day',
    _HistoryRange.week => 'week',
    _HistoryRange.month => 'month',
  };

  WeightChart? get _chart => _store.chart(_apiRange);

  /// Grafik bu aralık için hiç yüklenmediyse iskelet.
  bool get chartLoading => _chart == null;

  /// Sunucu kovaları + onaylanmamış bugünkü tartı (son kova).
  List<_ChartPoint> get chartPoints {
    final chart = _chart;
    if (chart == null) return const [];
    final points = <_ChartPoint>[
      for (var i = 0; i < chart.buckets.length; i++)
        if (chart.buckets[i].weightKg case final kg?)
          _ChartPoint(
            label: chart.buckets[i].label,
            kg: kg,
            isCurrent: i == chart.buckets.length - 1,
          ),
    ];
    final pending = _store.pendingKg;
    if (pending == null) return points;
    // Bugünün kovası doluysa değeri güncellenir, yoksa yeni nokta eklenir.
    return [
      for (final p in points)
        if (!p.isCurrent) p,
      _ChartPoint(
        label: chart.buckets.lastOrNull?.label ?? '—',
        kg: pending,
        isCurrent: true,
      ),
    ];
  }

  double get chartYMin {
    final base = _chart?.yMin ?? 65;
    final points = chartPoints;
    if (points.isEmpty) return base;
    return math.min(base, points.map((p) => p.kg).reduce(math.min) - 2);
  }

  double get chartYMax {
    final base = _chart?.yMax ?? 120;
    final points = chartPoints;
    if (points.isEmpty) return base;
    return math.max(base, points.map((p) => p.kg).reduce(math.max) + 2);
  }

  void initBodyHistory() {
    _seedCurrent = widget.currentKg;
    _seedStart = widget.startKg;
    _seedGoal = widget.targetKg;
    _seedFromHomeSummary();
    _store.addListener(_onStoreChanged);
    unawaited(_load());
  }

  void disposeBodyHistory() {
    _store.removeListener(_onStoreChanged);
  }

  void _onStoreChanged() {
    if (!mounted) return;
    setState(() {
      final count = chartPoints.length;
      if (count == 0) {
        selectedPointIndex = 0;
      } else if (_store.pendingKg != null || selectedPointIndex >= count) {
        selectedPointIndex = count - 1;
      }
    });
  }

  void _seedFromHomeSummary() {
    final home = getIt<HomeBloc>().state;
    if (home is! HomeLoaded) return;
    final s = home.summary;
    _weightUnit = s?.weightUnit ?? 'kg';
    _seedCurrent ??= s?.weightCurrentKg;
    _seedStart ??= s?.weightStartKg;
    _seedGoal ??= s?.weightGoalKg;
  }

  double? _bmiFor(double? kg) {
    final h = heightCm;
    if (kg == null || h == null || h <= 0) return null;
    final m = h / 100;
    return double.parse((kg / (m * m)).toStringAsFixed(1));
  }

  /// Özet ve seçili grafik paralel; diğer aralıklar arka planda hazırlanır
  /// (sekme değişiminde iskelet görünmesin).
  Future<void> _load() async {
    unawaited(_store.loadSummary().catchError((Object _) {}));
    try {
      await _store.loadChart(_apiRange);
    } on Object catch (e) {
      if (mounted && _chart == null) AppSnackbar.showError(context, e);
    }
    for (final range in const ['day', 'week', 'month']) {
      if (range == _apiRange || _store.chart(range) != null) continue;
      unawaited(_store.loadChart(range).then((_) {}, onError: (Object _) {}));
    }
  }

  void onRangeChanged(_HistoryRange range) {
    setState(() {
      selectedRange = range;
      selectedPointIndex = math.max(0, chartPoints.length - 1);
    });
    if (_chart != null) return;
    unawaited(_store.loadChart(_apiRange).then((_) {}, onError: (Object _) {}));
  }

  void onPointSelected(int index) {
    setState(() => selectedPointIndex = index);
  }

  void onUpdateTapped() {
    unawaited(_openWeightDialog());
  }

  Future<void> _openWeightDialog() async {
    final result = await AppDialogs.instance.showEditWeight(
      context,
      initialWeightKg: currentKg ?? 70,
    );
    if (result == null || !mounted) return;
    try {
      // Anında görünür; onaylanınca taze özet / grafik gelir.
      await _store.addWeight(result.weightKg, visibleRange: _apiRange);
    } on Object catch (e) {
      if (mounted) AppSnackbar.showError(context, e);
    }
  }

  Future<void> onEditTargetTapped() async {
    final result = await AppDialogs.instance.showEditWeight(
      context,
      initialWeightKg: targetKg ?? currentKg ?? 70,
    );
    if (result == null || !mounted) return;
    try {
      await _store.setGoal(result.weightKg);
    } on Object catch (e) {
      if (mounted) AppSnackbar.showError(context, e);
    }
  }
}
