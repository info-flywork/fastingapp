import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _motion = Duration(milliseconds: 280);
const _circle = 80.0;
const _connector = 48.0;

/// Oruç sekmesindeki vücut kartından açılan aşama durumu.
final class FastingBodyStatusView extends StatefulWidget {
  const FastingBodyStatusView({super.key});

  @override
  State<FastingBodyStatusView> createState() => _FastingBodyStatusViewState();
}

class _FastingBodyStatusViewState extends State<FastingBodyStatusView> {
  final _scroll = ScrollController();
  var _step = 0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _select(int index) {
    setState(() => _step = index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      const stride = _circle + _connector;
      final viewport = _scroll.position.viewportDimension;
      final target = (index * stride + _circle / 2 - viewport / 2).clamp(
        0.0,
        _scroll.position.maxScrollExtent,
      );
      _scroll.animateTo(target, duration: _motion, curve: Curves.easeOutCubic);
    });
  }

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
            _Stepper(step: _step, scroll: _scroll, onTap: _select),
            const SizedBox(height: 20),
            _AnimatedCopy(step: _step),
          ],
        ),
      ),
    );
  }
}

final class _Stage {
  const _Stage({
    required this.reached,
    required this.idle,
    required this.rangeKey,
    required this.titleKey,
    required this.bodyKey,
  });

  final AssetGenImage reached;
  final AssetGenImage idle;
  final String rangeKey;
  final String titleKey;
  final String bodyKey;
}

/// Renkli `*_light` geçilen aşama, gri düz dosya henüz gelmeyen.
final _stages = <_Stage>[
  _Stage(
    reached: Assets.images.a1Light,
    idle: Assets.images.a1,
    rangeKey: 'body_status.range_1',
    titleKey: 'body_status.title_1',
    bodyKey: 'body_status.body_1',
  ),
  _Stage(
    reached: Assets.images.a2Light,
    idle: Assets.images.a2,
    rangeKey: 'body_status.range_2',
    titleKey: 'body_status.title_2',
    bodyKey: 'body_status.body_2',
  ),
  _Stage(
    reached: Assets.images.a3Light,
    idle: Assets.images.a3,
    rangeKey: 'body_status.range_3',
    titleKey: 'body_status.title_3',
    bodyKey: 'body_status.body_3',
  ),
  _Stage(
    reached: Assets.images.a4Light,
    idle: Assets.images.a4,
    rangeKey: 'body_status.range_4',
    titleKey: 'body_status.title_4',
    bodyKey: 'body_status.body_4',
  ),
  _Stage(
    reached: Assets.images.a5Light,
    idle: Assets.images.a5,
    rangeKey: 'body_status.range_5',
    titleKey: 'body_status.title_5',
    bodyKey: 'body_status.body_5',
  ),
  _Stage(
    reached: Assets.images.a6Light,
    idle: Assets.images.a6,
    rangeKey: 'body_status.range_6',
    titleKey: 'body_status.title_6',
    bodyKey: 'body_status.body_6',
  ),
  _Stage(
    reached: Assets.images.a7Light,
    idle: Assets.images.a7,
    rangeKey: 'body_status.range_7',
    titleKey: 'body_status.title_7',
    bodyKey: 'body_status.body_7',
  ),
  _Stage(
    reached: Assets.images.a8Light,
    idle: Assets.images.a8,
    rangeKey: 'body_status.range_8',
    titleKey: 'body_status.title_8',
    bodyKey: 'body_status.body_8',
  ),
  _Stage(
    reached: Assets.images.a9Light,
    idle: Assets.images.a9,
    rangeKey: 'body_status.range_9',
    titleKey: 'body_status.title_9',
    bodyKey: 'body_status.body_9',
  ),
];

final class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text('body_status.title'.tr(), style: AppTextStyles.fastingMealTitle),
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
  const _Stepper({
    required this.step,
    required this.scroll,
    required this.onTap,
  });

  final int step;
  final ScrollController scroll;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      controller: scroll,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < _stages.length; i++) ...[
            if (i > 0)
              SizedBox(
                width: _connector,
                child: _StepLine(solid: step >= i),
              ),
            _StepCircle(
              stage: _stages[i],
              reached: i <= step,
              partial: i == step && i < _stages.length - 1,
              ringOnLeft: i > 0,
              onTap: () => onTap(i),
            ),
          ],
        ],
      ),
    );
  }
}

final class _StepLine extends StatelessWidget {
  const _StepLine({required this.solid});

  final bool solid;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: ColorName.colorPlanArcTrack),
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
    required this.stage,
    required this.reached,
    required this.partial,
    required this.ringOnLeft,
    required this.onTap,
  });

  final _Stage stage;
  final bool reached;
  final bool partial;
  final bool ringOnLeft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _circle,
        height: _circle,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const SizedBox(
              width: _circle,
              height: _circle,
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
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: stage.idle.image(fit: BoxFit.contain),
              ),
            ),
            AnimatedOpacity(
              opacity: reached ? 1 : 0,
              duration: _motion,
              curve: Curves.easeOutCubic,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: stage.reached.image(fit: BoxFit.contain),
              ),
            ),
            _LineFade(
              visible: partial,
              child: SizedBox(
                width: _circle,
                height: _circle,
                child: CustomPaint(
                  painter: _PartialRingPainter(onLeft: ringOnLeft),
                ),
              ),
            ),
            _LineFade(
              visible: reached && !partial,
              child: const SizedBox(
                width: _circle,
                height: _circle,
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
          if (!mounted || generation != _generation) return;
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
        child: _Copy(step: _visibleStep),
      ),
    );
  }
}

final class _Copy extends StatelessWidget {
  const _Copy({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final stage = _stages[step];
    final paragraphs = stage.bodyKey.tr().split('\n\n');
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: ColorName.colorWhite,
            borderRadius: BorderRadius.circular(99999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              stage.rangeKey.tr(),
              style: AppTextStyles.fastingBreakTitle,
            ),
          ),
        ),
        const SizedBox(height: 20),
        DecoratedBox(
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
                  stage.titleKey.tr(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.fastingMealTitle,
                ),
                for (final paragraph in paragraphs) ...[
                  const SizedBox(height: 24),
                  Text(paragraph, style: AppTextStyles.eatingWindowBody),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
