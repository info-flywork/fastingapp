import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/domain/hunger/hunger_repository.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/hunger_tracker/hunger_result_type.dart';
import 'package:fastingapp/presentation/hunger_tracker/hunger_symptom.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

part 'mixin/hunger_history_log_view_mixin.dart';

enum HungerHistoryFilter { all, physical, emotional }

/// Tam kontrol — açlık geçmişi / hunger log listesi.
final class HungerHistoryLogView extends StatefulWidget {
  const HungerHistoryLogView({super.key});

  @override
  State<HungerHistoryLogView> createState() => _HungerHistoryLogViewState();
}

class _HungerHistoryLogViewState extends State<HungerHistoryLogView>
    with HungerHistoryLogViewMixin {
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ColorName.colorBodyPageBg,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: top + 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _CircleBackButton(onTap: () => context.pop()),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'hunger_history_log_page.title'.tr(),
                                style: AppTextStyles.hungerHistoryLogTitle,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'hunger_history_log_page.subtitle'.tr(),
                                style: AppTextStyles.hungerHistoryLogSubtitle,
                              ),
                            ],
                          ),
                        ),
                        // Alt %30 kesik
                        ClipRect(
                          child: Align(
                            alignment: Alignment.topCenter,
                            heightFactor: 0.75,
                            child: AppImages.hungerLog.image(
                              width: 190,
                              height: 190,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _WeekSummaryCard(
                      week: week,
                      filter: filter,
                      onFilterChanged: setFilter,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'hunger_history_log_page.today'.tr(),
                      style: AppTextStyles.hungerHistorySectionTitle,
                    ),
                    const SizedBox(height: 12),
                    if (loading)
                      const Center(child: CircularProgressIndicator())
                    else if (filteredEntries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'hunger_history_log_page.subtitle'.tr(),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.hungerHistoryLogSubtitle,
                        ),
                      )
                    else
                      for (final entry in filteredEntries) ...[
                        _EntryCard(item: entry),
                        const SizedBox(height: 12),
                      ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorName.colorWhite,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Transform.rotate(
              angle: math.pi,
              child: Assets.icons.solarAltArrowUpLineDuotoneRight.svg(
                width: 20,
                height: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _WeekSummaryCard extends StatelessWidget {
  const _WeekSummaryCard({
    required this.week,
    required this.filter,
    required this.onFilterChanged,
  });

  final List<HungerWeekDay> week;
  final HungerHistoryFilter filter;
  final ValueChanged<HungerHistoryFilter> onFilterChanged;

  static const _dayKeys = [
    'home.week_mon',
    'home.week_tue',
    'home.week_wed',
    'home.week_thu',
    'home.week_fri',
    'home.week_sat',
    'home.week_sun',
  ];

  /// Bu hafta (Pzt → Paz); oruç saati sunucudaki son 7 günden (gelecek gün "-").
  List<(String, String, String?)> get _days {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final byDate = {for (final d in week) d.date: d};
    return [
      for (var i = 0; i < 7; i++)
        () {
          final date = monday.add(Duration(days: i));
          final key =
              '${date.year.toString().padLeft(4, '0')}-'
              '${date.month.toString().padLeft(2, '0')}-'
              '${date.day.toString().padLeft(2, '0')}';
          final minutes = byDate[key]?.fastedMinutes ?? 0;
          return (
            _dayKeys[i].tr(),
            '${date.day}',
            minutes >= 60
                ? 'home.week_hours'.tr(args: ['${minutes ~/ 60}'])
                : null,
          );
        }(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final (i, d) in _days.indexed) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: _DayColumn(weekday: d.$1, day: d.$2, hours: d.$3),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          const _CheckInsBanner(),
          const SizedBox(height: 16),
          _FilterTabs(filter: filter, onChanged: onFilterChanged),
        ],
      ),
    );
  }
}

final class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.weekday,
    required this.day,
    required this.hours,
  });

  final String weekday;
  final String day;
  final String? hours;

  @override
  Widget build(BuildContext context) {
    final hasHours = hours != null;
    return Column(
      children: [
        Text(weekday, style: AppTextStyles.hungerHistoryWeekday),
        const SizedBox(height: 2),
        Text(day, style: AppTextStyles.hungerHistoryDay),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: hasHours
                ? ColorName.colorMealPositive
                : ColorName.colorHomeChipBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            hours ?? '-',
            textAlign: TextAlign.center,
            style: hasHours
                ? AppTextStyles.hungerHistoryHoursActive
                : AppTextStyles.hungerHistoryHoursIdle,
          ),
        ),
      ],
    );
  }
}

final class _CheckInsBanner extends StatelessWidget {
  const _CheckInsBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorName.colorHungerTipBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          AppImages.tree.image(width: 40, height: 40, fit: BoxFit.contain),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'hunger_history_log_page.checkins_today'.tr(
                    namedArgs: {'count': '3'},
                  ),
                  style: AppTextStyles.hungerHistoryCheckinsTitle,
                ),
                Text(
                  'hunger_history_log_page.checkins_breakdown'.tr(
                    namedArgs: {'physical': '2', 'emotional': '1'},
                  ),
                  style: AppTextStyles.hungerHistoryCheckinsSub,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.filter, required this.onChanged});

  final HungerHistoryFilter filter;
  final ValueChanged<HungerHistoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ColorName.colorBodyPageBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            offset: Offset(0, 1),
            blurRadius: 1,
            blurStyle: BlurStyle.inner,
          ),
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 2),
            blurRadius: 6,
            blurStyle: BlurStyle.inner,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabW = constraints.maxWidth / HungerHistoryFilter.values.length;
          final index = filter.index;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                left: index * tabW,
                top: 0,
                width: tabW,
                height: 32,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: ColorName.colorWhite,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D0C0C0D),
                        offset: Offset(0, 1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final item in HungerHistoryFilter.values)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(item),
                        child: SizedBox(
                          height: 32,
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                              style: filter == item
                                  ? AppTextStyles.bodySegmentActive
                                  : AppTextStyles.bodySegmentIdle,
                              child: Text(
                                'hunger_history_log_page.filter_${item.name}'
                                    .tr(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

final class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.item});

  final HungerCheckinItem item;

  @override
  Widget build(BuildContext context) {
    final isPhysical = item.typeEnum == HungerResultType.physical;
    final time = DateFormat.jm(context.locale.toString()).format(item.loggedAt);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          (isPhysical ? AppImages.leaf : AppImages.hearttt).image(
            width: 48,
            height: 48,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'hunger_log_page.hunger_type'.tr(),
                  style: AppTextStyles.hungerLogCardLabel,
                ),
                Text(
                  (isPhysical
                          ? 'hunger_log_page.type_physical'
                          : 'hunger_log_page.type_emotional')
                      .tr(),
                  style: AppTextStyles.hungerLogCardValue,
                ),
              ],
            ),
          ),
          // Kaydın saati (önceden hesaplanıp gösterilmiyordu).
          Text(time, style: AppTextStyles.hungerLogCardLabel),
        ],
      ),
    );
  }
}
