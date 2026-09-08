import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Onboarding üst bar: geri + yüzde metni + animasyonlu progress.
///
/// [targetProgress] 0–1 arası (ör. 0.10 = %10).
/// Animasyon, rota geçişi bittikten sonra başlar ([startDelay]).
final class OnboardingProgressHeader extends StatefulWidget {
  const OnboardingProgressHeader({
    required this.targetProgress,
    this.fromProgress = 0,
    this.onBack,
    this.animationDuration = const Duration(milliseconds: 750),
    this.startDelay = const Duration(milliseconds: 240),
    super.key,
  });

  /// Animasyon bitiş değeri (0–1).
  final double targetProgress;

  /// Animasyon başlangıç değeri (0–1). Örn. 0.10 → 0.20.
  final double fromProgress;
  final VoidCallback? onBack;
  final Duration animationDuration;

  /// Sayfa push animasyonu bitene kadar bekleme.
  final Duration startDelay;

  @override
  State<OnboardingProgressHeader> createState() =>
      _OnboardingProgressHeaderState();
}

class _OnboardingProgressHeaderState extends State<OnboardingProgressHeader>
    with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(covariant OnboardingProgressHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetProgress != widget.targetProgress ||
        oldWidget.fromProgress != widget.fromProgress) {
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
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, _) {
        final value =
            widget.fromProgress +
            (widget.targetProgress - widget.fromProgress) * _curve.value;
        final percent = (value * 100).round();

        return Column(
          children: [
            SizedBox(
              height: 20,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.onBack != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: widget.onBack,
                        behavior: HitTestBehavior.opaque,
                        child: Transform.flip(
                          flipX: true,
                          child: SvgPicture.asset(
                            Assets.icons.solarArrowLeftLinear.path,
                            colorFilter: const ColorFilter.mode(
                              ColorName.colorTitle,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 44),
                    child: Text.rich(
                      TextSpan(
                        style: AppTextStyles.progressLabel,
                        children: [
                          TextSpan(text: 'onboarding.plan_ready_before'.tr()),
                          TextSpan(
                            text: '$percent%',
                            style: AppTextStyles.progressLabelEmphasis,
                          ),
                          TextSpan(text: 'onboarding.plan_ready_after'.tr()),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _ProgressTrack(progress: value),
          ],
        );
      },
    );
  }
}

final class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({required this.progress});

  final double progress;

  static const _trackHeight = 12.0;
  static const _headSize = 32.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final fillWidth = (width * progress).clamp(_headSize / 2, width);
        final headLeft = (fillWidth - _headSize / 2).clamp(
          0.0,
          width - _headSize,
        );
        return SizedBox(
          height: _trackHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              // Track
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: ColorName.colorBlack.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              // Fill
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: fillWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [
                        ColorName.colorProgressFillStart,
                        ColorName.colorProgressFillEnd,
                      ],
                    ),
                  ),
                ),
              ),
              // Head — track üzerinde ortalı, layout yüksekliğine eklemez
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
  }
}
