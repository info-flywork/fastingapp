import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

part 'mixin/body_history_view_mixin.dart';

const _kBodyHeaderHeight = 56.0;

/// Kilo kayıtları detay — Latest / Target / BMI / Weight History.
final class BodyHistoryView extends StatefulWidget {
  const BodyHistoryView({
    this.currentKg = 102.5,
    this.startKg = 112.2,
    this.targetKg = 74.2,
    this.bmi = 32.4,
    this.heightCm = 178,
    super.key,
  });

  final double currentKg;
  final double startKg;
  final double targetKg;
  final double bmi;
  final double heightCm;

  @override
  State<BodyHistoryView> createState() => _BodyHistoryViewState();
}

class _BodyHistoryViewState extends State<BodyHistoryView>
    with BodyHistoryViewMixin {
  @override
  void initState() {
    super.initState();
    initBodyHistory();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ColorName.colorBodyPageBg,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                height: _kBodyHeaderHeight,
                width: double.infinity,
                child: _BodyHeader(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 24),
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      _LatestRecordCard(
                        currentKg: currentKg,
                        onUpdate: onUpdateTapped,
                      ),
                      const SizedBox(height: 12),
                      _TargetCard(
                        currentKg: currentKg,
                        startKg: startKg,
                        targetKg: targetKg,
                        onEdit: onEditTargetTapped,
                      ),
                      const SizedBox(height: 12),
                      _BmiCard(bmi: bmi),
                      const SizedBox(height: 12),
                      _WeightHistoryCard(
                        range: selectedRange,
                        onRangeChanged: onRangeChanged,
                        points: chartPoints,
                        selectedIndex: selectedPointIndex,
                        onPointSelected: onPointSelected,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _BodyHeader extends StatelessWidget {
  const _BodyHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _CircleIconButton(
            onTap: () => context.pop(),
            child: Assets.icons.solarAltArrowUpLineDuotone.svg(
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                ColorName.colorTitle,
                BlendMode.srcIn,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'body_history.title'.tr(),
              style: AppTextStyles.bodyHistoryTitle,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

final class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorName.colorWhite,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 44, height: 44, child: Center(child: child)),
      ),
    );
  }
}

final class _LatestRecordCard extends StatelessWidget {
  const _LatestRecordCard({required this.currentKg, required this.onUpdate});

  final double currentKg;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'body_history.latest_record'.tr(),
                      style: AppTextStyles.bodyCardTitle,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatKg(currentKg),
                          style: AppTextStyles.bodyWeightValue,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            'body_history.unit'.tr(),
                            style: AppTextStyles.bodyWeightUnit,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Transform.rotate(
                angle: math.pi / 6,
                child: Assets.images.weigher2.image(
                  width: 105,
                  height: 105,
                  fit: BoxFit.contain,
                  opacity: const AlwaysStoppedAnimation(0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _UpdateButton(onTap: onUpdate),
        ],
      ),
    );
  }
}

final class _UpdateButton extends StatelessWidget {
  const _UpdateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorName.colorStepsFill,
      borderRadius: BorderRadius.circular(99999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99999),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99999),
            border: Border.all(
              color: ColorName.colorWhite.withValues(alpha: 0.15),
            ),
          ),
          child: Text(
            'body_history.update'.tr(),
            style: AppTextStyles.bodyUpdateButton,
          ),
        ),
      ),
    );
  }
}

final class _TargetCard extends StatelessWidget {
  const _TargetCard({
    required this.currentKg,
    required this.startKg,
    required this.targetKg,
    required this.onEdit,
  });

