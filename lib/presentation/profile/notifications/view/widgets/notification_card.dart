part of '../notifications_view.dart';

final class NotificationCard extends StatefulWidget {
  const NotificationCard({
    required this.item,
    required this.onDismissed,
    super.key,
  });

  final AppNotificationItem item;
  final VoidCallback onDismissed;

  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard>
    with TickerProviderStateMixin {
  static const _actionWidth = 48.0;

  late final AnimationController _slide;
  late final AnimationController _remove;
  late final Animation<double> _removeSize;
  late final Animation<double> _removeOpacity;
  late final Animation<Offset> _removeOffset;
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _remove = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    final curved = CurvedAnimation(parent: _remove, curve: Curves.easeInCubic);
    _removeSize = Tween<double>(begin: 1, end: 0).animate(curved);
    _removeOpacity = Tween<double>(begin: 1, end: 0).animate(curved);
    _removeOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.35, 0),
    ).animate(curved);
  }

  @override
  void dispose() {
    _slide.dispose();
    _remove.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_isRemoving) return;
    final next = (_slide.value - details.delta.dx / _actionWidth).clamp(
      0.0,
      1.0,
    );
    _slide.value = next;
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isRemoving) return;
    final velocity = details.primaryVelocity ?? 0;
    final shouldOpen = velocity < -300 || _slide.value >= 0.45;
    if (shouldOpen) {
      _slide.animateTo(1, curve: Curves.easeOutCubic);
    } else {
      _slide.animateTo(0, curve: Curves.easeOutCubic);
    }
  }

  Future<void> _onDelete() async {
    if (_isRemoving) return;
    _isRemoving = true;
    if (_slide.value < 1) {
      await _slide.animateTo(1, curve: Curves.easeOutCubic);
    }
    if (!mounted) return;
    await _remove.forward();
    if (!mounted) return;
    widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _removeSize,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: _removeOpacity,
        child: SlideTransition(
          position: _removeOffset,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              decoration: BoxDecoration(
                color: ColorName.colorWhite,
                borderRadius: BorderRadius.circular(16),
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ColorName.colorBlack.withValues(alpha: 0.05),
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    bottom: 0,
                    width: _actionWidth,
                    child: Material(
                      color: ColorName.colorOptionNegative,
                      child: InkWell(
                        onTap: _onDelete,
                        child: Center(
                          child: Assets.icons.solarTrashBinTrashBoldDuotone.svg(
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _slide,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(-_actionWidth * _slide.value, 0),
                        child: child,
                      );
                    },
                    child: GestureDetector(
                      onHorizontalDragUpdate: _onDragUpdate,
                      onHorizontalDragEnd: _onDragEnd,
                      child: ColoredBox(
                        color: ColorName.colorWhite,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _NotificationIcon(kind: widget.item.kind),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            widget.item.title ??
                                                widget.item.titleKey.tr(),
                                            style: AppTextStyles
                                                .notificationsCardTitle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'notifications.hours_ago'.tr(
                                            namedArgs: {
                                              'hours':
                                                  '${widget.item.hoursAgo}',
                                            },
                                          ),
                                          style:
                                              AppTextStyles.notificationsTime,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    _NotificationBody(item: widget.item),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.kind});

  final NotificationKind kind;

  @override
  Widget build(BuildContext context) {
    final asset = kind == NotificationKind.weight
        ? AppImages.weigher
        : AppImages.notificatio;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: ColorName.colorFlipClock,
        shape: BoxShape.circle,
        border: Border.all(color: ColorName.colorWhite, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: asset.image(fit: BoxFit.cover, width: 48, height: 48),
    );
  }
}

final class _NotificationBody extends StatelessWidget {
  const _NotificationBody({required this.item});

  final AppNotificationItem item;

  @override
  Widget build(BuildContext context) {
    if (item.body != null) {
      return Text(item.body!, style: AppTextStyles.notificationsBody);
    }
    if (item.kind == NotificationKind.weight && item.weightKg != null) {
      final value = item.weightKg! == item.weightKg!.roundToDouble()
          ? '${item.weightKg!.toInt()}kg'
          : '${item.weightKg}kg';
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'notifications.weight_body_prefix'.tr(),
              style: AppTextStyles.notificationsBody,
            ),
            TextSpan(
              text: value,
              style: AppTextStyles.notificationsBodyEmphasis,
            ),
          ],
        ),
      );
    }

    return Text(
      (item.bodyKey ?? '').tr(),
      style: AppTextStyles.notificationsBody,
    );
  }
}
