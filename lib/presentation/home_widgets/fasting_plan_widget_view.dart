import 'dart:ui';

import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/generated/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Today's Plan home widget — mint zemin, mascot, Start Fasting.
final class FastingPlanWidgetView extends StatelessWidget {
  const FastingPlanWidgetView({
    required this.title,
    required this.planLabel,
    required this.windowLabel,
    required this.ctaLabel,
    super.key,
  });

  final String title;
  final String planLabel;
  final String windowLabel;
  final String ctaLabel;

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
                right: 48,
                top: 8,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    width: 200,
                    height: 200,
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
                padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 320,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: _title),
                          const SizedBox(height: 4),
                          Text(planLabel, style: _plan),
                          const SizedBox(height: 8),
                          Text(windowLabel, style: _window),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: ColorName.colorCtaGradientBottom,
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                        ),
                        child: Center(child: Text(ctaLabel, style: _cta)),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 12,
                bottom: 78,
                child: AppImages.mascotWidget.image(
                  height: 230,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _title = TextStyle(
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

const _window = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w500,
  fontSize: 22,
  height: 1.2,
  color: ColorName.colorSubtitle,
);

const _cta = TextStyle(
  fontFamily: FontFamily.sFProDisplay,
  fontWeight: FontWeight.w500,
  fontSize: 22,
  height: 1.2,
  color: ColorName.colorWhite,
);
