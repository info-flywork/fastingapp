import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/domain/fasting/forecast_repository.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

enum _ForecastDay { easy, moderate, hard }

/// Oruç tahmini kartı — segment + metrikler + grafik.
///
/// Segment: body_history `_RangeSegment` kalıbı.
/// Grafik: body_history `_WeightLineChart` CustomPaint kalıbı.
final class FastingFastForecastCard extends StatefulWidget {
  const FastingFastForecastCard({super.key});

  @override
  State<FastingFastForecastCard> createState() =>
      _FastingFastForecastCardState();
}

class _FastingFastForecastCardState extends State<FastingFastForecastCard> {
  var _day = _ForecastDay.easy;
  FastForecast? _forecast;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final forecast = await getIt<ForecastRepository>().getForecast();
      if (!mounted) return;
      setState(() {
        _forecast = forecast;
        _day = _dayFor(forecast.successChance);
      });
    } on Exception {
      if (mounted)
        setState(() => _forecast = const FastForecast(available: false));
    }
  }

  /// Başarı ihtimaline göre günün zorluğu.
  static _ForecastDay _dayFor(double? chance) => switch (chance) {
    null => _ForecastDay.easy,
    >= 0.75 => _ForecastDay.easy,
    >= 0.5 => _ForecastDay.moderate,
    _ => _ForecastDay.hard,
  };

  @override
  Widget build(BuildContext context) {
    final forecast = _forecast;
    // Yükleniyor ya da yeterli geçmiş yok → kart gösterilmez.
    if (forecast == null || !forecast.available) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Header(),
          const SizedBox(height: 16),
          _DaySegment(
            day: _day,
            onChanged: (value) => setState(() => _day = value),
          ),
          const SizedBox(height: 16),
          _ForecastSummary(day: _day, chance: forecast.successChance),
          const SizedBox(height: 16),
          _MetricsRow(forecast: forecast),
          const SizedBox(height: 16),
          SizedBox(height: 180, child: _ForecastChart(day: _day)),
        ],
      ),
    );
  }
}

final class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppImages.fastForecast.image(
          width: 28,
          height: 28,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 6),
        Text(
          'fasting_page.forecast_title'.tr(),
          style: AppTextStyles.fastingForecastTitle,
        ),
      ],
    );
  }
}

/// Figma Frame 1597878700 — 40h, pad 4, radius 20, #F6F6F6, inner shadows.
final class _DaySegment extends StatelessWidget {
  const _DaySegment({required this.day, required this.onChanged});

  final _ForecastDay day;
  final ValueChanged<_ForecastDay> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ColorName.colorFlipClock,
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
          final tabW = constraints.maxWidth / _ForecastDay.values.length;
          final index = day.index;

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
                  for (final item in _ForecastDay.values)
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
                              style: day == item
                                  ? AppTextStyles.bodySegmentActive
                                  : AppTextStyles.bodySegmentIdle,
                              child: Text(
                                switch (item) {
                                  _ForecastDay.easy =>
                                    'fasting_page.forecast_easy'.tr(),
                                  _ForecastDay.moderate =>
                                    'fasting_page.forecast_moderate'.tr(),
                                  _ForecastDay.hard =>
                                    'fasting_page.forecast_hard'.tr(),
                                },
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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

final class _ForecastSummary extends StatelessWidget {
  const _ForecastSummary({required this.day, required this.chance});

  final _ForecastDay day;
  final double? chance;

  @override
  Widget build(BuildContext context) {
    final icon = day == _ForecastDay.easy ? AppImages.huh : AppImages.noone;
    final dayLabel = switch (day) {
      _ForecastDay.easy => 'fasting_page.forecast_easy'.tr(),
      _ForecastDay.moderate => 'fasting_page.forecast_moderate'.tr(),
      _ForecastDay.hard => 'fasting_page.forecast_hard'.tr(),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  icon.image(width: 20, height: 20, fit: BoxFit.contain),
                  const SizedBox(width: 6),
                  Text(
                    'fasting_page.forecast_today'.tr(),
                    style: AppTextStyles.fastingForecastLabel,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(dayLabel, style: AppTextStyles.fastingForecastDay),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'fasting_page.forecast_confidence'.tr(),
              style: AppTextStyles.fastingForecastLabel,
            ),
            const SizedBox(height: 4),
            Text(
              chance == null ? '–' : '${(chance! * 100).round()}%',
              style: AppTextStyles.fastingForecastConfidence,
            ),
          ],
        ),
      ],
    );
  }
}

