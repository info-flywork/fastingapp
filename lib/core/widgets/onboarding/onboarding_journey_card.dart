import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Highlight ekranındaki kilo yolculuğu kartı.
///
/// Sol = başlangıç / mevcut kilo, sağ = hedef.
/// [targetProgress] 0–1; 0’dan bu değere animasyonla ilerler.
final class OnboardingJourneyCard extends StatefulWidget {
  const OnboardingJourneyCard({
    required this.currentWeightKg,
    required this.goalWeightKg,
    required this.footer,
    required this.targetProgress,
    this.animationDuration = const Duration(milliseconds: 750),
    this.startDelay = const Duration(milliseconds: 240),
    super.key,
  });

  /// Şu anki kilo (etiket sol).
  final double currentWeightKg;

  /// Hedef kilo (etiket sağ).
  final double goalWeightKg;

  /// Animasyon bitiş oranı (0–1).
  final double targetProgress;

  final String footer;
  final Duration animationDuration;
  final Duration startDelay;

  /// 0 = start’ta, 1 = hedefe ulaşılmış.
  static double progressBetween({
    required double startKg,
    required double currentKg,
    required double goalKg,
  }) {
    final span = startKg - goalKg;
    if (span.abs() < 0.05) return 0;
    return ((startKg - currentKg) / span).clamp(0.0, 1.0);
  }

  @override
  State<OnboardingJourneyCard> createState() => _OnboardingJourneyCardState();
}

class _OnboardingJourneyCardState extends State<OnboardingJourneyCard>
    with SingleTickerProviderStateMixin {
  static const _trackHeight = 12.0;
  static const _headSize = 28.0;

  late final AnimationController _controller;
  late final Animation<double> _curve;
  int _forwardGeneration = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
    _scheduleForward();
  }

  Future<void> _scheduleForward() async {
    final generation = ++_forwardGeneration;
    _controller
      ..duration = widget.animationDuration
      ..value = 0;
    final delay = widget.startDelay;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
      if (!mounted || generation != _forwardGeneration) return;
    }
    await _controller.forward();
  }

  @override
  void didUpdateWidget(covariant OnboardingJourneyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentWeightKg != widget.currentWeightKg ||
        oldWidget.goalWeightKg != widget.goalWeightKg ||
        oldWidget.targetProgress != widget.targetProgress) {
      _scheduleForward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.targetProgress.clamp(0.0, 1.0);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.currentWeightKg.toStringAsFixed(1)} kg',
                  style: AppTextStyles.journeyWeightCurrent,
                ),
                Text(
                  '${widget.goalWeightKg.toStringAsFixed(1)} kg',
                  style: AppTextStyles.journeyWeightGoal,
                ),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: _curve,
              builder: (context, _) {
                final progress = target * _curve.value;
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final fillWidth = (width * progress).clamp(0.0, width);
                    final headLeft = progress <= 0
                        ? 0.0
                        : (fillWidth - _headSize / 2).clamp(
                            0.0,
                            width - _headSize,
                          );

                    return SizedBox(
                      height: _trackHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: ColorName.colorBlack.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          if (fillWidth > 0)
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: fillWidth,
                              child: const DecoratedBox(
                                decoration: BoxDecoration(
                                  color: ColorName.colorWhite,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            left: headLeft,
                            top: (_trackHeight - _headSize) / 2,
                            child: Image.asset(
                              Assets.images.progressHead.path,
                              width: _headSize,
                              height: _headSize,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 10),
            Text(
              widget.footer,
              textAlign: TextAlign.center,
              style: AppTextStyles.journeyFooter,
            ),
          ],
        ),
      ),
    );
  }
}
