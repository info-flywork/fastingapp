part of '../home_view.dart';

/// Oruç kartı: maskot + flip-clock geri sayım.
final class HomeFastingCard extends StatefulWidget {
  const HomeFastingCard({
    this.activeFast,
    this.eatingWindow,
    this.serverTime,
    super.key,
  });

  final ActiveFast? activeFast;
  final EatingWindow? eatingWindow;
  final DateTime? serverTime;

  @override
  State<HomeFastingCard> createState() => _HomeFastingCardState();
}

class _HomeFastingCardState extends State<HomeFastingCard> {
  Timer? _timer;
  late DateTime _anchor = DateTime.now();

  Duration get _remaining {
    final at = _anchor;
    final offset = clockOffsetFromServer(widget.serverTime, at);
    if (widget.activeFast != null) {
      return FastingLiveMetrics.active(
        fast: widget.activeFast!,
        fetchedAt: at,
        clockOffset: offset,
      ).remainingToPlannedEnd;
    }
    if (widget.eatingWindow != null) {
      return FastingLiveMetrics.eating(
        window: widget.eatingWindow!,
        fetchedAt: at,
        clockOffset: offset,
      ).remainingToPlannedEnd;
    }
    return Duration.zero;
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant HomeFastingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeFast?.id != widget.activeFast?.id ||
        oldWidget.eatingWindow?.endsAt != widget.eatingWindow?.endsAt ||
        oldWidget.serverTime != widget.serverTime) {
      _anchor = DateTime.now();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rem = _remaining;
    final hours = rem.inHours;
    final minutes = rem.inMinutes.remainder(60);
    final seconds = rem.inSeconds.remainder(60);

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
                    child: AppImages.fork.image(
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
                          child: AppImages.blood.image(
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
                    child: AppImages.mascotClock.image(
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
                    FlipClockUnit(value: hours, label: 'home.timer_hrs'.tr()),
                    const SizedBox(width: 10),
                    FlipClockUnit(value: minutes, label: 'home.timer_min'.tr()),
                    const SizedBox(width: 10),
                    FlipClockUnit(value: seconds, label: 'home.timer_sec'.tr()),
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
