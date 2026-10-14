import 'package:flutter/foundation.dart';

/// Haftalık plan günü tipi (backend `weeklySchedule[].type`).
enum WeeklyDayType { fast, normal, reduced }

/// Haftalık programın bir günü. [dow]: 1 = Pazartesi … 7 = Pazar.
@immutable
final class WeeklyDay {
  const WeeklyDay({
    required this.dow,
    required this.type,
    this.fastMinutes,
    this.kcal,
  });

  factory WeeklyDay.fromJson(Map<String, dynamic> json) => WeeklyDay(
    dow: (json['dow'] as num?)?.toInt() ?? 1,
    type: switch (json['type']) {
      'fast' => WeeklyDayType.fast,
      'reduced' => WeeklyDayType.reduced,
      _ => WeeklyDayType.normal,
    },
    fastMinutes: (json['fastMinutes'] as num?)?.toInt(),
    kcal: (json['kcal'] as num?)?.toInt(),
  );

  final int dow;
  final WeeklyDayType type;
  final int? fastMinutes;
  final int? kcal;

  Map<String, dynamic> toJson() => {
    'dow': dow,
    'type': type.name,
    if (type == WeeklyDayType.fast && fastMinutes != null)
      'fastMinutes': fastMinutes,
    if (type == WeeklyDayType.reduced && kcal != null) 'kcal': kcal,
  };

  WeeklyDay copyWith({WeeklyDayType? type, int? fastMinutes}) => WeeklyDay(
    dow: dow,
    type: type ?? this.type,
    fastMinutes: fastMinutes ?? this.fastMinutes,
    kcal: kcal,
  );

  @override
  bool operator ==(Object other) =>
      other is WeeklyDay &&
      other.dow == dow &&
      other.type == type &&
      other.fastMinutes == fastMinutes &&
      other.kcal == kcal;

  @override
  int get hashCode => Object.hash(dow, type, fastMinutes, kcal);
}

/// Haftalık plan türleri (backend `scheduleType`).
enum WeeklyKind { weeklyReduced, alternateDay, selectedDays, customWeekly }

/// Haftalık plan kuralları — sunucu `plans.rules.js` (`resolveWeeklySchedule`)
/// ile aynı; ekranda kaydetmeden önce uyarı gösterilsin diye.
abstract final class WeeklyRules {
  static const reducedKcal = 500;
  static const defaultFastMinutes = 16 * 60;

  /// Haftalık plan kodları (Planlar sekmesi sırası).
  static const codes = [
    '5_2',
    '6_1',
    'alternate_day',
    'crescendo',
    'custom_weekly',
  ];

  static WeeklyKind? kindOf(String? planCode) => switch (planCode) {
    '5_2' || '6_1' => WeeklyKind.weeklyReduced,
    'alternate_day' => WeeklyKind.alternateDay,
    'crescendo' => WeeklyKind.selectedDays,
    'custom_weekly' => WeeklyKind.customWeekly,
    _ => null,
  };

  static bool isWeekly(String? planCode) => kindOf(planCode) != null;

  static int reducedDaysOf(String planCode) => planCode == '6_1' ? 1 : 2;

  /// Fast günü süre aralığı (dakika).
  static (int, int) fastRange(WeeklyKind kind) => switch (kind) {
    WeeklyKind.selectedDays => (12 * 60, 16 * 60),
    _ => (12 * 60, 23 * 60),
  };

  /// Katalog şablonu (backend `catalog.service.js` → `weeklyTemplate`).
  static List<WeeklyDay> template(String planCode) {
    List<WeeklyDay> days(WeeklyDay Function(int dow) f) => [
      for (var d = 1; d <= 7; d++) f(d),
    ];
    WeeklyDay reduced(int d) =>
        WeeklyDay(dow: d, type: WeeklyDayType.reduced, kcal: reducedKcal);
    WeeklyDay normal(int d) => WeeklyDay(dow: d, type: WeeklyDayType.normal);
    WeeklyDay fast(int d, int m) =>
        WeeklyDay(dow: d, type: WeeklyDayType.fast, fastMinutes: m);
    return switch (kindOf(planCode)) {
      WeeklyKind.weeklyReduced => days(
        (d) => (planCode == '5_2' ? [1, 4] : [3]).contains(d)
            ? reduced(d)
            : normal(d),
      ),
      WeeklyKind.alternateDay => days((d) => d.isOdd ? reduced(d) : normal(d)),
      WeeklyKind.selectedDays => days(
        (d) => [1, 3, 5].contains(d) ? fast(d, 14 * 60) : normal(d),
      ),
      WeeklyKind.customWeekly => days((d) => fast(d, defaultFastMinutes)),
      null => const [],
    };
  }

  /// Ardışık "özel gün" var mı; [wrap]: Pazar → Pazartesi de ardışık.
  static bool hasConsecutive(Iterable<int> dows, {bool wrap = true}) {
    final set = dows.toSet();
    return set.any(
      (d) => d == 7 ? wrap && set.contains(1) : set.contains(d + 1),
    );
  }

  /// Geçersizse çeviri anahtarı (`plans.weekly_error_*`), geçerliyse null.
  static String? validate(String planCode, List<WeeklyDay> days) {
    final kind = kindOf(planCode);
    if (kind == null || days.length != 7) return 'plans.weekly_error_days';
    Iterable<int> of(WeeklyDayType t) =>
        days.where((d) => d.type == t).map((d) => d.dow);
    switch (kind) {
      case WeeklyKind.weeklyReduced:
        if (of(WeeklyDayType.fast).isNotEmpty) return 'plans.weekly_error_days';
        final reduced = of(WeeklyDayType.reduced);
        if (reduced.length != reducedDaysOf(planCode)) {
          return 'plans.weekly_error_reduced_count';
        }
        if (hasConsecutive(reduced)) return 'plans.weekly_error_consecutive';
      case WeeklyKind.alternateDay:
        if (of(WeeklyDayType.fast).isNotEmpty) return 'plans.weekly_error_days';
        final reduced = of(WeeklyDayType.reduced);
        if (reduced.length < 3 ||
            reduced.length > 4 ||
            hasConsecutive(reduced, wrap: false)) {
          return 'plans.weekly_error_alternate';
        }
      case WeeklyKind.selectedDays:
        if (of(WeeklyDayType.reduced).isNotEmpty) {
          return 'plans.weekly_error_days';
        }
        final fasts = of(WeeklyDayType.fast);
        if (fasts.length < 2 || fasts.length > 3) {
          return 'plans.weekly_error_fast_count';
        }
        if (hasConsecutive(fasts)) return 'plans.weekly_error_consecutive';
      case WeeklyKind.customWeekly:
        break;
    }
    final (min, max) = fastRange(kind);
    for (final d in days.where((d) => d.type == WeeklyDayType.fast)) {
      final m = d.fastMinutes ?? defaultFastMinutes;
      if (m < min || m > max) return 'plans.weekly_error_hours';
    }
    return null;
  }
}
