part of '../doable_highlight_view.dart';

mixin DoableHighlightViewMixin on State<DoableHighlightView> {
  /// 8.5 gibi yarım kiloları korur; tam sayıysa ondalıksız yazar.
  String formatDeltaKg(double delta) {
    final rounded = (delta * 10).round() / 10;
    if ((rounded - rounded.roundToDouble()).abs() < 0.05) {
      return rounded.round().toString();
    }
    return rounded.toStringAsFixed(1);
  }

  /// Sol = mevcut, sağ = hedef.
  /// Yolculuk başında: kalan farkın mevcut kiloya oranı —
  /// fark büyüdükçe bar daha ileri gider (her zaman aynı yerde durmaz).
  double journeyProgressFor({
    required double currentKg,
    required double goalKg,
    double? startKg,
  }) {
    final start = startKg ?? currentKg;
    final traveled = OnboardingJourneyCard.progressBetween(
      startKg: start,
      currentKg: currentKg,
      goalKg: goalKg,
    );
    if (traveled > 0) return traveled;

    if (currentKg <= 0) return 0.1;
    final delta = (currentKg - goalKg).abs();
    return (delta / currentKg).clamp(0.06, 0.55);
  }

  void onContinue() {
    context.push(RoutePaths.diet.path);
  }
}
