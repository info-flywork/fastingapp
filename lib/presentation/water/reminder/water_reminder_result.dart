import 'package:flutter/foundation.dart';

/// Water Reminder kaydet sonucu — [WaterView]'a geri döner.
@immutable
final class WaterReminderResult {
  const WaterReminderResult({
    required this.dailyGoalMl,
    required this.glassSizeMl,
    required this.unit,
    required this.notificationsEnabled,
    this.customGlassSizes = const [],
  });

  final int dailyGoalMl;
  final int glassSizeMl;
  final String unit;
  final bool notificationsEnabled;
  final List<int> customGlassSizes;
}

/// Water Reminder açılış argümanları.
@immutable
final class WaterReminderArgs {
  const WaterReminderArgs({
    required this.dailyGoalMl,
    required this.glassSizeMl,
    this.unit = 'ml',
    this.notificationsEnabled = false,
    this.customGlassSizes = const [],
  });

  final int dailyGoalMl;
  final int glassSizeMl;
  final String unit;
  final bool notificationsEnabled;
  final List<int> customGlassSizes;
}
