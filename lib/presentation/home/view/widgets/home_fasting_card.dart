part of '../home_view.dart';

/// Oruç kartı: maskot + flip-clock geri sayım.
final class HomeFastingCard extends StatefulWidget {
  const HomeFastingCard({super.key});

  @override
  State<HomeFastingCard> createState() => _HomeFastingCardState();
}

class _HomeFastingCardState extends State<HomeFastingCard> {
  static const _initial = Duration(hours: 6, minutes: 12, seconds: 39);

  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = _initial;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining.inSeconds <= 0) {
        _timer?.cancel();
        return;
      }
      setState(() => _remaining -= const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: ClipRect(
                  child: Transform.scale(
                    scale: 1.75,
                    child: Assets.images.fork.image(
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text('home.fasting'.tr(), style: AppTextStyles.homeCardTitle),
              const Spacer(),
              Container(
                height: 28,
                padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
                decoration: BoxDecoration(
                  color: ColorName.colorHomeChipBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: ClipOval(
                        child: Transform.scale(
                          scale: 1.85,
                          child: Assets.images.blood.image(
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: ColorName.colorTitle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: ClipRect(
                  child: Transform.scale(
                    scale: 1.21,
                    child: Assets.images.mascotClock.image(
                      width: 96,
                      height: 96,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FlipUnit(value: hours, label: 'home.timer_hrs'.tr()),
                    const SizedBox(width: 10),
                    _FlipUnit(value: minutes, label: 'home.timer_min'.tr()),
                    const SizedBox(width: 10),
                    _FlipUnit(value: seconds, label: 'home.timer_sec'.tr()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _FlipUnit extends StatefulWidget {
  const _FlipUnit({required this.value, required this.label});

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
  State<_FlipUnit> createState() => _FlipUnitState();
}

class _FlipUnitState extends State<_FlipUnit>
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
  void didUpdateWidget(covariant _FlipUnit oldWidget) {
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
      width: _FlipUnit.halfWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _FlipUnit.halfWidth,
            height: _FlipUnit.fullHeight,
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
                        const SizedBox(height: _FlipUnit.gap),
                        _FlipHalf(isTop: false, value: bottomValue),
                      ],
                    ),
                    if (flipping && angle <= math.pi / 2)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: _FlipUnit.halfHeight,
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
                        top: _FlipUnit.halfHeight + _FlipUnit.gap,
                        left: 0,
                        right: 0,
                        height: _FlipUnit.halfHeight,
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
                      left: -_FlipUnit.hingeSize / 2,
                      top: 0,
                      bottom: 0,
                      child: _FlipHinge(),
                    ),
                    const Positioned(
                      right: -_FlipUnit.hingeSize / 2,
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

/// Üst/alt parça: rakamın ilgili yarısını kırpar, boşlukta çizgi bırakmaz.
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
      width: _FlipUnit.halfWidth,
      height: _FlipUnit.halfHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: isTop
              ? const Radius.circular(_FlipUnit.halfRadius)
              : Radius.zero,
          bottom: isTop
              ? Radius.zero
              : const Radius.circular(_FlipUnit.halfRadius),
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
              top: isTop ? 0 : -(_FlipUnit.halfHeight + _FlipUnit.gap),
              height: _FlipUnit.fullHeight,
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
