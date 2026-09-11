import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Plan oluşturma ekranındaki yeşil progress track.
final class BuildingPlanProgressBar extends StatelessWidget {
  const BuildingPlanProgressBar({
    required this.progress,
    this.showHead = true,
    super.key,
  });

  final double progress;
  final bool showHead;

  static const _trackHeight = 25.0;
  static const _headSize = 61.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final t = progress.clamp(0.0, 1.0);
        final tip = width * t;
        final fillWidth = tip.clamp(0.0, width);
        // Head merkezi progress ucunda; %100’de sağ kenara oturur (yarı taşabilir).
        final headLeft = (tip - _headSize / 2).clamp(0.0, width - _headSize / 2);
        final stackHeight = showHead ? _headSize : _trackHeight;
        final trackTop = (stackHeight - _trackHeight) / 2;

        return SizedBox(
          height: stackHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: trackTop,
                height: _trackHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: ColorName.colorBlack.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: trackTop,
                height: _trackHeight,
                width: fillWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: ColorName.colorPlanBuildFill,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: ColorName.colorWhite.withValues(alpha: 0.55),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                        blurStyle: BlurStyle.inner,
                      ),
                    ],
                  ),
                ),
              ),
              if (showHead && t > 0)
                Positioned(
                  left: headLeft,
                  top: 0,
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
