import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/utils/weight_progress.dart';
import 'package:fastingapp/core/utils/weight_units.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/core/sync/data_sync.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_shimmer.dart';
import 'package:fastingapp/core/widgets/weight_progress_bar.dart';
import 'package:fastingapp/domain/trackers/trackers_repository.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/home/bloc/home_bloc.dart';
import 'package:fastingapp/presentation/home/bloc/home_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

part 'mixin/body_history_view_mixin.dart';

const _kBodyHeaderHeight = 56.0;

/// Kilo kayıtları detay — Latest / Target / BMI / Weight History.
final class BodyHistoryView extends StatefulWidget {
  const BodyHistoryView({
    this.currentKg,
    this.startKg,
    this.targetKg,
    this.bmi,
    this.heightCm,
    super.key,
  });

  final double? currentKg;
  final double? startKg;
  final double? targetKg;
  final double? bmi;
  final double? heightCm;

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
                        yMin: chartYMin,
                        yMax: chartYMax,
                        onPointSelected: onPointSelected,
                        chartLoading: chartLoading,
                      ),
                      if (entries.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _WeightEntriesCard(
                          entries: entries,
                          onEdit: (e) => unawaited(onEditEntry(e)),
                          onDelete: (e) => unawaited(onDeleteEntry(e)),
                        ),
                      ],
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

  final double? currentKg;
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
                          _formatKgOrDash(currentKg),
                          style: AppTextStyles.bodyWeightValue,
                        ),
                        if (currentKg != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(
                              _unitLabel(),
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
                child: AppImages.weigher2.image(
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

  final double? currentKg;
  final double? startKg;
  final double? targetKg;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final start = startKg;
    final target = targetKg;
    final current = currentKg;
    final progress = weightProgressOf(
      start: start,
      goal: target,
      current: current,
    );
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
                child: Assets.icons.solarPen2LineDuotone2.svg(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          WeightProgressBar(progress: progress),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  startKg == null
                      ? '—'
                      : '${_formatKg(startKg!)}${_unitLabel()}',
                  style: AppTextStyles.bodyBoundValue,
                ),
              ),
              Assets.icons.solarDoubleAltArrowRightLineDuotonePng.image(
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
              Expanded(
                child: Text(
                  targetKg == null
                      ? '—'
                      : '${_formatKg(targetKg!)}${_unitLabel()}',
                  style: AppTextStyles.bodyBoundValue,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'body_history.start'.tr(),
                style: AppTextStyles.bodyBoundLabel,
              ),
              const Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 20),
                    child: _DashLine(),
                  ),
                ),
              ),
              Text(
                'body_history.progress_percent'.tr(args: ['$percent']),
                style: AppTextStyles.bodyProgressPercent,
              ),
              const Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: _DashLine(),
                  ),
                ),
              ),
              Text(
                'body_history.target'.tr(),
                style: AppTextStyles.bodyBoundLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Figma Line 10 — 48w, stroke 1, dashed 3/3, #3C3C43 @ 56%.
final class _DashLine extends StatelessWidget {
  const _DashLine();

  static const _width = 48.0;

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(size: Size(_width, 1), painter: _DashPainter());
  }
}

final class _DashPainter extends CustomPainter {
  const _DashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ColorName.colorSubtitle.withValues(alpha: 0.56)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    const dash = 3.0;
    const gap = 3.0;
    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      final end = math.min(x + dash, size.width);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

final class _BmiCard extends StatelessWidget {
  const _BmiCard({required this.bmi});

  final double? bmi;

  static const _min = 15.0;
  static const _max = 45.0;
  static const _ticks = [15.0, 16.0, 18.5, 25.0, 30.0, 35.0, 40.0, 45.0];

  /// Figma Rect 192–199 — sabit oranlar (22…26), ekrana scale.
  static const _figmaWidths = [22.0, 28.0, 39.0, 78.0, 56.0, 56.0, 55.0, 26.0];
  static const _segmentColors = [
    ColorName.colorBmi0,
    ColorName.colorBmi1,
    ColorName.colorBmi2,
    ColorName.colorBmi3,
    ColorName.colorBmi4,
    ColorName.colorBmi5,
    ColorName.colorBmi6,
    ColorName.colorBmi7,
  ];

