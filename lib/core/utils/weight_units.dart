import 'package:easy_localization/easy_localization.dart';

/// Kilo gösterimi kullanıcının birimiyle (`kg` | `lb`); veri hep kg.
abstract final class WeightUnits {
  static const kgToLb = 2.2046226218;

  static bool isLb(String unit) => unit == 'lb';

  /// Birimsiz sayı, bir ondalık ("72", "158.7").
  static String amount(double kg, String unit) {
    final v = isLb(unit) ? kg * kgToLb : kg;
    final rounded = (v * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? '${rounded.toInt()}'
        : rounded.toStringAsFixed(1);
  }

  static String label(String unit) =>
      (isLb(unit) ? 'home.weight_unit_lb' : 'home.weight_unit').tr();
}
