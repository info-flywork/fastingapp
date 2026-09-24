import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/fasting/view/fasting_feeling_better_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Kısa yürüyüş — 3 dakikalık sayaç.
final class FastingQuickWalkView extends StatefulWidget {
  const FastingQuickWalkView({required this.bodyKey, super.key});

  final String bodyKey;

  @override
  State<FastingQuickWalkView> createState() => _FastingQuickWalkViewState();
}

const _walkSeconds = 180;

class _FastingQuickWalkViewState extends State<FastingQuickWalkView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  bool _celebrating = false;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _walkSeconds),
    )..addStatusListener(_onProgress);
  }

  void _onProgress(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() => _celebrating = true);
  }

  @override
  void dispose() {
    _progress
      ..removeStatusListener(_onProgress)
      ..dispose();
    super.dispose();
  }

  void _toggle() {
    if (_progress.isCompleted) return;
    if (_progress.isAnimating) {
      _progress.stop();
    } else {
      _progress.forward();
    }
    setState(() {});
  }

  String get _actionLabel {
    if (_progress.isAnimating) return 'fasting_struggle.walk_stop'.tr();
    if (_progress.value > 0) return 'fasting_struggle.walk_resume'.tr();
    return 'fasting_struggle.walk_start'.tr();
  }

  @override
  Widget build(BuildContext context) {
    if (_celebrating) return const FastingFeelingBetterView();
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: ColorName.colorWhite,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 24),
          children: [
            const _BackRow(),
            const SizedBox(height: 40),
            Center(
              child: Transform.scale(
                scale: 1.1,
                child: Assets.images.mascotQuickWalkt.image(
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'fasting_struggle.says'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.fastingStruggleTitle,
            ),
            const SizedBox(height: 12),
            Text(
              widget.bodyKey.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.fastingStruggleBody,
            ),
            const SizedBox(height: 32),
            _WalkCard(
              progress: _progress,
              actionLabel: _actionLabel,
              stopping: _progress.isAnimating,
              onAction: _toggle,
            ),
          ],
        ),
      ),
    );
  }
}

final class _BackRow extends StatelessWidget {
  const _BackRow();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => context.pop(),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Assets.icons.solarArrowLeftLinear1.image(
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 6),
              Text(
                'notifications.back'.tr(),
                style: AppTextStyles.fastingStruggleBack,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _clockFor(double elapsed) {
  final left = (_walkSeconds * (1 - elapsed)).ceil().clamp(0, _walkSeconds);
  final minutes = left ~/ 60;
  final seconds = left % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

final class _WalkCard extends StatelessWidget {
  const _WalkCard({
    required this.progress,
    required this.actionLabel,
    required this.stopping,
    required this.onAction,
  });

  final Animation<double> progress;
  final String actionLabel;
  final bool stopping;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorName.colorBlack.withValues(alpha: 0.05),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Assets.images.quickWalk.image(
              width: 48,
              height: 48,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 10),
            Text(
              'fasting_struggle.walk_session_title'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.fastingStruggleOptionTitle,
            ),
            const SizedBox(height: 10),
            Text(
              'fasting_struggle.walk_session_body'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.fastingStruggleOptionBody,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 134,
              height: 134,
              child: AnimatedBuilder(
                animation: progress,
                builder: (context, _) {
                  final elapsed = progress.value.clamp(0.0, 1.0);
                  return CustomPaint(
                    painter: _WalkRingPainter(progress: elapsed),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _clockFor(elapsed),
                          style: AppTextStyles.fastingWalkClock,
                        ),
                        Text(
                          'fasting_struggle.walk_total'.tr(),
                          style: AppTextStyles.fastingWalkTotal,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 198,
              child: AppButton(
                label: actionLabel,
                onPressed: onAction,
                showIcon: false,
                expand: false,
                decoration: stopping
                    ? AppButtonDecoration.errorStop()
                    : AppButtonDecoration.homeJoin(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _WalkRingPainter extends CustomPainter {
  const _WalkRingPainter({required this.progress});

  final double progress;

  static const _stroke = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - _stroke) / 2;
    final track = Paint()
      ..color = ColorName.colorWaterRulerTick.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    canvas.drawCircle(center, radius, track);
    final amount = progress.clamp(0.0, 1.0);
    if (amount <= 0) return;
    final arc = Paint()
      ..color = ColorName.colorCtaGradientBottom
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * amount,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_WalkRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
