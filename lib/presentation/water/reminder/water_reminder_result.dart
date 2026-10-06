import 'package:flutter/foundation.dart';

/// Water Reminder kaydet sonucu — [WaterView]'a geri döner.
@immutable
final class WaterReminderResult {
  const WaterReminderResult({
    required this.dailyGoalMl,
    required this.glassSizeMl,
    required this.unit,
    required this.notificationsEnabled,
  });

  final int dailyGoalMl;
  final int glassSizeMl;
  final String unit;
  final bool notificationsEnabled;
}

/// Water Reminder açılış argümanları.
@immutable
final class WaterReminderArgs {
  const WaterReminderArgs({
    required this.dailyGoalMl,
    required this.glassSizeMl,
    this.unit = 'ml',
    this.notificationsEnabled = false,
  });

  final int dailyGoalMl;
  final int glassSizeMl;
  final String unit;
  final bool notificationsEnabled;
}
