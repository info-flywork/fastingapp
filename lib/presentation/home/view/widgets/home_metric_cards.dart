part of '../home_view.dart';

/// Su ve adım metrik kartları (yan yana).
final class HomeMetricCards extends StatelessWidget {
  const HomeMetricCards({
    required this.onWaterTapped,
    required this.onStepsTapped,
    super.key,
  });

  final VoidCallback onWaterTapped;
  final VoidCallback onStepsTapped;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _MetricCard(
              icon: AppImages.water,
              labelKey: 'home.water',
              value: 600,
              goal: 2500,
              valueKey: 'home.water_value',
              goalKey: 'home.water_goal',
              trackColor: ColorName.colorWaterTrack,
              fillColor: ColorName.colorWaterFill,
              progress: 600 / 2500,
              liquid: true,
              onTap: onWaterTapped,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MetricCard(
              icon: AppImages.steps,
              labelKey: 'home.steps',
              value: 1000,
              goal: 8000,
              valueKey: 'home.steps_value',
              goalKey: 'home.steps_goal',
              trackColor: ColorName.colorStepsTrack,
              fillColor: ColorName.colorStepsFill,
              progress: 1000 / 8000,
              onTap: onStepsTapped,
            ),
          ),
        ],
      ),
    );
  }
}

final class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.labelKey,
    required this.value,
    required this.goal,
    required this.valueKey,
    required this.goalKey,
    required this.trackColor,
    required this.fillColor,
    required this.progress,
    this.liquid = false,
    this.onTap,
  });

  final AppImageAsset icon;
  final String labelKey;
  final int value;
  final int goal;
  final String valueKey;
  final String goalKey;
  final Color trackColor;
  final Color fillColor;
  final double progress;
  final bool liquid;
  final VoidCallback? onTap;

  static const _iconSize = 40.0;
  static const _radius = 20.0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorName.colorWhite,
      borderRadius: BorderRadius.circular(_radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  icon.image(
                    width: _iconSize,
                    height: _iconSize,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      labelKey.tr(),
                      style: AppTextStyles.homeMetricLabel,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: ColorName.colorTitle,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: valueKey.tr(args: ['$value']),
                      style: AppTextStyles.homeMetricValue.copyWith(
                        color: const Color(0xFF1C1C21),
                      ),
                    ),
                    TextSpan(
                      text: goalKey.tr(args: ['$goal']),
                      style: AppTextStyles.homeMetricGoal,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (liquid)
                _AnimatedLiquidBar(
                  progress: progress,
                  trackColor: trackColor,
                  fillColor: fillColor,
                )
              else
                _FlatProgressBar(
                  progress: progress,
                  trackColor: trackColor,
                  fillColor: fillColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Adım — düz capsule; ilk açılışta dolma animasyonu.
final class _FlatProgressBar extends StatelessWidget {
  const _FlatProgressBar({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
  });

  final double progress;
  final Color trackColor;
  final Color fillColor;

  static const height = 35.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, _) {
        return SizedBox(
          height: height,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: animatedProgress,
                  heightFactor: 1,
                  child: ColoredBox(color: fillColor),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Su — sıvı dolgu, animasyonlu S-kenar + highlight + hafif kabarcık.
final class _AnimatedLiquidBar extends StatefulWidget {
  const _AnimatedLiquidBar({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
  });

  final double progress;
  final Color trackColor;
  final Color fillColor;

  @override
  State<_AnimatedLiquidBar> createState() => _AnimatedLiquidBarState();
}

class _AnimatedLiquidBarState extends State<_AnimatedLiquidBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave;

  static const height = 35.0;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: widget.progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, _) {
        return AnimatedBuilder(
          animation: _wave,
          builder: (context, _) {
            return SizedBox(
              height: height,
              width: double.infinity,
              child: CustomPaint(
                painter: _LiquidBarPainter(
                  progress: animatedProgress,
                  phase: _wave.value * math.pi * 2,
                  trackColor: widget.trackColor,
                  fillColor: widget.fillColor,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

final class _LiquidBarPainter extends CustomPainter {
  const _LiquidBarPainter({
    required this.progress,
    required this.phase,
    required this.trackColor,
    required this.fillColor,
  });

  final double progress;
  final double phase;
  final Color trackColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final track = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );
    canvas.drawRRect(track, Paint()..color = trackColor);

    if (progress <= 0.001) return;

    canvas.save();
    canvas.clipRRect(track);

    final h = size.height;
    final fillW = size.width * progress;
    final amp = math.min(h * 0.28, fillW * 0.45);

    // Sıvı gövde — sağ kenar animasyonlu S.
    final fillPath = Path()..moveTo(0, 0);
    const steps = 40;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final y = h * t;
      final wave =
          math.sin(t * math.pi * 1.6 + phase) * amp * 0.55 +
          math.sin(t * math.pi * 0.8 - phase * 0.7) * amp * 0.25;
      fillPath.lineTo(fillW + wave, y);
    }
    fillPath
      ..lineTo(0, h)
      ..close();

    // Dolgu — hafif dikey gradient.
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Color.lerp(fillColor, const Color(0xFF3A6FD6), 0.12)!,
          fillColor,
          Color.lerp(fillColor, Colors.white, 0.12)!,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, fillW + amp, h));
    canvas.drawPath(fillPath, fillPaint);

    // Kenar highlight — beyaz S şerit (animasyonlu).
    final highlight = Path();
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final y = h * t;
      final wave =
          math.sin(t * math.pi * 1.6 + phase) * amp * 0.55 +
          math.sin(t * math.pi * 0.8 - phase * 0.7) * amp * 0.25;
      final x = fillW + wave - h * 0.12;
      if (i == 0) {
        highlight.moveTo(x, y);
      } else {
        highlight.lineTo(x, y);
      }
    }
    canvas.drawPath(
      highlight,
      Paint()
        ..color = const Color(0x99FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2.2, h * 0.08)
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );

    // Yüzey parıltısı.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, fillW * 0.85, h * 0.28),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.22),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, fillW, h * 0.28)),
    );

    // Kabarcıklar — dolgu içinde yavaş yükselir.
    final bubblePaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 5; i++) {
      final seed = i * 17.3;
      final bx = fillW * (0.12 + (i * 0.15) % 0.7);
      if (bx > fillW - 4) continue;
      final rise = ((phase / (math.pi * 2)) + seed * 0.07) % 1.0;
      final by = h * (1.05 - rise * 1.15);
      final r = 1.2 + (i % 3) * 0.7;
      bubblePaint.color = Colors.white.withValues(alpha: 0.18 + (i % 2) * 0.08);
      canvas.drawCircle(Offset(bx, by), r, bubblePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LiquidBarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.phase != phase ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.fillColor != fillColor;
  }
}
