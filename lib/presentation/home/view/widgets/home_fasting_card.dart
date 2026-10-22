part of '../home_view.dart';

/// Oruç kartı: maskot + flip-clock geri sayım.
/// Hedef dolunca kutlama görünümü; dokununca her zaman Oruç sekmesine gider.
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
  StreamSubscription<FastingSessionState>? _sessionSub;

  /// Kalan süre: cubit canlı ölçümü öncelikli (optimistic start + ortak saat).
  FastingLiveMetrics? get _metrics {
    final session = getIt<FastingSessionCubit>().state;
    final cubitFast = session.fast;
    final cubitEat = session.eatingWindow;
    // Aynı oruç / pencere veya cubit daha güncel (_local → sunucu id).
    if (cubitFast != null &&
        (widget.activeFast == null ||
            widget.activeFast!.id == cubitFast.id ||
            cubitFast.id == '_local' ||
            widget.activeFast!.id == '_local')) {
      return session.liveMetrics;
    }
    if (cubitEat != null &&
        widget.activeFast == null &&
        (widget.eatingWindow == null ||
            widget.eatingWindow!.endsAt == cubitEat.endsAt)) {
      return session.liveMetrics;
    }
    final at = DateTime.now();
    final offset = clockOffsetFromServer(widget.serverTime, at);
    if (widget.activeFast != null) {
      return FastingLiveMetrics.active(
        fast: widget.activeFast!,
        fetchedAt: at,
        clockOffset: offset,
      );
    }
    if (widget.eatingWindow != null) {
      return FastingLiveMetrics.eating(
        window: widget.eatingWindow!,
        fetchedAt: at,
        clockOffset: offset,
      );
    }
    return null;
  }

  /// Yeme penceresi sıfıra inince bir kez özet yenilenir (pencere kapanır,
  /// kart güncel durumu gösterir).
  bool _refreshedAtZero = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
    // Optimistic start: cubit özetten önce dolar — kart hemen yenilensin.
    _sessionSub = getIt<FastingSessionCubit>().stream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_sessionSub?.cancel());
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeFastingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eatingWindow?.endsAt != widget.eatingWindow?.endsAt ||
        oldWidget.activeFast?.id != widget.activeFast?.id) {
      _refreshedAtZero = false;
    }
  }

  void _openFastingTab() {
    context.goNamed(RoutePaths.fasting.name);
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _metrics;
    final fasting = widget.activeFast != null;
    final eating = !fasting && widget.eatingWindow != null;
    final remaining = metrics?.remainingToPlannedEnd ?? Duration.zero;
    // Oruç hedefi geçti: süre hedefte donar (ileri saymaz).
    final goalReached = fasting && remaining == Duration.zero;
    final rem = goalReached
        ? Duration(minutes: widget.activeFast!.targetMinutes)
        : remaining;
    if (eating && remaining == Duration.zero && !_refreshedAtZero) {
      _refreshedAtZero = true;
      getIt<HomeBloc>().add(const HomeRefreshRequested());
    }
    final title = goalReached
        ? 'home.fasting_goal_reached'
        : eating
        ? 'home.eating_window'
        : 'home.fasting';
    final hours = rem.inHours;
    final minutes = rem.inMinutes.remainder(60);
    final seconds = rem.inSeconds.remainder(60);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openFastingTab,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: goalReached ? null : ColorName.colorWhite,
              gradient: goalReached
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ColorName.colorCtaGradientTop,
                        ColorName.colorWhite,
                      ],
                    )
                  : null,
              border: goalReached
                  ? Border.all(
                      color: ColorName.colorMealPositive.withValues(alpha: 0.65),
                      width: 1.5,
                    )
                  : null,
            ),
            child: Column(
              children: [
                Row(
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
                    Expanded(
                      child: Text(
                        title.tr(),
                        style: AppTextStyles.homeCardTitle.copyWith(
                          color: goalReached
                              ? ColorName.colorBrandStrong
                              : ColorName.colorTitle,
                        ),
                      ),
                    ),
                    _TrailingChip(goalReached: goalReached),
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
                          // clockv2 şeffaf; clock beyaz kare — tamamlandıda v2.
                          scale: goalReached ? 1.15 : 1.21,
                          child: (goalReached
                                  ? AppImages.mascotClockv2
                                  : AppImages.mascotClock)
                              .image(
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
                          FlipClockUnit(
                            value: hours,
                            label: 'home.timer_hrs'.tr(),
                          ),
                          const SizedBox(width: 10),
                          FlipClockUnit(
                            value: minutes,
                            label: 'home.timer_min'.tr(),
                          ),
                          const SizedBox(width: 10),
                          FlipClockUnit(
                            value: seconds,
                            label: 'home.timer_sec'.tr(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _TrailingChip extends StatelessWidget {
  const _TrailingChip({required this.goalReached});

  final bool goalReached;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      decoration: BoxDecoration(
        color: goalReached
            ? ColorName.colorMealPositive.withValues(alpha: 0.22)
            : ColorName.colorHomeChipBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (goalReached)
            const Icon(
              Icons.check_circle_rounded,
              size: 20,
              color: ColorName.colorBrandStrong,
            )
          else
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
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: goalReached
                ? ColorName.colorBrandStrong
                : ColorName.colorTitle,
          ),
        ],
      ),
    );
  }
}
