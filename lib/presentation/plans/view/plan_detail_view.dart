import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/core/widgets/horseshoe_arc.dart';
import 'package:fastingapp/domain/fasting/plan_catalog_repository.dart';
import 'package:fastingapp/domain/fasting/plan_schedule.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/fasting/bloc/fasting_session_cubit.dart';
import 'package:fastingapp/presentation/plans/plan_detail_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

part 'mixin/plan_detail_view_mixin.dart';

const _kHeaderHeight = 56.0;

/// Oruç planı detay — haftalık beginner plan ekranı.
final class PlanDetailView extends StatefulWidget {
  const PlanDetailView({required this.args, super.key});

  final PlanDetailArgs args;

  @override
  State<PlanDetailView> createState() => _PlanDetailViewState();
}

class _PlanDetailViewState extends State<PlanDetailView>
    with PlanDetailViewMixin {
  @override
  void initState() {
    super.initState();
    initPlanDetail(widget.args);
    loadCatalogSchedule();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final plan = args.plan;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ColorName.colorWhite,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SizedBox(
                height: _kHeaderHeight,
                width: double.infinity,
                child: _PlanDetailHeader(titleKey: args.pageTitleKey),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    children: [
                      _PlanArcSection(
                        title: plan.title,
                        chipKey: plan.chipKey,
                        chipBg: plan.chipBg,
                        chipFg: plan.chipFg,
                        eatShare: eatShare,
                        eatStartFraction:
                            (eatStartHour * 60 + eatStartMinute) / (24 * 60),
                        endsLabel: formatTime(eatStartHour, eatStartMinute),
                        startsLabel: formatTime(eatEndHour, eatEndMinute),
                        onChange: onChangeTapped,
                      ),
                      const SizedBox(height: 56),
                      _WeeklySchedule(
                        eatStartHour: eatStartHour,
                        eatStartMinute: eatStartMinute,
                        eatEndHour: eatEndHour,
                        eatEndMinute: eatEndMinute,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, bottom),
                child: AppButton(
                  label: 'plans.detail_start'.tr(),
                  onPressed: onStartPlanTapped,
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

final class _PlanDetailHeader extends StatelessWidget {
  const _PlanDetailHeader({required this.titleKey});

  final String titleKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _CircleBackButton(onTap: () => context.pop()),
          Expanded(
            child: Text(
              titleKey.tr(),
              style: AppTextStyles.planDetailTitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 44),
        ],
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

final class _PlanArcSection extends StatelessWidget {
  const _PlanArcSection({
    required this.title,
    required this.chipKey,
    required this.chipBg,
    required this.chipFg,
    required this.eatShare,
    required this.eatStartFraction,
    required this.endsLabel,
    required this.startsLabel,
    required this.onChange,
  });

  final String title;
  final String chipKey;
  final Color chipBg;
  final Color chipFg;
  final double eatShare;

  /// Yeme penceresinin gün içindeki başlangıcı (0 = gece yarısı, 1 = ertesi).
  final double eatStartFraction;
  final String endsLabel;
  final String startsLabel;
  final VoidCallback onChange;

  /// Yay uçlarının yatay inset'i (dairenin başlangıç/bitiş noktaları).
  static double get _endpointInset =>
      HorseshoeArc.endpointInset(HorseshoeArc.diameterDefault);

  @override
  Widget build(BuildContext context) {
    final tipInset = _endpointInset;

    return SizedBox(
      width: HorseshoeArc.diameterDefault,
      child: Column(
        children: [
          SizedBox(
            width: HorseshoeArc.diameterDefault,
            height: HorseshoeArc.diameterDefault * 0.82,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _AnimatedPlanArc(
                  start: eatStartFraction,
                  progress: eatShare,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: AppTextStyles.planDetailRatio),
                      const SizedBox(height: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: chipBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            chipKey.tr(),
                            style: AppTextStyles.plansChipLabel.copyWith(
                              color: chipFg,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _LegendDot(
                            color: ColorName.colorPlanFasting,
                            label: 'plans.detail_fasting'.tr(),
                          ),
                          const SizedBox(width: 20),
                          _LegendDot(
                            color: ColorName.colorMealPositive,
                            label: 'plans.detail_eating'.tr(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Yay ucu = sol/sağ yazı bloğunun ortası → aralar açılır.
          _PlanTimeRow(
            tipInset: tipInset,
            endsLabel: endsLabel,
            startsLabel: startsLabel,
            onChange: onChange,
          ),
        ],
      ),
    );
  }
}

/// Yeme diliminin yerini ve uzunluğunu yaya doğru kaydırır.
final class _AnimatedPlanArc extends ImplicitlyAnimatedWidget {
  const _AnimatedPlanArc({required this.start, required this.progress})
    : super(
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeOutCubic,
      );

  final double start;
  final double progress;

  @override
  AnimatedWidgetBaseState<_AnimatedPlanArc> createState() =>
      _AnimatedPlanArcState();
}

final class _AnimatedPlanArcState
    extends AnimatedWidgetBaseState<_AnimatedPlanArc> {
  Tween<double>? _start;
  Tween<double>? _progress;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _start =
        visitor(
              _start,
              widget.start,
              (dynamic value) => Tween<double>(begin: value as double),
            )
            as Tween<double>?;
    _progress =
        visitor(
              _progress,
              widget.progress,
              (dynamic value) => Tween<double>(begin: value as double),
            )
            as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return HorseshoeArc(
      start: _start?.evaluate(animation) ?? widget.start,
      progress: _progress?.evaluate(animation) ?? widget.progress,
    );
  }
}

final class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.planDetailLegend),
      ],
    );
  }
}

final class _PlanTimeRow extends StatelessWidget {
  const _PlanTimeRow({
    required this.tipInset,
    required this.endsLabel,
    required this.startsLabel,
    required this.onChange,
  });

  /// Yay ucunun daire sol/sağ kenarından uzaklığı.
  final double tipInset;
  final String endsLabel;
  final String startsLabel;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: HorseshoeArc.diameterDefault,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Sol blok: merkezi sol yay ucunda.
          Positioned(
            left: tipInset,
            child: FractionalTranslation(
              translation: const Offset(-0.5, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'plans.detail_fasting_ends'.tr(),
                    style: AppTextStyles.planDetailTimeLabel,
                  ),
                  const SizedBox(height: 2),
                  Text(endsLabel, style: AppTextStyles.planDetailTimeValue),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: onChange,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'plans.detail_change'.tr(),
                    style: AppTextStyles.planDetailChange,
                  ),
                  const SizedBox(width: 4),
                  ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      ColorName.colorPlanPen,
                      BlendMode.srcIn,
                    ),
                    child: AppImages.solarPenBold.image(width: 16, height: 16),
                  ),
                ],
              ),
            ),
          ),
          // Sağ blok: merkezi sağ yay ucunda.
          Positioned(
            left: HorseshoeArc.diameterDefault - tipInset,
            child: FractionalTranslation(
              translation: const Offset(-0.5, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'plans.detail_fasting_starts'.tr(),
                    style: AppTextStyles.planDetailTimeLabel,
                  ),
                  const SizedBox(height: 2),
                  Text(startsLabel, style: AppTextStyles.planDetailTimeValue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _WeeklySchedule extends StatelessWidget {
  const _WeeklySchedule({
    required this.eatStartHour,
    required this.eatStartMinute,
    required this.eatEndHour,
    required this.eatEndMinute,
  });

  final int eatStartHour;
  final int eatStartMinute;
  final int eatEndHour;
  final int eatEndMinute;

  static const _dayKeys = [
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 34),
          child: SizedBox(
            height: 16,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final hour in [0, 6, 12, 18, 24])
                      Positioned(
                        left: (hour / 24) * w,
                        child: FractionalTranslation(
                          translation: Offset(
                            hour == 0
                                ? 0
                                : hour == 24
                                ? -1
                                : -0.5,
                            0,
                          ),
                          child: Text(
                            '${hour}h',
                            style: AppTextStyles.planDetailAxis,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        _AnimatedWeekBars(
          startHour: eatStartHour + eatStartMinute / 60,
          endHour: eatEndHour + eatEndMinute / 60,
          dayKeys: _dayKeys,
        ),
      ],
    );
  }
}

/// Yedi günün yeşil dilimini at nalıyla aynı sürede kaydırır.
final class _AnimatedWeekBars extends ImplicitlyAnimatedWidget {
  const _AnimatedWeekBars({
    required this.startHour,
    required this.endHour,
    required this.dayKeys,
  }) : super(
         duration: const Duration(milliseconds: 480),
         curve: Curves.easeOutCubic,
       );

  final double startHour;
  final double endHour;
  final List<String> dayKeys;

  @override
  AnimatedWidgetBaseState<_AnimatedWeekBars> createState() =>
      _AnimatedWeekBarsState();
}

final class _AnimatedWeekBarsState
    extends AnimatedWidgetBaseState<_AnimatedWeekBars> {
  Tween<double>? _start;
  Tween<double>? _end;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _start =
        visitor(
              _start,
              widget.startHour,
              (dynamic value) => Tween<double>(begin: value as double),
            )
            as Tween<double>?;
    _end =
        visitor(
              _end,
              widget.endHour,
              (dynamic value) => Tween<double>(begin: value as double),
            )
            as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    final start = _start?.evaluate(animation) ?? widget.startHour;
    final end = _end?.evaluate(animation) ?? widget.endHour;
    return Column(
      children: [
        for (var i = 0; i < widget.dayKeys.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _DayBarRow(
            dayKey: widget.dayKeys[i],
            eatStartHour: start,
            eatEndHour: end,
          ),
        ],
      ],
    );
  }
}

final class _DayBarRow extends StatelessWidget {
  const _DayBarRow({
    required this.dayKey,
    required this.eatStartHour,
    required this.eatEndHour,
  });

  final String dayKey;
  final double eatStartHour;
  final double eatEndHour;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(dayKey.tr(), style: AppTextStyles.planDetailAxis),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: SizedBox(
            height: 14,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final startH = eatStartHour;
                var endH = eatEndHour;
                if (endH <= startH) endH += 24;

                final left = (startH / 24) * w;
                final right = (endH / 24) * w;
                final segW = (right - left).clamp(0.0, w);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: w,
                      height: 14,
                      decoration: BoxDecoration(
                        color: ColorName.colorPlanFastingBar,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Positioned(
                      left: left.clamp(0.0, w),
                      width: segW,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: ColorName.colorMealPositive,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
