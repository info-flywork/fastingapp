import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/generated/app_images.g.dart';

/// Bardak boyutu (ml) → reminder / water view ortak ikonları.
abstract final class WaterGlassIcons {
  static AppImageAsset forMl(int ml) {
    return switch (ml) {
      50 => AppImages.waterGlass50,
      100 => AppImages.waterGlass100,
      200 => AppImages.waterGlass200,
      300 => AppImages.waterBottle300,
      500 => AppImages.waterBottle500,
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
