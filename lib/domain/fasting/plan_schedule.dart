import 'package:fastingapp/domain/fasting/plan_catalog_repository.dart';
import 'package:flutter/foundation.dart';

/// Plan detayının saati: katalogdaki oruç/yeme süresi + kartın zamanlaması.
///
/// Yay, "oruç biter / başlar" ve haftalık çubuklar aynı [eatMinutes] ve
/// [startMinutes] değerini kullanır. Böylece 15-9 akşam kartı 08:00–17:00,
/// kahvaltı kartı 12:00–21:00 olur.
@immutable
final class ResolvedPlanSchedule {
  const ResolvedPlanSchedule({
    required this.fastMinutes,
    required this.eatMinutes,
    required this.startMinutes,
  });

  final int fastMinutes;
  final int eatMinutes;

  /// Yeme penceresinin başlangıcı, günün dakikası (0–1439).
  final int startMinutes;

  int get endMinutes => (startMinutes + eatMinutes) % (24 * 60);

  int get fastHours => (fastMinutes / 60).round();
  int get eatHours => (eatMinutes / 60).round();
  int get startHour => startMinutes ~/ 60;
  int get startMinute => startMinutes % 60;
  int get endHour => endMinutes ~/ 60;
  int get endMinute => endMinutes % 60;
}

/// `skip_breakfast` / `skipBreakfast` → `skipBreakfast`.
String? canonicalPlanTiming(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final compact = raw.toLowerCase().replaceAll('_', '');
  return switch (compact) {
    'skipbreakfast' => 'skipBreakfast',
    'skipdinner' => 'skipDinner',
    'earlywindow' => 'earlyWindow',
    'latewindow' => 'lateWindow',
    'custom' => 'custom',
    _ => null,
  };
}

/// Zamanlamanın varsayılan yeme başlangıcı (iş kuralı).
/// Kahvaltı 12:00, akşam 08:00, erken 07:00, geç 14:00.
int eatStartMinutesForTiming(String? timing) {
  return switch (canonicalPlanTiming(timing)) {
    'skipDinner' => 8 * 60,
    'earlyWindow' => 7 * 60,
    'lateWindow' => 14 * 60,
    _ => 12 * 60,
  };
}

/// Seçilen kart + katalog + (varsa) kayıtlı plan → tek pencere.
///
/// Süre her zaman planın yeme saatidir. Kayıtlı pencere yalnızca aynı kart
/// (aynı kod ve zamanlama) ve süre plana uyuyorsa başlangıcı kaydırır.
ResolvedPlanSchedule resolvePlanSchedule({
  required int fallbackFastHours,
  required int fallbackEatHours,
  String? cardTiming,
  String? planCode,
  PlanCatalogEntry? catalog,
  PlanCatalogDetail? detail,
  String? currentPlanCode,
  String? currentTiming,
  String? currentEatStart,
  String? currentEatEnd,
}) {
  final eatHours = _eatHours(
    fallbackFastHours: fallbackFastHours,
    fallbackEatHours: fallbackEatHours,
    catalog: catalog,
    detail: detail,
  );
  final eatMinutes = eatHours * 60;
  final fastMinutes = 24 * 60 - eatMinutes;

  final selected =
      canonicalPlanTiming(cardTiming) ??
      canonicalPlanTiming(detail?.defaultTiming) ??
      canonicalPlanTiming(catalog?.defaultTiming) ??
      'skipBreakfast';

  var start = eatStartMinutesForTiming(selected);
  final defaultTiming = canonicalPlanTiming(
    detail?.defaultTiming ?? catalog?.defaultTiming,
  );
  if (defaultTiming == null || defaultTiming == selected) {
    final serverStart = _parseMinutes(
      detail?.defaultEatStart ?? catalog?.defaultEatStart,
    );
    if (serverStart != null) start = serverStart;
    final exampleStart = _parseMinutes(detail?.exampleStart);
    final exampleEnd = _parseMinutes(detail?.exampleEnd);
    if (exampleStart != null &&
        exampleEnd != null &&
        _durationMinutes(exampleStart, exampleEnd) == eatMinutes) {
      start = exampleStart;
    }
  }

  if (planCode != null &&
      currentPlanCode == planCode &&
      _sameCard(selected, canonicalPlanTiming(currentTiming), defaultTiming)) {
    final savedStart = _parseMinutes(currentEatStart);
    final savedEnd = _parseMinutes(currentEatEnd);
    if (savedStart != null &&
        savedEnd != null &&
        _durationMinutes(savedStart, savedEnd) == eatMinutes) {
      start = savedStart;
    }
  }

  return ResolvedPlanSchedule(
    fastMinutes: fastMinutes,
    eatMinutes: eatMinutes,
    startMinutes: start,
  );
}

int _eatHours({
  required int fallbackFastHours,
  required int fallbackEatHours,
  PlanCatalogEntry? catalog,
  PlanCatalogDetail? detail,
}) {
  final fromServer = _hours(detail?.eatHours) ?? _hours(catalog?.eatHours);
  if (fromServer != null) return fromServer;
  final fast = _hours(detail?.fastHours) ?? _hours(catalog?.fastHours);
  if (fast != null) return 24 - fast;
  final fallbackEat = _hours(fallbackEatHours);
  if (fallbackEat != null) return fallbackEat;
  final fallbackFast = _hours(fallbackFastHours);
  if (fallbackFast != null) return 24 - fallbackFast;
  return 8;
}

int? _hours(int? value) {
  if (value == null || value <= 0 || value >= 24) return null;
  return value;
}

bool _sameCard(String selected, String? current, String? defaultTiming) {
  if (current == null) return false;
  if (current == selected) return true;
  if (current == 'custom') {
    return selected == (defaultTiming ?? 'skipBreakfast');
  }
  return false;
}

int? _parseMinutes(String? hm) {
  if (hm == null || hm.isEmpty) return null;
  final parts = hm.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
    return null;
  }
  return h * 60 + m;
}

int _durationMinutes(int start, int end) {
  var diff = end - start;
  if (diff <= 0) diff += 24 * 60;
  return diff;
}
