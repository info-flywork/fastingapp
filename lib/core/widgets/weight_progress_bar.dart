import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Home / Body History ortak kilo ilerleme çubuğu (20h, turuncu fill).
final class WeightProgressBar extends StatelessWidget {
  const WeightProgressBar({required this.progress, super.key});

  final double progress;

  static const _height = 20.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, _) {
        return SizedBox(
          height: _height,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ColorName.colorStepsTrack,
              borderRadius: BorderRadius.circular(99999),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99999),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: animatedProgress,
                  heightFactor: 1,
                  child: const ColoredBox(color: ColorName.colorStepsFill),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