  /// Tick’ler: 15→1. gap, 16→2., 18.5→3., … 45→sağ uç (Figma).
  static const _tickBoundaryIndices = [1, 2, 3, 4, 5, 6, 7, 8];

  static const _gap = 2.0;
  static const _barH = 11.0;
  static const _labelH = 16.0;

  @override
  Widget build(BuildContext context) {
    final value = bmi;
    final statusKey = value == null
        ? null
        : value < 18.5
        ? 'body_history.bmi_low'
        : value < 25
        ? 'body_history.bmi_normal'
        : 'body_history.bmi_high';

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
              Text(
                value == null ? '—' : value.toStringAsFixed(1),
                style: AppTextStyles.bodyBmiValue,
              ),
              if (statusKey != null) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    statusKey.tr(),
                    style: AppTextStyles.bodyBmiStatus,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final barW = constraints.maxWidth;
              final segWs = _segmentWidths(barW);
              final boundaries = _boundaryXs(segWs);
              final tickXs = [
                for (final i in _tickBoundaryIndices)
                  i == 8 ? boundaries[i] : boundaries[i] + _gap / 2,
              ];
              final markerX = value == null ? null : _markerX(value, tickXs);

              return Column(
                children: [
                  SizedBox(
                    height: 12,
                    width: barW,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (markerX != null)
                          Positioned(
                            left: (markerX - 8).clamp(0.0, barW - 16),
                            top: 0,
                            child: AppImages.vector18Bmi.image(
                              width: 16,
                              height: 10,
                              fit: BoxFit.contain,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: _barH,
                    width: barW,
                    child: Row(
                      children: [
                        for (var i = 0; i < segWs.length; i++) ...[
                          if (i > 0) const SizedBox(width: _gap),
                          Container(
                            width: segWs[i],
                            height: _barH,
                            decoration: BoxDecoration(
                              color: _segmentColors[i],
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: _labelH,
                    width: barW,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (var i = 0; i < _ticks.length; i++)
                          _BmiTickLabel(
                            tick: _ticks[i],
                            x: tickXs[i],
                            alignEnd: i == _ticks.length - 1,
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Figma genişlik oranlarını mevcut bar genişliğine ölçekler.
  static List<double> _segmentWidths(double barW) {
    final gaps = _gap * (_figmaWidths.length - 1);
    final contentW = barW - gaps;
    final figmaTotal = _figmaWidths.fold<double>(0, (a, b) => a + b);
    return [for (final w in _figmaWidths) w / figmaTotal * contentW];
  }

  static List<double> _boundaryXs(List<double> segWs) {
    final xs = <double>[0];
    var x = 0.0;
    for (var i = 0; i < segWs.length; i++) {
      x += segWs[i];
      xs.add(x);
      if (i < segWs.length - 1) x += _gap;
    }
    return xs;
  }

  /// BMI değerini tick X’leri arasında doğrusal map’ler.
  static double _markerX(double value, List<double> tickXs) {
    final v = value.clamp(_min, _max);
    for (var i = 0; i < _ticks.length - 1; i++) {
      final a = _ticks[i];
      final b = _ticks[i + 1];
      if (v <= b || i == _ticks.length - 2) {
        final t = ((v - a) / (b - a)).clamp(0.0, 1.0);
        return tickXs[i] + t * (tickXs[i + 1] - tickXs[i]);
      }
    }
    return tickXs.last;
  }
}

final class _BmiTickLabel extends StatelessWidget {
  const _BmiTickLabel({
    required this.tick,
    required this.x,
    required this.alignEnd,
  });

  final double tick;
  final double x;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final label = _formatKg(tick);
    final text = Text(label, style: AppTextStyles.bodyBmiTick);

    if (alignEnd) {
      return Positioned(right: 0, top: 0, child: text);
    }

    return Positioned(
      left: x,
      top: 0,
      child: FractionalTranslation(
        translation: const Offset(-0.5, 0),
        child: text,
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
    required this.yMin,
    required this.yMax,
    required this.onPointSelected,
    this.chartLoading = false,
  });

  final _HistoryRange range;
  final ValueChanged<_HistoryRange> onRangeChanged;
  final List<_ChartPoint> points;
  final int selectedIndex;
  final double yMin;
  final double yMax;
  final ValueChanged<int> onPointSelected;
  final bool chartLoading;

  @override
  Widget build(BuildContext context) {
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
            'body_history.weight_history'.tr(),
            style: AppTextStyles.bodyHistoryTitleSmall,
          ),
          const SizedBox(height: 16),
          _RangeSegment(range: range, onChanged: onRangeChanged),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: chartLoading
                ? const AppShimmer(
                    child: AppShimmerBone(
                      height: 220,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.04, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: points.isEmpty
                        ? Center(
                            key: ValueKey('empty-$range'),
                            child: Text(
                              '—',
                              style: AppTextStyles.bodyCardTitle,
                            ),
                          )
                        : _WeightLineChart(
                            key: ValueKey(range),
                            points: points,
                            selectedIndex: selectedIndex,
                            yMin: yMin,
                            yMax: yMax,
                            onPointSelected: onPointSelected,
                          ),
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
          final tabW = constraints.maxWidth / _HistoryRange.values.length;
          final index = range.index;

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
                  for (final item in _HistoryRange.values)
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
                              style: range == item
                                  ? AppTextStyles.bodySegmentActive
                                  : AppTextStyles.bodySegmentIdle,
                              child: Text(switch (item) {
                                _HistoryRange.day => 'body_history.day'.tr(),
                                _HistoryRange.week => 'body_history.week'.tr(),
                                _HistoryRange.month =>
                                  'body_history.month'.tr(),
                              }),
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

@immutable
final class _ChartPoint {
  const _ChartPoint({
    required this.label,
    required this.kg,
    this.isCurrent = false,
  });

  final String label;
  final double kg;

  /// Bugünü içeren (son) kova.
  final bool isCurrent;
}

final class _WeightLineChart extends StatelessWidget {
  const _WeightLineChart({
    required this.points,
    required this.selectedIndex,
    required this.yMin,
    required this.yMax,
    required this.onPointSelected,
    super.key,
  });

  final List<_ChartPoint> points;
  final int selectedIndex;
  final double yMin;
  final double yMax;
  final ValueChanged<int> onPointSelected;

  List<double> get _yLabels {
    final span = yMax - yMin;
    if (span <= 0) return [yMax, yMin];
    return List<double>.generate(5, (i) => yMax - (span / 4) * i);
  }

  double get _yMin => yMin;
  double get _yMax => yMax;
  static const _leftPad = 28.0;
  static const _topPad = 10.0;
  static const _bottomPad = 24.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartW = constraints.maxWidth - _leftPad;
        final chartH = constraints.maxHeight - _bottomPad - _topPad;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final localX = details.localPosition.dx - _leftPad;
            if (localX < 0 || points.isEmpty) return;
            final step = chartW / math.max(points.length - 1, 1);
            final index = (localX / step).round().clamp(0, points.length - 1);
            onPointSelected(index);
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _WeightChartPainter(
                    points: points,
                    selectedIndex: selectedIndex,
                    leftPad: _leftPad,
                    topPad: _topPad,
                    bottomPad: _bottomPad,
                    yMin: _yMin,
                    yMax: _yMax,
                  ),
                ),
              ),
              for (final y in _yLabels)
                Positioned(
                  left: 0,
                  top: _topPad + ((_yMax - y) / (_yMax - _yMin)) * chartH - 5,
                  child: SizedBox(
                    width: _leftPad - 4,
                    child: Text(
                      '${y.toInt()}',
                      style: AppTextStyles.bodyChartAxis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              for (var i = 0; i < points.length; i++)
                Positioned(
                  left:
                      _leftPad +
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
              if (selectedIndex >= 0 && selectedIndex < points.length)
                Builder(
                  builder: (context) {
                    final t = selectedIndex / math.max(points.length - 1, 1);
                    final kg = points[selectedIndex].kg;
                    final y =
                        _topPad + ((_yMax - kg) / (_yMax - _yMin)) * chartH;
                    final x = _leftPad + t * chartW;
                    return Positioned(
                      left: (x - 37).clamp(_leftPad, constraints.maxWidth - 80),
                      top: (y - 40).clamp(0.0, chartH),
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
                          '${_formatKg(kg)} ${_unitLabel()}',
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
    required this.topPad,
    required this.bottomPad,
    required this.yMin,
    required this.yMax,
  });

  final List<_ChartPoint> points;
  final int selectedIndex;
  final double leftPad;
  final double topPad;
  final double bottomPad;
  final double yMin;
  final double yMax;

  /// Kırılma noktalarındaki boşluk (her uçtan).
  static const _breakGap = 5.0;
  static const _stroke = 2.5;
  static const _dotR = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final chartW = size.width - leftPad;
    final chartH = size.height - bottomPad - topPad;
    final gridPaint = Paint()
      ..color = ColorName.colorSubtitle.withValues(alpha: 0.12)
      ..strokeWidth = 1;

    for (var i = 0; i < 5; i++) {
      final y = yMax - ((yMax - yMin) / 4) * i;
      final dy = topPad + ((yMax - y) / (yMax - yMin)) * chartH;
      canvas.drawLine(Offset(leftPad, dy), Offset(size.width, dy), gridPaint);
    }

    Offset pointFor(int i) {
      final t = i / math.max(points.length - 1, 1);
      final dy = topPad + ((yMax - points[i].kg) / (yMax - yMin)) * chartH;
      return Offset(leftPad + t * chartW, dy);
    }

    final linePaint = Paint()
      ..color = ColorName.colorBlack
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;

    // Her segment ayrı çizilir; kırılmada boşluk bırakılır.
    for (var i = 0; i < points.length - 1; i++) {
      final a = pointFor(i);
      final b = pointFor(i + 1);
      final dx = b.dx - a.dx;
      final dy = b.dy - a.dy;
      final len = math.sqrt(dx * dx + dy * dy);
      if (len <= _breakGap * 2) continue;
      final ux = dx / len;
      final uy = dy / len;
      final start = Offset(a.dx + ux * _breakGap, a.dy + uy * _breakGap);
      final end = Offset(b.dx - ux * _breakGap, b.dy - uy * _breakGap);
      canvas.drawLine(start, end, linePaint);
    }

    if (selectedIndex >= 0 && selectedIndex < points.length) {
      final p = pointFor(selectedIndex);
      // 8×8 dolu siyah nokta
      canvas.drawCircle(
        p,
        _dotR,
        Paint()
          ..color = ColorName.colorBlack
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.topPad != topPad;
  }
}

/// Ekranın kilo birimi (`kg` | `lb`, özetten); değerler hep kg gelir.
/// Önceden lb seçilse de bu ekran kg gösteriyordu.
var _weightUnit = 'kg';

String _formatKg(double kg) => WeightUnits.amount(kg, _weightUnit);

String _unitLabel() => WeightUnits.label(_weightUnit);

String _formatKgOrDash(double? kg) => kg == null ? '—' : _formatKg(kg);

/// Son kilo kayıtları: dokun → düzenle, sola kaydır → sil (önceden yanlış
/// girilen değer grafikte kalıcı kalıyordu).
final class _WeightEntriesCard extends StatelessWidget {
  const _WeightEntriesCard({
    required this.entries,
    required this.onEdit,
    required this.onDelete,
  });

  final List<WeightEntry> entries;
  final ValueChanged<WeightEntry> onEdit;
  final ValueChanged<WeightEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    final format = DateFormat.MMMd(context.locale.toString()).add_Hm();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'body_history.entries_title'.tr(),
              style: AppTextStyles.bodyCardTitle,
            ),
            const SizedBox(height: 4),
            for (final e in entries)
              Dismissible(
                key: ValueKey(e.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  onDelete(e);
                  // Liste sunucu yanıtıyla yenilenir.
                  return false;
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: ColorName.colorOptionNegative.withValues(alpha: 0.1),
                  child: Assets.icons.solarTrashBinTrashBoldDuotone.svg(
                    width: 22,
                    height: 22,
                  ),
                ),
                child: InkWell(
                  onTap: () => onEdit(e),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            format.format(e.recordedAt),
                            style: AppTextStyles.bodyBmiTick,
                          ),
                        ),
                        Text(
                          '${_formatKg(e.weightKg)} ${_unitLabel()}',
                          style: AppTextStyles.bodyCardTitle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
