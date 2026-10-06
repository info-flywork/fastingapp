import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/hunger_tracker/hunger_result_type.dart';
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
                      filter: filter,
                      onFilterChanged: setFilter,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'hunger_history_log_page.today'.tr(),
                      style: AppTextStyles.hungerHistorySectionTitle,
                    ),
                    const SizedBox(height: 12),
                    for (final entry in filteredEntries) ...[
                      _EntryCard(type: entry),
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
  const _WeekSummaryCard({required this.filter, required this.onFilterChanged});

  final HungerHistoryFilter filter;
  final ValueChanged<HungerHistoryFilter> onFilterChanged;

  static const _days = <(String, String, String?)>[
    ('MON', '22', '10h'),
    ('TUE', '23', null),
    ('WED', '24', null),
    ('THU', '25', null),
    ('FRI', '26', null),
    ('SAT', '27', null),
    ('SUN', '28', null),
  ];

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
              for (var i = 0; i < _days.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: _DayColumn(
                    weekday: _days[i].$1,
                    day: _days[i].$2,
                    hours: _days[i].$3,
                  ),
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
  const _EntryCard({required this.type});

  final HungerResultType type;

  @override
  Widget build(BuildContext context) {
    final isPhysical = type == HungerResultType.physical;
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
        ],
      ),
    );
  }
}
