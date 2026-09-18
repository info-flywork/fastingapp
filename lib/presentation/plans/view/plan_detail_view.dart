import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/plans/plan_detail_args.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

part 'mixin/plan_detail_view_mixin.dart';

const _kHeaderHeight = 56.0;

/// Figma Ellipse: 336×336, stroke ≈ 26
const _kArcDiameter = 300.0;
const _kArcStroke = 26.0;

/// Figma: 250° yay, altta açık horseshoe.
const _kArcSweepDegrees = 250.0;

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
                        eatHours: ratioEatHours,
                        fastHours: fastHours,
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
    required this.eatHours,
    required this.fastHours,
    required this.endsLabel,
    required this.startsLabel,
    required this.onChange,
  });

  final String title;
  final String chipKey;
  final Color chipBg;
  final Color chipFg;
  final int eatHours;
  final int fastHours;
  final String endsLabel;
  final String startsLabel;
  final VoidCallback onChange;

  /// Yay uçlarının yatay inset'i (dairenin başlangıç/bitiş noktaları).
  static double get _endpointInset {
    const r = (_kArcDiameter - _kArcStroke) / 2;
    return (_kArcDiameter / 2) + r * math.cos(_PlanArcPainter.startRad);
  }

  @override
  Widget build(BuildContext context) {
    final total = (eatHours + fastHours).clamp(1, 48);
    final eatFraction = eatHours / total;
    final tipInset = _endpointInset;

    return SizedBox(
      width: _kArcDiameter,
      child: Column(
        children: [
          SizedBox(
            width: _kArcDiameter,
            height: _kArcDiameter * 0.82,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: _kArcDiameter,
                  child: CustomPaint(
                    painter: _PlanArcPainter(eatFraction: eatFraction),
                  ),
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

/// 250° horseshoe gösterge — alt açık, yeşil sol uçtan başlar (Figma).
final class _PlanArcPainter extends CustomPainter {
  const _PlanArcPainter({required this.eatFraction});

  final double eatFraction;

  static const double _sweepRad = _kArcSweepDegrees * math.pi / 180;
  static const double _gapRad = (360 - _kArcSweepDegrees) * math.pi / 180;

  /// Flutter: 0=sağ, saat yönü pozitif. Alt merkez = π/2.
  static const double startRad = (math.pi / 2) + (_gapRad / 2);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = _kArcStroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke + 4
      ..strokeCap = StrokeCap.round
      ..color = ColorName.colorPlanArcTrack;

    canvas.drawArc(rect, startRad, _sweepRad, false, trackPaint);

    final fastingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = ColorName.colorPlanFasting;

    canvas.drawArc(rect, startRad, _sweepRad, false, fastingPaint);

    final eatSweep = _sweepRad * eatFraction.clamp(0.05, 0.95);
    final eatingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = ColorName.colorMealPositive;

    canvas.drawArc(rect, startRad, eatSweep, false, eatingPaint);
  }

  @override
  bool shouldRepaint(covariant _PlanArcPainter oldDelegate) {
    return oldDelegate.eatFraction != eatFraction;
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
      width: _kArcDiameter,
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
                    child: Assets.images.solarPenBold.image(
                      width: 16,
                      height: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Sağ blok: merkezi sağ yay ucunda.
          Positioned(
            left: _kArcDiameter - tipInset,
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
        for (var i = 0; i < _dayKeys.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _DayBarRow(
            dayKey: _dayKeys[i],
            eatStartHour: eatStartHour + eatStartMinute / 60,
            eatEndHour: eatEndHour + eatEndMinute / 60,
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
