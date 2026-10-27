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
import 'package:fastingapp/presentation/fasting/bloc/fasting_session_cubit.dart';
import 'package:fastingapp/presentation/fasting/bloc/fasting_session_state.dart';
import 'package:flutter/material.dart';

enum _ForecastDay { easy, moderate, hard }

/// Oruç tahmini kartı — segment + metrikler + grafik.
///
/// Segment: body_history `_RangeSegment` kalıbı.
/// Grafik: body_history `_WeightLineChart` CustomPaint kalıbı.
final class FastingFastForecastCard extends StatefulWidget {
  const FastingFastForecastCard({super.key});

  /// Çıkış / hesap değişimi: önceki kullanıcının tahmini görünmesin.
  static void clearCache() {
    _FastingFastForecastCardState._lastForecast = null;
    _FastingFastForecastCardState._lastDay = null;
  }

  @override
  State<FastingFastForecastCard> createState() =>
      _FastingFastForecastCardState();
}

class _FastingFastForecastCardState extends State<FastingFastForecastCard> {
  /// Son tahmin ve seçili gün (oturum boyunca): kart yeniden kurulunca
  /// (sekme / sayfa dönüşü) boş gelip sonra açılmasın, seçim sıfırlanmasın.
  static FastForecast? _lastForecast;
  static _ForecastDay? _lastDay;

  late var _day = _lastDay ?? _dayFor(_lastForecast?.successChance);
  FastForecast? _forecast = _lastForecast;

  StreamSubscription<String>? _fastChanges;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    // Oruç başlayınca / bitince, plan (saat, süre, haftalık gün) değişince
    // ve gün dönünce yeniden yüklenir; önceden yalnızca oruç değişiminde.
    final session = getIt<FastingSessionCubit>();
    _fastChanges = session.stream
        .map(_keyOf)
        .distinct()
        .where((key) => key != _loadedFor)
        .listen((_) => unawaited(_load()));
  }

  String? _loadedFor;

  static String _keyOf(FastingSessionState s) {
    final now = DateTime.now();
    return '${s.fast?.id}|${s.plan?.signature}|${now.year}-${now.month}-${now.day}';
  }

  @override
  void dispose() {
    _fastChanges?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    _loadedFor = _keyOf(getIt<FastingSessionCubit>().state);
    try {
      final forecast = await getIt<ForecastRepository>().getForecast();
      // Önerilen gün yalnızca tahmin değişince güncellenir; aynı tahmin
      // yeniden gelince kullanıcının seçtiği sekme korunur.
      final changed = forecast.successChance != _forecast?.successChance;
      _lastForecast = forecast;
      if (changed) _lastDay = _dayFor(forecast.successChance);
      if (!mounted) return;
      setState(() {
        _forecast = forecast;
        if (changed) _day = _dayFor(forecast.successChance);
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
    final today = _dayFor(forecast.successChance);
    final slice = forecast.sliceFor(_dayKey(_day), isToday: _day == today);
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
            onChanged: (value) => setState(() => _day = _lastDay = value),
          ),
          const SizedBox(height: 16),
          _ForecastSummary(day: _day, chance: forecast.successChance),
          const SizedBox(height: 16),
          _MetricsRow(forecast: forecast, slice: slice),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: _ForecastChart(forecast: forecast, curve: slice.curve),
          ),
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

String _dayKey(_ForecastDay day) => switch (day) {
  _ForecastDay.easy => 'easy',
  _ForecastDay.moderate => 'moderate',
  _ForecastDay.hard => 'hard',
};

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
  const _MetricsRow({required this.forecast, required this.slice});

  final FastForecast forecast;
  final ForecastSlice slice;

  @override
  Widget build(BuildContext context) {
    String clock(DateTime t) => DateFormat.Hm().format(t);
    final peak = slice.toughestAt;
    final riskStart = slice.riskStartsAt;
    final riskEnd = slice.riskEndsAt;
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
            value: riskStart == null || riskEnd == null
                ? '–'
                : '${clock(riskStart)} – ${clock(riskEnd)}',
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
        SizedBox(
          height: 28,
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTextStyles.fastingForecastMetricValue,
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
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

/// Yüksek/Düşük çizgisi. Noktalar sunucunun `curve` dizisi;
/// tepe yalnızca gerçek bir zorluk kaydı varsa çizilir.
final class _ForecastChart extends StatelessWidget {
  const _ForecastChart({required this.forecast, required this.curve});

  final FastForecast forecast;
  final List<double> curve;

  static const _leftPad = 36.0;
  static const _topPad = 28.0;
  static const _bottomPad = 22.0;
  static const _rightPad = 8.0;

  static _DaySeries _series(List<double> curve) {
    final values = curve.length >= 2 ? curve : const [0.0, 0.0];
    var peak = -1;
    var best = 0.0;
    for (var i = 0; i < values.length; i++) {
      if (values[i] > best) {
        best = values[i];
        peak = i;
      }
    }
    return _DaySeries(values: values, peakIndex: best > 0 ? peak : -1);
  }

  static List<String> _axis(FastForecast forecast) {
    final start = forecast.fastStartsAt;
    final end = forecast.fastEndsAt;
    if (start == null || end == null) {
      final last = math.max(0, forecast.curve.length - 1);
      return ['0s', '${last ~/ 2}s', '${last}s'];
    }
    final mid = start.add(end.difference(start) ~/ 2);
    String fmt(DateTime t) => DateFormat.Hm().format(t);
    return [fmt(start), fmt(mid), fmt(end)];
  }

  @override
  Widget build(BuildContext context) {
    final target = _series(curve);
    final labels = _axis(forecast);

    return TweenAnimationBuilder<_DaySeries>(
      tween: _DaySeriesTween(end: target),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, series, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final chartW = constraints.maxWidth - _leftPad - _rightPad;
            final chartH = constraints.maxHeight - _topPad - _bottomPad;
            final hasPeak = series.peakIndex >= 0;
            final peakT = hasPeak
                ? series.peakIndex / (series.values.length - 1)
                : 0.0;
            final peakX = _leftPad + peakT * chartW;
            final peakY = hasPeak
                ? _topPad + (1 - series.values[series.peakIndex]) * chartH
                : 0.0;

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
                for (var i = 0; i < labels.length; i++)
                  Positioned(
                    left: _leftPad + (i / (labels.length - 1)) * chartW - 18,
                    bottom: 0,
                    child: SizedBox(
                      width: 44,
                      child: Text(
                        labels[i],
                        style: AppTextStyles.bodyChartAxis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                if (hasPeak)
                  Positioned(
                    left: (peakX - 28).clamp(
                      _leftPad,
                      constraints.maxWidth - 64,
                    ),
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

    if (peakIndex < 0) return;
    final peak = points[peakIndex];
    canvas.drawCircle(peak, 3, Paint()..color = ColorName.colorErrorRed);
  }

  /// Tepe yoksa çizgi düz yeşil. Varsa tepeye yaklaştıkça kırmızıya döner.
  Color _colorForSegment(int segmentIndex) {
    if (peakIndex < 0) return ColorName.colorMealPositive;
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
