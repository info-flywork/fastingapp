part of '../home_view.dart';

/// Haftanın günleri şeridi (Pzt–Paz) — Figma week strip.
final class HomeWeekStrip extends StatelessWidget {
  const HomeWeekStrip({this.days = const [], super.key});

  final List<SummaryWeekDay> days;

  static const _dayKeys = [
    'home.week_mon',
    'home.week_tue',
    'home.week_wed',
    'home.week_thu',
    'home.week_fri',
    'home.week_sat',
    'home.week_sun',
  ];

  /// Seçili günden sağa her adımda soluklaşma.
  static double _fadeForDistance(int stepsToRight) {
    if (stepsToRight <= 0) return 1;
    // 1→0.92, 2→0.82, 3→0.62, 4→0.45, 5→0.30, 6→0.18
    const curve = <double>[1, 0.92, 0.82, 0.62, 0.45, 0.30, 0.18];
    if (stepsToRight >= curve.length) return curve.last;
    return curve[stepsToRight];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    var selectedIndex = today.weekday - 1;
    if (days.isNotEmpty) {
      final idx = days.indexWhere((d) => d.isToday);
      if (idx >= 0) selectedIndex = idx;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: _DayCell(
                dayKey: _dayKeys[i],
                date: monday.add(Duration(days: i)),
                selected: i == selectedIndex,
                label: _labelForDay(i),
                textOpacity: _fadeForDistance(i - selectedIndex),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Oruç saati; haftalık planda işaretlenmiş azaltılmış gün "✓".
  String? _labelForDay(int index) {
    if (days.length != 7 || index >= days.length) return null;
    final day = days[index];
    if (day.isFuture) return null;
    if (day.fastedHours > 0) {
      // Kayıt planı aşsa da şerit plan saatini geçmez (16:8 → en fazla 16s).
      final capMinutes =
          getIt<FastingSessionCubit>().state.plan?.fastMinutes ?? 0;
      final capHours = capMinutes > 0 ? capMinutes ~/ 60 : day.fastedHours;
      final hours = day.fastedHours > capHours ? capHours : day.fastedHours;
      return 'home.week_hours'.tr(args: ['$hours']);
    }
    if (day.dayType == 'reduced' && day.checkin == 'done') return '✓';
    return null;
  }
}

final class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.dayKey,
    required this.date,
    required this.selected,
    required this.textOpacity,
    this.label,
  });

  final String dayKey;
  final DateTime date;
  final bool selected;
  final double textOpacity;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final dayColor = selected
        ? ColorName.colorBrandStrong
        : ColorName.colorSubtitle.withValues(alpha: 0.5);
    const dateColor = ColorName.colorTitle;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: textOpacity,
          child: Container(
            width: 40,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: selected ? ColorName.colorWhite : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: ColorName.colorBlack.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dayKey.tr(),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  style: AppTextStyles.homeWeekDay.copyWith(color: dayColor),
                ),
                const SizedBox(height: 4),
                Text(
                  '${date.day}',
                  style: AppTextStyles.homeWeekDate.copyWith(color: dateColor),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 40,
          height: 18,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: label != null
                ? ColorName.colorPremiumGradientStart
                : ColorName.colorWeekPill,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label ?? '-',
            style: label != null
                ? AppTextStyles.homeWeekHours
                : AppTextStyles.homeWeekHours.copyWith(
                    color: ColorName.colorSubtitle.withValues(alpha: 0.4),
                  ),
          ),
        ),
      ],
    );
  }
}
