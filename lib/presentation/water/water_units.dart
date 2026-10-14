import 'package:easy_localization/easy_localization.dart';

/// Su miktarının seçili birimde gösterimi. Sunucu ve hesaplar hep ml;
/// kullanıcı oz seçtiyse ekranda oz (önceden her yerde "ml" yazıyordu).
abstract final class WaterUnits {
  static const mlPerOz = 29.5735295625;

  static bool isOz(String unit) => unit == 'oz';

  /// Birimsiz sayı: ml tam sayı, oz bir ondalık ("8.5", "8").
  static String amount(int ml, String unit) {
    if (!isOz(unit)) return '$ml';
    final oz = (ml / mlPerOz * 10).round() / 10;
    return oz == oz.roundToDouble() ? '${oz.toInt()}' : '$oz';
  }

  static String label(String unit) =>
      (isOz(unit) ? 'water_reminder.unit_oz' : 'water_reminder.unit_ml').tr();

  static String withUnit(int ml, String unit) =>
      '${amount(ml, unit)} ${label(unit)}';
}