final class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.forecast});

  final FastForecast forecast;

  @override
  Widget build(BuildContext context) {
    String clock(DateTime t) => DateFormat.Hm().format(t);
    final peak = forecast.toughestAt;
    final start = forecast.fastStartsAt;
    final end = forecast.fastEndsAt;
    final fastMinutes = start != null && end != null
        ? end.difference(start).inMinutes
        : null;
    return Row(
      children: [
        Expanded(
          child: _MetricCell(
            icon: AppImages.stonks,
            value: peak == null ? '–' : clock(peak),
            label: 'fasting_page.forecast_hunger_pack'.tr(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCell(
            icon: AppImages.redWarning,
            value: peak == null
                ? '–'
                : '${clock(peak.subtract(const Duration(minutes: 30)))} - '
                      '${clock(peak.add(const Duration(minutes: 30)))}',
            label: 'fasting_page.forecast_risk_zone'.tr(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCell(
            icon: AppImages.sandClock,
            value: fastMinutes == null
                ? '–'
                : '${fastMinutes ~/ 60}h:'
                      '${(fastMinutes % 60).toString().padLeft(2, '0')}',
            label: 'fasting_page.forecast_recommended'.tr(),
          ),
        ),
      ],
    );
  }
}

final class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.icon,
    required this.value,
    required this.label,
  });

  final AppImageAsset icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        icon.image(width: 42, height: 42, fit: BoxFit.contain),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.fastingForecastMetricValue,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: AppTextStyles.fastingForecastMetricLabel,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// High/Low + multi-color line + PEAK — body_history chart kalıbı.
final class _ForecastChart extends StatelessWidget {
  const _ForecastChart({required this.day});

  final _ForecastDay day;

  static const _xLabels = ['8:00', '16:00', '24:00'];
  static const _leftPad = 36.0;
  static const _topPad = 28.0;
  static const _bottomPad = 22.0;
  static const _rightPad = 8.0;

  static _DaySeries _seriesFor(_ForecastDay day) => switch (day) {
    _ForecastDay.easy => const _DaySeries(
      values: [0.18, 0.32, 0.48, 0.62, 0.88, 0.72, 0.45],
      peakIndex: 4,
    ),
    _ForecastDay.moderate => const _DaySeries(
      values: [0.28, 0.45, 0.58, 0.82, 0.70, 0.55, 0.40],
      peakIndex: 3,
    ),
    _ForecastDay.hard => const _DaySeries(
      values: [0.40, 0.62, 0.92, 0.78, 0.65, 0.52, 0.38],
      peakIndex: 2,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final target = _seriesFor(day);

    return TweenAnimationBuilder<_DaySeries>(
      tween: _DaySeriesTween(end: target),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, series, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final chartW = constraints.maxWidth - _leftPad - _rightPad;
            final chartH = constraints.maxHeight - _topPad - _bottomPad;
            final peakT = series.peakIndex / (series.values.length - 1);
            final peakX = _leftPad + peakT * chartW;
            final peakY =
                _topPad + (1 - series.values[series.peakIndex]) * chartH;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ForecastChartPainter(
                      values: series.values,
                      peakIndex: series.peakIndex,
                      leftPad: _leftPad,
                      topPad: _topPad,
                      bottomPad: _bottomPad,
                      rightPad: _rightPad,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: _topPad - 2,
                  child: Text(
                    'fasting_page.forecast_high'.tr(),
                    style: AppTextStyles.bodyChartAxis,
                  ),
                ),
                Positioned(
                  left: 0,
                  top: _topPad + chartH - 10,
                  child: Text(
                    'fasting_page.forecast_low'.tr(),
                    style: AppTextStyles.bodyChartAxis,
                  ),
                ),
                for (var i = 0; i < _xLabels.length; i++)
                  Positioned(
                    left: _leftPad + (i / (_xLabels.length - 1)) * chartW - 14,
                    bottom: 0,
                    child: SizedBox(
                      width: 36,
                      child: Text(
                        _xLabels[i],
                        style: AppTextStyles.bodyChartAxis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                Positioned(
                  left: (peakX - 28).clamp(_leftPad, constraints.maxWidth - 64),
                  top: (peakY - 34).clamp(0.0, chartH),
                  child: Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: ColorName.colorChartTooltip,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          offset: const Offset(0, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'fasting_page.forecast_peak'.tr(),
                      style: AppTextStyles.bodyChartTooltip,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

@immutable
final class _DaySeries {
  const _DaySeries({required this.values, required this.peakIndex});

  final List<double> values;
  final int peakIndex;
}

final class _DaySeriesTween extends Tween<_DaySeries> {
  _DaySeriesTween({required _DaySeries end}) : super(end: end);

  @override
  _DaySeries lerp(double t) {
    final a = begin ?? end!;
    final b = end!;
    final len = math.min(a.values.length, b.values.length);
    return _DaySeries(
      values: [
        for (var i = 0; i < len; i++)
          ui.lerpDouble(a.values[i], b.values[i], t)!,
      ],
      peakIndex: t < 0.5 ? a.peakIndex : b.peakIndex,
    );
  }
}

final class _ForecastChartPainter extends CustomPainter {
  const _ForecastChartPainter({
    required this.values,
    required this.peakIndex,
    required this.leftPad,
    required this.topPad,
    required this.bottomPad,
    required this.rightPad,
  });

  final List<double> values;
  final int peakIndex;
  final double leftPad;
  final double topPad;
  final double bottomPad;
  final double rightPad;

  @override
  void paint(Canvas canvas, Size size) {
    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - bottomPad;
    final origin = Offset(leftPad, topPad);

    final gridPaint = Paint()
      ..color = ColorName.colorSubtitle.withValues(alpha: 0.12)
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = origin.dy + chartH * (i / 3);
      canvas.drawLine(
        Offset(origin.dx, y),
        Offset(origin.dx + chartW, y),
        gridPaint,
      );
    }

    if (values.length < 2) return;

    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          origin.dx + (i / (values.length - 1)) * chartW,
          origin.dy + (1 - values[i]) * chartH,
        ),
    ];

    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final delta = b - a;
      final len = delta.distance;
      if (len <= 0) continue;

      // Segmentler arasında küçük boşluk; peak noktasında çember payı.
      const gapPx = 2.5;
      const peakGapPx = 8.0;
      final startGap = i == peakIndex ? peakGapPx : gapPx;
      final endGap = i + 1 == peakIndex ? peakGapPx : gapPx;
      final startInset = math.min(startGap, len / 2 - 0.5);
      final endInset = math.min(endGap, len / 2 - 0.5);
      if (startInset <= 0 || endInset <= 0) continue;

      final dir = delta / len;
      final start = a + dir * startInset;
      final end = b - dir * endInset;

      final paint = Paint()
        ..color = _colorForSegment(i)
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, end, paint);
    }

    final peak = points[peakIndex];
    canvas.drawCircle(peak, 3, Paint()..color = ColorName.colorErrorRed);
  }

  /// Peak sağ/sol kırmızı → turuncu → koyu yeşil → açık yeşil.
  Color _colorForSegment(int segmentIndex) {
    final distance = segmentIndex < peakIndex
        ? peakIndex - 1 - segmentIndex
        : segmentIndex - peakIndex;
    return switch (distance) {
      0 => ColorName.colorErrorRed,
      1 => ColorName.colorWarningOrange,
      2 => const Color(0xFF4A9B4F),
      _ => ColorName.colorMealPositive,
    };
  }

  @override
  bool shouldRepaint(covariant _ForecastChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.peakIndex != peakIndex;
  }
}
