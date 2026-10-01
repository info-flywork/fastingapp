import 'dart:math' as math;

import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';

/// Home / Finish ortak flip clock birimi (saat, dakika, saniye).
final class FlipClockUnit extends StatefulWidget {
  const FlipClockUnit({required this.value, required this.label, super.key});

  final int value;
  final String label;

  /// Figma Rectangle 3/4 — 60.9 × 25.73, radius 3.7, #F6F6F6
  static const halfWidth = 60.9;
  static const halfHeight = 25.73;
  static const gap = 2.0;
  static const hingeSize = 10.0;
  static const halfRadius = 3.7;
  static const fullHeight = halfHeight * 2 + gap;

  @override
  State<FlipClockUnit> createState() => _FlipClockUnitState();
}

class _FlipClockUnitState extends State<FlipClockUnit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late int _current;
  late int _previous;

  @override
  void initState() {
    super.initState();
    _current = widget.value;
    _previous = widget.value;
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 520),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() => _previous = _current);
          }
        });
  }

  @override
  void didUpdateWidget(covariant FlipClockUnit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    _previous = _current;
    _current = widget.value;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: FlipClockUnit.halfWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: FlipClockUnit.halfWidth,
            height: FlipClockUnit.fullHeight,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = Curves.easeIn.transform(_controller.value);
                final angle = t * math.pi;
                final flipping =
                    _controller.isAnimating ||
                    (_controller.value > 0 && _controller.value < 1);
                final bottomValue = flipping && angle < math.pi / 2
                    ? _previous
                    : _current;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      children: [
                        _FlipHalf(isTop: true, value: _current),
                        const SizedBox(height: FlipClockUnit.gap),
                        _FlipHalf(isTop: false, value: bottomValue),
                      ],
                    ),
                    if (flipping && angle <= math.pi / 2)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: FlipClockUnit.halfHeight,
                        child: Transform(
                          alignment: Alignment.bottomCenter,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.002)
                            ..rotateX(angle),
                          child: _FlipHalf(
                            isTop: true,
                            value: _previous,
                            shade: true,
                          ),
                        ),
                      ),
                    if (flipping && angle > math.pi / 2)
                      Positioned(
                        top: FlipClockUnit.halfHeight + FlipClockUnit.gap,
                        left: 0,
                        right: 0,
                        height: FlipClockUnit.halfHeight,
                        child: Transform(
                          alignment: Alignment.topCenter,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.002)
                            ..rotateX(angle - math.pi),
                          child: _FlipHalf(
                            isTop: false,
                            value: _current,
                            shade: true,
                          ),
                        ),
                      ),
                    const Positioned(
                      left: -FlipClockUnit.hingeSize / 2,
                      top: 0,
                      bottom: 0,
                      child: _FlipHinge(),
                    ),
                    const Positioned(
                      right: -FlipClockUnit.hingeSize / 2,
                      top: 0,
                      bottom: 0,
                      child: _FlipHinge(),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.homeFlipUnit,
          ),
        ],
      ),
    );
  }
}

final class _FlipHalf extends StatelessWidget {
  const _FlipHalf({
    required this.isTop,
    required this.value,
    this.shade = false,
  });

  final bool isTop;
  final int value;
  final bool shade;

  @override
  Widget build(BuildContext context) {
    final digit = Text(
      value.toString().padLeft(2, '0'),
      style: AppTextStyles.homeFlipDigits,
    );

    return SizedBox(
      width: FlipClockUnit.halfWidth,
      height: FlipClockUnit.halfHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: isTop
              ? const Radius.circular(FlipClockUnit.halfRadius)
              : Radius.zero,
          bottom: isTop
              ? Radius.zero
              : const Radius.circular(FlipClockUnit.halfRadius),
        ),
        child: Stack(
          children: [
            const ColoredBox(
              color: ColorName.colorFlipClock,
              child: SizedBox.expand(),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: isTop ? 0 : -(FlipClockUnit.halfHeight + FlipClockUnit.gap),
              height: FlipClockUnit.fullHeight,
              child: Center(child: digit),
            ),
            if (shade)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: isTop
                          ? Alignment.topCenter
                          : Alignment.bottomCenter,
                      end: isTop ? Alignment.bottomCenter : Alignment.topCenter,
                      colors: [
                        ColorName.colorTitle.withValues(alpha: 0.18),
                        ColorName.colorTitle.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

final class _FlipHinge extends StatelessWidget {
  const _FlipHinge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 10,
        height: 10,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: ColorName.colorWhite,
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 2,
              height: 2,
              decoration: const BoxDecoration(
                color: ColorName.colorTitle,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 1.5),
            Container(
              width: 2,
              height: 2,
              decoration: const BoxDecoration(
                color: ColorName.colorTitle,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
