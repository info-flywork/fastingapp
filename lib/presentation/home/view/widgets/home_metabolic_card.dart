part of '../home_view.dart';

/// Metabolic Twin kartı — kilo kartının altında.
final class HomeMetabolicCard extends StatelessWidget {
  const HomeMetabolicCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Assets.images.metabolic.image(
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'home.metabolic_twin'.tr(),
                  style: AppTextStyles.homeMetabolicTitle,
                ),
              ),
              Assets.icons.solarAltArrowUpLineDuotoneRight.svg(),
            ],
          ),
          const SizedBox(height: 16),
          const _MascotStage(),
          const SizedBox(height: 16),
          Text(
            'home.metabolic_feeling'.tr(),
            style: AppTextStyles.homeMetabolicFeeling,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'home.metabolic_subtitle'.tr(),
            style: AppTextStyles.homeMetabolicSubtitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Expanded(
                child: Center(
                  child: _MetabolicGauge(
                    progress: 0.72,
                    color: ColorName.colorPremiumGradientStart,
                    labelKey: 'home.metabolic_energy',
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: _MetabolicGauge(
                    progress: 0.45,
                    color: ColorName.colorStepsFill,
                    labelKey: 'home.metabolic_hydration',
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: _MetabolicGauge(
                    progress: 0.88,
                    color: ColorName.colorMetabolicFast,
                    labelKey: 'home.metabolic_fast_ready',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _MascotStage extends StatelessWidget {
  const _MascotStage();

  static const _pinkW = 140.0;
  static const _pinkH = 80.0;
  static const _pinkRadius = 14.0;
  static const _mascotSize = 150.0;

  /// Pembe üstünde kafa payı + pembe yükseklik.
  static const _stageH = 120.0;

  /// Bacakları kesmek için aşağı taşı (px).
  static const _clipLegsBy = 30.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _stageH,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: _pinkW,
            height: _pinkH,
            decoration: BoxDecoration(
              color: ColorName.colorMetabolicBg,
              borderRadius: BorderRadius.circular(_pinkRadius),
            ),
          ),
          Positioned(
            bottom: -_clipLegsBy,
            child: SizedBox(
              width: _mascotSize,
              height: _mascotSize,
              child: Assets.images.mascotMetabolic.image(
                width: _mascotSize,
                height: _mascotSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _MetabolicGauge extends StatelessWidget {
  const _MetabolicGauge({
    required this.progress,
    required this.color,
    required this.labelKey,
  });

  final double progress;
  final Color color;
  final String labelKey;

  static const _size = 108.0;

  @override
  Widget build(BuildContext context) {
    final target = progress.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(_size, constraints.maxWidth);
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: target),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(size, size),
                    painter: _MetabolicArcPainter(
                      progress: value,
                      progressColor: color,
                      trackColor: ColorName.colorUnitToggleBg,
                    ),
                  ),
                  // Yüzde — yayın merkezine yakın.
                  Align(
                    alignment: const Alignment(0, -0.12),
                    child: Text(
                      '${(value * 100).round()}%',
                      style: AppTextStyles.homeMetabolicGaugeValue,
                    ),
                  ),
                  // Etiket — yayın başlangıç/bitiş boşluğunda (alt açık kısım).
                  Align(
                    alignment: const Alignment(0, 0.92),
                    child: Text(
                      labelKey.tr(),
                      style: AppTextStyles.homeMetabolicGaugeLabel,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Altı açık 240° yay — etiket başlangıç/bitiş arasında.
final class _MetabolicArcPainter extends CustomPainter {
  const _MetabolicArcPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
  });

  final double progress;
  final Color progressColor;
  final Color trackColor;

  static const _stroke = 12.0;

  /// Altta 120° boşluk; yay 150° → 390° (240° sweep).
  static const _startAngle = 150 * math.pi / 180;
  static const _sweepAngle = 240 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - _stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackShadow = Paint()
      ..color = const Color(0x1F000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
      ..isAntiAlias = true;
    canvas.drawArc(
      rect.shift(const Offset(0, 1.2)),
      _startAngle,
      _sweepAngle,
      false,
      trackShadow,
    );

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawArc(rect, _startAngle, _sweepAngle, false, trackPaint);

    final highlight = Paint()
      ..color = ColorName.colorWhite.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    final highlightRect = Rect.fromCircle(
      center: Offset(center.dx, center.dy - 0.8),
      radius: radius - _stroke / 2 + 0.5,
    );
    canvas.drawArc(highlightRect, _startAngle, _sweepAngle, false, highlight);

    if (progress <= 0.001) return;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawArc(
      rect,
      _startAngle,
      _sweepAngle * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MetabolicArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
