part of '../body_history_view.dart';

mixin BodyHistoryViewMixin on State<BodyHistoryView> {
  late double currentKg;
  late double startKg;
  late double targetKg;
  late double bmi;

  _HistoryRange selectedRange = _HistoryRange.day;
  int selectedPointIndex = 3;

  List<_ChartPoint> get chartPoints => switch (selectedRange) {
    _HistoryRange.day => const [
      _ChartPoint(label: '16', kg: 104.2),
      _ChartPoint(label: '17', kg: 103.8),
      _ChartPoint(label: '18', kg: 103.1),
      _ChartPoint(label: '19', kg: 102.5),
      _ChartPoint(label: '20', kg: 102.8),
      _ChartPoint(label: '21', kg: 102.2),
      _ChartPoint(label: '22', kg: 102.5),
    ],
    _HistoryRange.week => const [
      _ChartPoint(label: '1', kg: 108.0),
      _ChartPoint(label: '2', kg: 106.5),
      _ChartPoint(label: '3', kg: 105.2),
      _ChartPoint(label: '4', kg: 104.0),
      _ChartPoint(label: '5', kg: 103.0),
      _ChartPoint(label: '6', kg: 102.6),
      _ChartPoint(label: '7', kg: 102.5),
    ],
    _HistoryRange.month => const [
      _ChartPoint(label: 'O', kg: 112.2),
      _ChartPoint(label: 'Ş', kg: 110.0),
      _ChartPoint(label: 'M', kg: 108.4),
      _ChartPoint(label: 'N', kg: 106.8),
      _ChartPoint(label: 'M', kg: 105.0),
      _ChartPoint(label: 'H', kg: 103.6),
      _ChartPoint(label: 'T', kg: 102.5),
    ],
  };

  void initBodyHistory() {
    currentKg = widget.currentKg;
    startKg = widget.startKg;
    targetKg = widget.targetKg;
    bmi = widget.bmi;
  }

  void onRangeChanged(_HistoryRange range) {
    setState(() {
      selectedRange = range;
      selectedPointIndex = math.min(3, chartPoints.length - 1);
    });
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
      initialWeightKg: currentKg,
    );
    if (result == null || !mounted) return;

    final heightM = widget.heightCm / 100;
    setState(() {
      currentKg = result.weightKg;
      if (heightM > 0) {
        bmi = double.parse(
          (currentKg / (heightM * heightM)).toStringAsFixed(1),
        );
      }
    });
  }

  Future<void> onEditTargetTapped() async {
    final result = await AppDialogs.instance.showEditWeight(
      context,
      initialWeightKg: targetKg,
    );
    if (result == null || !mounted) return;
    setState(() => targetKg = result.weightKg);
  }
}
