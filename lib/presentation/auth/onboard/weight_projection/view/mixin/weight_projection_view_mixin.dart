part of '../weight_projection_view.dart';

mixin WeightProjectionViewMixin on State<WeightProjectionView> {
  DateTime projectedTargetDate({
    required double currentKg,
    required double goalKg,
    required double weeklyLossKg,
  }) {
    final delta = (currentKg - goalKg).abs();
    final weeks = weeklyLossKg <= 0 ? 12.0 : delta / weeklyLossKg;
    final days = (weeks * 7).ceil().clamp(7, 365 * 2);
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: days));
  }

  void onContinue() {
    context.push(RoutePaths.goodCompany.path);
  }
}
