import 'package:fastingapp/generated/assets.gen.dart';

/// Bardak boyutu (ml) → reminder / water view ortak ikonları.
abstract final class WaterGlassIcons {
  static AssetGenImage forMl(int ml) {
    return switch (ml) {
      50 => Assets.images.waterGlass50,
      100 => Assets.images.waterGlass100,
      200 => Assets.images.waterGlass200,
      300 => Assets.images.waterBottle300,
      500 => Assets.images.waterBottle500,
      _ => forMl(_nearestPreset(ml)),
    };
  }

  static int _nearestPreset(int ml) {
    const presets = <int>[50, 100, 200, 300, 500];
    var nearest = presets.first;
    var bestDist = (ml - nearest).abs();
    for (final p in presets.skip(1)) {
      final dist = (ml - p).abs();
      if (dist < bestDist) {
        bestDist = dist;
        nearest = p;
      }
    }
    return nearest;
  }
}
