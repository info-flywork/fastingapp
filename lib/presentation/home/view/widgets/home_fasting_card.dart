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

final class _FlipUnit extends StatelessWidget {
  const _FlipUnit({required this.value, required this.label});

  final int value;
  final String label;

  /// Figma Rectangle 3/4 — 60.9 × 25.73, radius 3.7, #F6F6F6
  static const _halfWidth = 60.9;
  static const _halfHeight = 25.73;
  static const _gap = 2.0;
  static const _hingeSize = 10.0;
  static const _halfRadius = 3.7;

  @override
  Widget build(BuildContext context) {
    final text = value.toString().padLeft(2, '0');
    const fullHeight = _halfHeight * 2 + _gap;
    final digit = Text(text, style: AppTextStyles.homeFlipDigits);

    return SizedBox(
      width: _halfWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _halfWidth,
            height: fullHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    _FlipHalf(
                      isTop: true,
                      fullHeight: fullHeight,
                      digit: digit,
                    ),
                    const SizedBox(height: _gap),
                    _FlipHalf(
                      isTop: false,
                      fullHeight: fullHeight,
                      digit: digit,
                    ),
                  ],
                ),
                const Positioned(
                  left: -_hingeSize / 2,
                  top: 0,
                  bottom: 0,
                  child: _FlipHinge(),
                ),
                const Positioned(
                  right: -_hingeSize / 2,
                  top: 0,
                  bottom: 0,
                  child: _FlipHinge(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
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
    required this.fullHeight,
    required this.digit,
  });

  final bool isTop;
  final double fullHeight;
  final Widget digit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _FlipUnit._halfWidth,
      height: _FlipUnit._halfHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: isTop
              ? const Radius.circular(_FlipUnit._halfRadius)
              : Radius.zero,
          bottom: isTop
              ? Radius.zero
              : const Radius.circular(_FlipUnit._halfRadius),
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
              top: isTop ? 0 : -(_FlipUnit._halfHeight + _FlipUnit._gap),
              height: fullHeight,
              child: Center(child: digit),
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
