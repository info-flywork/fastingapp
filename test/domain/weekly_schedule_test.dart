import 'package:fastingapp/domain/fasting/weekly_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

List<WeeklyDay> _days(Map<int, WeeklyDayType> special, {int? minutes}) => [
  for (var d = 1; d <= 7; d++)
    WeeklyDay(
      dow: d,
      type: special[d] ?? WeeklyDayType.normal,
      fastMinutes: special[d] == WeeklyDayType.fast ? minutes : null,
    ),
];

void main() {
  test('şablonlar kendi kurallarından geçer', () {
    for (final code in WeeklyRules.codes) {
      expect(
        WeeklyRules.validate(code, WeeklyRules.template(code)),
        isNull,
        reason: code,
      );
    }
  });

  test('5:2 — tam 2 azaltılmış, ardışık değil (Pazar→Pazartesi dahil)', () {
    const r = WeeklyDayType.reduced;
    expect(WeeklyRules.validate('5_2', _days({1: r})), isNotNull);
    expect(WeeklyRules.validate('5_2', _days({1: r, 2: r})), isNotNull);
    expect(WeeklyRules.validate('5_2', _days({7: r, 1: r})), isNotNull);
    expect(WeeklyRules.validate('5_2', _days({2: r, 5: r})), isNull);
  });

  test('gün aşırı — Pazar/Pazartesi ardışık sayılmaz', () {
    const r = WeeklyDayType.reduced;
    expect(
      WeeklyRules.validate('alternate_day', _days({1: r, 3: r, 5: r, 7: r})),
      isNull,
    );
    expect(
      WeeklyRules.validate('alternate_day', _days({1: r, 2: r, 5: r})),
      isNotNull,
    );
  });

  test('crescendo — 2-3 gün, 12-16 saat', () {
    const f = WeeklyDayType.fast;
    expect(
      WeeklyRules.validate('crescendo', _days({1: f, 4: f}, minutes: 840)),
      isNull,
    );
    expect(
      WeeklyRules.validate('crescendo', _days({1: f, 4: f}, minutes: 1080)),
      'plans.weekly_error_hours',
    );
    expect(
      WeeklyRules.validate('crescendo', _days({1: f}, minutes: 840)),
      'plans.weekly_error_fast_count',
    );
  });
}
