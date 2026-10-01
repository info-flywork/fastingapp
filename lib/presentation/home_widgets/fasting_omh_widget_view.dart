import 'dart:ui';

import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/generated/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Today home widget — mint zemin, zen mascot, Let's do this.
final class FastingOmhWidgetView extends StatelessWidget {
  const FastingOmhWidgetView({
    required this.todayLabel,
    required this.planLabel,
    required this.windowLabel,
    required this.cheerLabel,
    super.key,
  });

  final String todayLabel;
  final String planLabel;
  final String windowLabel;
  final String cheerLabel;

  /// Medium oranına uyumlu — 658 × 310.
  static const logicalSize = Size(658, 310);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: logicalSize.width,
      height: logicalSize.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ColorName.colorWhite,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: ColorName.colorWaterRulerTick),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(39)),
          child: Stack(
            children: [
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x337ACE6B), // #7ACE6B @ 20%
                ),
              ),
              Positioned(
                right: 40,
                top: 16,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorName.colorCtaGradientBottom.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 28, 32, 28),
                child: SizedBox(
                  width: 320,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Logo(),
                      const SizedBox(height: 14),
                      Text(todayLabel, style: _today),
                      const SizedBox(height: 12),
                      Text(planLabel, style: _plan),
                      const SizedBox(height: 8),
                      Text(windowLabel, style: _secondary),
                      const Spacer(),
                      Text(cheerLabel, style: _secondary),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 8,
                bottom: 0,
                child: Assets.images.mascotOmh.image(
                  height: 260,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        style: _logo,
        children: [
          TextSpan(
            text: 'Mochi',
            style: TextStyle(color: ColorName.colorTitle),
          ),
          TextSpan(
            text: 'Fast',
            style: TextStyle(color: ColorName.colorCtaGradientBottom),
          ),
        ],
      ),
    );
  }
}

const _logo = TextStyle(
  fontFamily: FontFamily.baloo,
  fontSize: 28,
  height: 24 / 28,
  letterSpacing: 28 * -0.015,
);

const _today = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w600,
  fontSize: 32,
  height: 1.2,
  letterSpacing: -0.5,
  color: ColorName.colorTitle,
);

const _plan = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w700,
  fontSize: 56,
  height: 1.1,
  letterSpacing: -0.5,
  color: ColorName.colorTitle,
);

const _secondary = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w500,
  fontSize: 22,
  height: 1.2,
  color: ColorName.colorSubtitle,
);
