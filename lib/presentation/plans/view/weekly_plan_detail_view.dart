import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/domain/fasting/weekly_schedule.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/plans/plans_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Haftalık plan detayı nav argümanları. [current]: kullanıcının bu plandaki
/// mevcut programı (yoksa katalog şablonu).
@immutable
final class WeeklyPlanDetailArgs {
  const WeeklyPlanDetailArgs({required this.plan, this.current});

  final PlansCardData plan;
  final List<WeeklyDay>? current;
}

/// Haftalık plan (5:2, 6:1, gün aşırı, Crescendo, özel hafta): günleri seç,
/// "Planı başlat" → seçilen 7 günlük program döner.
final class WeeklyPlanDetailView extends StatefulWidget {
  const WeeklyPlanDetailView({required this.args, super.key});

  final WeeklyPlanDetailArgs args;

  @override
  State<WeeklyPlanDetailView> createState() => _WeeklyPlanDetailViewState();
}

class _WeeklyPlanDetailViewState extends State<WeeklyPlanDetailView> {
  late List<WeeklyDay> _days;
  late int _fastMinutes;

  String get _code => widget.args.plan.planCode;
  WeeklyKind get _kind => WeeklyRules.kindOf(_code)!;

  bool get _hasFastDays =>
      _kind == WeeklyKind.selectedDays || _kind == WeeklyKind.customWeekly;

  @override
  void initState() {
    super.initState();
    final current = widget.args.current;
    _days = current != null && current.length == 7
        ? List.of(current)
        : WeeklyRules.template(_code);
    _fastMinutes =
        _days
            .where((d) => d.type == WeeklyDayType.fast)
            .map((d) => d.fastMinutes)
            .whereType<int>()
            .firstOrNull ??
        (_kind == WeeklyKind.selectedDays ? 14 * 60 : 16 * 60);
  }

  /// Bir güne dokununca plan türüne göre sıradaki tip.
  void _onDayTapped(int index) {
    final day = _days[index];
    final next = switch (_kind) {
      WeeklyKind.weeklyReduced || WeeklyKind.alternateDay =>
        day.type == WeeklyDayType.reduced
            ? WeeklyDayType.normal
            : WeeklyDayType.reduced,
      WeeklyKind.selectedDays =>
        day.type == WeeklyDayType.fast
            ? WeeklyDayType.normal
            : WeeklyDayType.fast,
      WeeklyKind.customWeekly => switch (day.type) {
        WeeklyDayType.normal => WeeklyDayType.fast,
        WeeklyDayType.fast => WeeklyDayType.reduced,
        WeeklyDayType.reduced => WeeklyDayType.normal,
      },
    };
    HapticFeedback.selectionClick();
    setState(() {
      _days[index] = WeeklyDay(
        dow: day.dow,
        type: next,
        fastMinutes: next == WeeklyDayType.fast ? _fastMinutes : null,
        kcal: next == WeeklyDayType.reduced ? WeeklyRules.reducedKcal : null,
      );
    });
  }

  void _changeHours(int deltaMinutes) {
    final (min, max) = WeeklyRules.fastRange(_kind);
    setState(() {
      _fastMinutes = (_fastMinutes + deltaMinutes).clamp(min, max);
      _days = [
        for (final d in _days)
          d.type == WeeklyDayType.fast
              ? d.copyWith(fastMinutes: _fastMinutes)
              : d,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final error = WeeklyRules.validate(_code, _days);
    final (minFast, maxFast) = WeeklyRules.fastRange(_kind);
    final plan = widget.args.plan;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ColorName.colorWhite,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    _BackButton(onTap: () => context.pop()),
                    Expanded(
                      child: Text(
                        plan.displayTitle,
                        style: AppTextStyles.planDetailTitle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  children: [
                    Text(
                      'plans.weekly_desc_$_code'.tr(),
                      style: AppTextStyles.optionSubtitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'plans.weekly_hint_${_kind.name}'.tr(),
                      style: AppTextStyles.planDetailAxis,
                    ),
                    const SizedBox(height: 20),
                    for (var i = 0; i < _days.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _DayRow(day: _days[i], onTap: () => _onDayTapped(i)),
                    ],
                    if (_hasFastDays) ...[
                      const SizedBox(height: 24),
                      _HoursStepper(
                        minutes: _fastMinutes,
                        onMinus: _fastMinutes > minFast
                            ? () => _changeHours(-60)
                            : null,
                        onPlus: _fastMinutes < maxFast
                            ? () => _changeHours(60)
                            : null,
                      ),
                    ],
                    if (error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        error.tr(),
                        style: AppTextStyles.planDetailAxis.copyWith(
                          color: ColorName.colorOptionNegative,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, math.max(bottom, 16)),
                child: AppButton(
                  label: 'plans.detail_start'.tr(),
                  isEnabled: error == null,
                  onPressed: () => context.pop(List<WeeklyDay>.of(_days)),
                  decoration: AppButtonDecoration.primary(),
                  showIcon: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gün etiketi + tip hapı (oruç / 500 kcal / serbest).
final class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.onTap});

  final WeeklyDay day;
  final VoidCallback onTap;

  static const dayKeys = [
    'plans.detail_mon',
    'plans.detail_tue',
    'plans.detail_wed',
    'plans.detail_thu',
    'plans.detail_fri',
    'plans.detail_sat',
    'plans.detail_sun',
  ];

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String label) = switch (day.type) {
      WeeklyDayType.fast => (
        ColorName.colorPlanFastingBar,
        ColorName.colorTitle,
        'plans.weekly_day_fast'.tr(
          args: ['${((day.fastMinutes ?? 960) / 60).round()}'],
        ),
      ),
      WeeklyDayType.reduced => (
        ColorName.colorPlanChipBreakfastBg,
        ColorName.colorPlanChipBreakfastText,
        'plans.weekly_day_reduced'.tr(args: ['${day.kcal ?? 500}']),
      ),
      WeeklyDayType.normal => (
        ColorName.colorProfileBack,
        ColorName.colorTitle.withValues(alpha: 0.6),
        'plans.weekly_day_normal'.tr(),
      ),
    };
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            dayKeys[day.dow - 1].tr(),
            style: AppTextStyles.planDetailAxis,
          ),
        ),
        Expanded(
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(
                  label,
                  style: AppTextStyles.plansChipLabel.copyWith(color: fg),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

final class _HoursStepper extends StatelessWidget {
  const _HoursStepper({
    required this.minutes,
    required this.onMinus,
    required this.onPlus,
  });

  final int minutes;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, VoidCallback? onTap) => Material(
      color: ColorName.colorProfileBack,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            color: onTap == null
                ? ColorName.colorBlack.withValues(alpha: 0.2)
                : ColorName.colorTitle,
          ),
        ),
      ),
    );
    return Row(
      children: [
        Expanded(
          child: Text(
            'plans.weekly_fast_hours'.tr(args: ['${minutes ~/ 60}']),
            style: AppTextStyles.planOptionTitle,
          ),
        ),
        button(Icons.remove_rounded, onMinus),
        const SizedBox(width: 12),
        button(Icons.add_rounded, onPlus),
      ],
    );
  }
}

final class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorName.colorProfileBack,
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
              child: Assets.icons.solarAltArrowLeftLinear.svg(),
            ),
          ),
        ),
      ),
    );
  }
}
