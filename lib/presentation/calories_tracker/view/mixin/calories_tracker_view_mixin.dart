part of '../calories_tracker_view.dart';

mixin CaloriesTrackerViewMixin on State<CaloriesTrackerView> {
  static const _manualStep = 50;
  static const _manualMin = 0;
  static const _manualMax = 5000;

  int eatenKcal = 3143;
  int overKcal = 273;
  int manualKcal = 500;

  void onManualDecrement() {
    if (manualKcal <= _manualMin) return;
    setState(() {
      manualKcal = (manualKcal - _manualStep).clamp(_manualMin, _manualMax);
    });
  }

  void onManualIncrement() {
    if (manualKcal >= _manualMax) return;
    setState(() {
      manualKcal = (manualKcal + _manualStep).clamp(_manualMin, _manualMax);
    });
  }

  void onProteinTracker() {}

  void onCalculate() {}
}
