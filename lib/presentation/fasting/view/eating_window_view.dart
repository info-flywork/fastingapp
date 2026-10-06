import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _motion = Duration(milliseconds: 280);

/// Oruç sekmesindeki öğün kartından açılan öğün penceresi.
final class EatingWindowView extends StatefulWidget {
  const EatingWindowView({super.key});

  @override
  State<EatingWindowView> createState() => _EatingWindowViewState();
}

class _EatingWindowViewState extends State<EatingWindowView> {
  var _step = 0;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: ColorName.colorProfileBack,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 24),
          children: [
            const _Header(),
            const SizedBox(height: 28),
            _Stepper(
              step: _step,
              onTap: (index) => setState(() => _step = index),
            ),
            const SizedBox(height: 28),
            _AnimatedCopy(step: _step),
          ],
        ),
      ),
    );
  }
}

final class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'eating_window.title'.tr(),
            style: AppTextStyles.fastingMealTitle,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: _BackButton(onTap: () => context.pop()),
          ),
        ],
      ),
    );
  }
}

final class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: ColorName.colorBlack.withValues(alpha: 0.05),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: Transform.rotate(
                angle: math.pi,
                child: Assets.icons.solarAltArrowLeftLinear.svg(
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    ColorName.colorTitle,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _Stepper extends StatelessWidget {
  const _Stepper({required this.step, required this.onTap});

  final int step;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final images = [
      AppImages.breakYourFast,
      AppImages.keepNoruish,
      AppImages.nextFast,
    ];
    final dimmed = [
      AppImages.breakYourFast,
      AppImages.darkNorusih,
      AppImages.darkFast,
    ];
    // Renkli haller 80. Başlamamış fotoğraflar biraz daha küçük.
    const dimmedScales = [1.0, 0.78, 0.78];
    return Row(
      children: [
        for (var i = 0; i < images.length; i++) ...[
          if (i > 0)
            Expanded(
              child: _StepLine(
                solid: step >= i,
                fade: step == 0 && step == i - 1,
              ),
            ),
          _StepCircle(
            colorImage: images[i],
            dimmedImage: dimmed[i],
            reached: i <= step,
            partial: i == step,
            ringOnLeft: i > 0,
            coverScale: dimmedScales[i],
            onTap: () => onTap(i),
          ),
        ],
      ],
    );
  }
}

final class _StepLine extends StatelessWidget {
  const _StepLine({required this.solid, required this.fade});

  final bool solid;
  final bool fade;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _LineFade(
            visible: !solid && !fade,
            child: const ColoredBox(color: ColorName.colorPlanArcTrack),
          ),
          _LineFade(
            visible: fade,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorName.colorMealPositive,
                    ColorName.colorProfileBack,
                  ],
                ),
              ),
            ),
          ),
          _LineFade(
            visible: solid,
            child: const ColoredBox(color: ColorName.colorMealPositive),
          ),
        ],
      ),
    );
  }
}

final class _LineFade extends StatelessWidget {
  const _LineFade({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: _motion,
      curve: Curves.easeOutCubic,
      child: child,
    );
  }
}

final class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.colorImage,
    required this.dimmedImage,
    required this.reached,
    required this.partial,
    required this.ringOnLeft,
    required this.coverScale,
    required this.onTap,
  });

  final AppImageAsset colorImage;
  final AppImageAsset dimmedImage;
  final bool reached;
  final bool partial;
  final bool ringOnLeft;
  final double coverScale;
  final VoidCallback onTap;

  static const _size = 80.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _size,
        height: _size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const SizedBox(
              width: _size,
              height: _size,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: ColorName.colorWhite,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: reached ? 0 : 1,
              duration: _motion,
              curve: Curves.easeOutCubic,
              child: AnimatedScale(
                scale: reached ? 1 : coverScale,
                duration: _motion,
                curve: Curves.easeOutCubic,
                child: dimmedImage.image(
                  width: _size,
                  height: _size,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: reached ? 1 : 0,
              duration: _motion,
              curve: Curves.easeOutCubic,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: colorImage.image(fit: BoxFit.contain),
              ),
            ),
            _LineFade(
              visible: partial,
              child: SizedBox(
                width: _size,
                height: _size,
                child: CustomPaint(
                  painter: _PartialRingPainter(onLeft: ringOnLeft),
                ),
              ),
            ),
            _LineFade(
              visible: reached && !partial,
              child: const SizedBox(
                width: _size,
                height: _size,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(color: ColorName.colorMealPositive, width: 2),
                    ),
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

final class _PartialRingPainter extends CustomPainter {
  const _PartialRingPainter({required this.onLeft});

  final bool onLeft;

  @override
  void paint(Canvas canvas, Size size) {
    const green = ColorName.colorMealPositive;
    final clear = green.withValues(alpha: 0);
    final rect = Offset.zero & size;
    // 0 sağda. Solda sağ alt boyasız; yeşil sol alt ve sol üstte.
    final colors = onLeft
        ? [clear, clear, green, green, green, clear, clear]
        : [green, green, clear, clear, clear, green, green];
    final stops = onLeft
        ? const [0.0, 0.25, 0.34, 0.5, 0.66, 0.78, 1.0]
        : const [0.0, 0.18, 0.28, 0.5, 0.72, 0.82, 1.0];
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = SweepGradient(colors: colors, stops: stops).createShader(rect);
    canvas.drawCircle(
      size.center(Offset.zero),
      size.shortestSide / 2 - 1,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _PartialRingPainter oldDelegate) =>
      oldDelegate.onLeft != onLeft;
}

final class _AnimatedCopy extends StatefulWidget {
  const _AnimatedCopy({required this.step});

  final int step;

  @override
  State<_AnimatedCopy> createState() => _AnimatedCopyState();
}

class _AnimatedCopyState extends State<_AnimatedCopy>
    with SingleTickerProviderStateMixin {
  late int _visibleStep;
  late final AnimationController _controller;
  var _generation = 0;

  @override
  void initState() {
    super.initState();
    _visibleStep = widget.step;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant _AnimatedCopy oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step != widget.step) {
      _swap();
    }
  }

  void _swap() {
    final generation = ++_generation;
    _controller
        .animateTo(
          0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
        )
        .then((_) {
          if (!mounted || generation != _generation) {
            return;
          }
          setState(() => _visibleStep = widget.step);
          _controller.animateTo(
            1,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
          );
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _controller.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _controller.value) * 8),
            child: child,
          ),
        );
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: _CopyCard(step: _visibleStep),
      ),
    );
  }
}

final class _CopyCard extends StatelessWidget {
  const _CopyCard({required this.step});

  final int step;

  static const _titleKeys = [
    'eating_window.break_title',
    'eating_window.nourish_title',
    'eating_window.next_title',
  ];

  static const _bodyKeys = [
    'eating_window.break_body',
    'eating_window.nourish_body',
    'eating_window.next_body',
  ];

  @override
  Widget build(BuildContext context) {
    final paragraphs = _bodyKeys[step].tr().split('\n\n');
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _titleKeys[step].tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.fastingMealTitle,
            ),
            for (final paragraph in paragraphs) ...[
              const SizedBox(height: 24),
              Text.rich(
                TextSpan(children: _spans(paragraph)),
                textAlign: TextAlign.start,
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<InlineSpan> _spans(String text) {
    final parts = text.split('**');
    return [
      for (var i = 0; i < parts.length; i++)
        TextSpan(
          text: parts[i],
          style: i.isOdd
              ? AppTextStyles.eatingWindowBodyStrong
              : AppTextStyles.eatingWindowBody,
        ),
    ];
  }
}