  final double currentKg;
  final double startKg;
  final double targetKg;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final span = (startKg - targetKg).abs();
    final progress = span <= 0
        ? 0.0
        : ((startKg - currentKg) / span).clamp(0.0, 1.0);
    final percent = (progress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'body_history.target'.tr(),
                  style: AppTextStyles.bodyCardTitle,
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                behavior: HitTestBehavior.opaque,
                child: Assets.icons.solarPen2LineDuotone2.svg(
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    ColorName.colorTitle,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ThinProgressBar(progress: progress),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BoundColumn(
                  value: '${_formatKg(startKg)}${'body_history.unit'.tr()}',
                  label: 'body_history.start'.tr(),
                  align: TextAlign.start,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Assets.icons.solarDoubleAltArrowRightLineDuotone.svg(
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'body_history.progress_percent'.tr(args: ['$percent']),
                      style: AppTextStyles.bodyProgressPercent,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _BoundColumn(
                  value: '${_formatKg(targetKg)}${'body_history.unit'.tr()}',
                  label: 'body_history.target'.tr(),
                  align: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _BoundColumn extends StatelessWidget {
  const _BoundColumn({
    required this.value,
    required this.label,
    required this.align,
  });

  final String value;
  final String label;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align == TextAlign.end
          ? CrossAxisAlignment.end
          : align == TextAlign.start
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(value, style: AppTextStyles.bodyBoundValue, textAlign: align),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.bodyBoundLabel, textAlign: align),
      ],
    );
  }
}

final class _ThinProgressBar extends StatelessWidget {
  const _ThinProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          height: 8,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ColorName.colorStepsTrack,
              borderRadius: BorderRadius.circular(999),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: value,
                  heightFactor: 1,
                  child: const ColoredBox(color: ColorName.colorStepsFill),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

final class _BmiCard extends StatelessWidget {
  const _BmiCard({required this.bmi});

  final double bmi;

  static const _min = 15.0;
  static const _max = 45.0;
  static const _ticks = [15.0, 16.0, 18.5, 25.0, 30.0, 35.0, 40.0, 45.0];
  static const _segmentFlex = [28, 39, 78, 56, 56, 55, 26];
  static const _segmentColors = [
    ColorName.colorBmi1,
    ColorName.colorBmi2,
    ColorName.colorBmi3,
    ColorName.colorBmi4,
    ColorName.colorBmi5,
    ColorName.colorBmi6,
    ColorName.colorBmi7,
  ];

  @override
  Widget build(BuildContext context) {
    final statusKey = bmi < 18.5
        ? 'body_history.bmi_low'
        : bmi < 25
        ? 'body_history.bmi_normal'
        : 'body_history.bmi_high';
    final markerT = ((bmi - _min) / (_max - _min)).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'body_history.bmi_title'.tr(),
            style: AppTextStyles.bodyCardTitle,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatKg(bmi), style: AppTextStyles.bodyBmiValue),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(statusKey.tr(), style: AppTextStyles.bodyBmiStatus),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 11,
              child: Row(
                children: [
                  for (var i = 0; i < _segmentFlex.length; i++)
                    Expanded(
                      flex: _segmentFlex[i],
                      child: ColoredBox(color: _segmentColors[i]),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              final x = markerT * constraints.maxWidth;
              return SizedBox(
                height: 14,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: (x - 8).clamp(0.0, constraints.maxWidth - 16),
                      top: 0,
                      child: Assets.icons.vector18.svg(width: 16, height: 10),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final tick in _ticks)
                Text(
                  tick == tick.roundToDouble()
                      ? '${tick.toInt()}'
                      : tick.toStringAsFixed(1),
                  style: AppTextStyles.bodyBmiTick,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _HistoryRange { day, week, month }

final class _WeightHistoryCard extends StatelessWidget {
  const _WeightHistoryCard({
    required this.range,
    required this.onRangeChanged,
    required this.points,
    required this.selectedIndex,
    required this.onPointSelected,
  });

  final _HistoryRange range;
  final ValueChanged<_HistoryRange> onRangeChanged;
  final List<_ChartPoint> points;
  final int selectedIndex;
  final ValueChanged<int> onPointSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'body_history.weight_history'.tr(),
            style: AppTextStyles.bodyCardTitle,
          ),
          const SizedBox(height: 12),
          _RangeSegment(range: range, onChanged: onRangeChanged),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _WeightLineChart(
              points: points,
              selectedIndex: selectedIndex,
              onPointSelected: onPointSelected,
            ),
          ),
        ],
      ),
    );
  }
}

final class _RangeSegment extends StatelessWidget {
  const _RangeSegment({required this.range, required this.onChanged});

  final _HistoryRange range;
  final ValueChanged<_HistoryRange> onChanged;

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
        ],
      ),
      child: Row(
        children: [
          for (final item in _HistoryRange.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(item),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: range == item
                        ? ColorName.colorWhite
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: range == item
                        ? const [
                            BoxShadow(
                              color: Color(0x0D0C0C0D),
                              offset: Offset(0, 1),
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    switch (item) {
                      _HistoryRange.day => 'body_history.day'.tr(),
                      _HistoryRange.week => 'body_history.week'.tr(),
                      _HistoryRange.month => 'body_history.month'.tr(),
                    },
                    style: range == item
                        ? AppTextStyles.bodySegmentActive
                        : AppTextStyles.bodySegmentIdle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final class _ChartPoint {
  const _ChartPoint({required this.label, required this.kg});

  final String label;
  final double kg;
}

final class _WeightLineChart extends StatelessWidget {
  const _WeightLineChart({
    required this.points,
    required this.selectedIndex,
    required this.onPointSelected,
  });

  final List<_ChartPoint> points;
  final int selectedIndex;
  final ValueChanged<int> onPointSelected;

  static const _yLabels = [120.0, 100.0, 80.0, 70.0, 65.0];
  static const _yMin = 65.0;
  static const _yMax = 120.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const leftPad = 28.0;
        const bottomPad = 24.0;
        final chartW = constraints.maxWidth - leftPad;
        final chartH = constraints.maxHeight - bottomPad;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final localX = details.localPosition.dx - leftPad;
            if (localX < 0 || points.isEmpty) return;
            final step = chartW / math.max(points.length - 1, 1);
            final index = (localX / step).round().clamp(0, points.length - 1);
            onPointSelected(index);
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _WeightChartPainter(
                    points: points,
                    selectedIndex: selectedIndex,
                    leftPad: leftPad,
                    bottomPad: bottomPad,
                    yMin: _yMin,
                    yMax: _yMax,
                  ),
                ),
              ),
              // Y labels
              for (final y in _yLabels)
                Positioned(
                  left: 0,
                  top: ((_yMax - y) / (_yMax - _yMin)) * chartH - 6,
                  child: SizedBox(
                    width: leftPad - 4,
                    child: Text(
                      '${y.toInt()}',
                      style: AppTextStyles.bodyChartAxis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              // X labels
              for (var i = 0; i < points.length; i++)
                Positioned(
                  left:
                      leftPad +
                      (i / math.max(points.length - 1, 1)) * chartW -
                      8,
                  bottom: 0,
                  child: SizedBox(
                    width: 16,
                    child: Text(
                      points[i].label,
                      style: AppTextStyles.bodyChartAxis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              // Tooltip
              if (selectedIndex >= 0 && selectedIndex < points.length)
                Builder(
                  builder: (context) {
                    final t = selectedIndex / math.max(points.length - 1, 1);
                    final kg = points[selectedIndex].kg;
                    final y = ((_yMax - kg) / (_yMax - _yMin)) * chartH;
                    final x = leftPad + t * chartW;
                    return Positioned(
                      left: (x - 37).clamp(leftPad, constraints.maxWidth - 80),
                      top: (y - 40).clamp(0.0, chartH - 20),
                      child: Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: ColorName.colorChartTooltip,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.251),
                              offset: const Offset(0, 4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${_formatKg(kg)} ${'body_history.unit'.tr()}',
                          style: AppTextStyles.bodyChartTooltip,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

final class _WeightChartPainter extends CustomPainter {
  const _WeightChartPainter({
    required this.points,
    required this.selectedIndex,
    required this.leftPad,
    required this.bottomPad,
    required this.yMin,
    required this.yMax,
  });

  final List<_ChartPoint> points;
  final int selectedIndex;
  final double leftPad;
  final double bottomPad;
  final double yMin;
  final double yMax;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final chartW = size.width - leftPad;
    final chartH = size.height - bottomPad;
    final gridPaint = Paint()
      ..color = ColorName.colorSubtitle.withValues(alpha: 0.12)
      ..strokeWidth = 1;

    for (final y in [120.0, 100.0, 80.0, 70.0, 65.0]) {
      final dy = ((yMax - y) / (yMax - yMin)) * chartH;
      canvas.drawLine(Offset(leftPad, dy), Offset(size.width, dy), gridPaint);
    }

    Offset pointFor(int i) {
      final t = i / math.max(points.length - 1, 1);
      final dy = ((yMax - points[i].kg) / (yMax - yMin)) * chartH;
      return Offset(leftPad + t * chartW, dy);
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final p = pointFor(i);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    final linePaint = Paint()
      ..color = ColorName.colorTitle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    if (selectedIndex >= 0 && selectedIndex < points.length) {
      final p = pointFor(selectedIndex);
      canvas.drawCircle(p, 5, Paint()..color = ColorName.colorTitle);
      canvas.drawCircle(p, 3, Paint()..color = ColorName.colorWhite);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

String _formatKg(double kg) {
  if (kg == kg.roundToDouble()) return '${kg.toInt()}';
  return kg.toStringAsFixed(1);
}
