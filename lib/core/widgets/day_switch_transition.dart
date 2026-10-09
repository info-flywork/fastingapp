import 'package:flutter/material.dart';

/// Gün ileri/geri geçişinde yatay kaydırma + fade.
///
/// [direction] > 0: sonraki güne (sağdan girer, sola çıkar).
/// [direction] < 0: önceki güne (soldan girer, sağa çıkar).
final class DaySwitchTransition extends StatelessWidget {
  const DaySwitchTransition({
    required this.date,
    required this.direction,
    required this.child,
    this.duration = const Duration(milliseconds: 280),
    super.key,
  });

  final DateTime date;
  final int direction;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final sign = direction >= 0 ? 1.0 : -1.0;
    final dateKey = DateUtils.dateOnly(date);

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        final isIncoming =
            (child.key as ValueKey<DateTime>?)?.value == dateKey;
        final beginX = (isIncoming ? sign : -sign) * 0.18;
        final offset = Tween<Offset>(
          begin: Offset(beginX, 0),
          end: Offset.zero,
        ).animate(animation);

        return ClipRect(
          child: SlideTransition(
            position: offset,
            child: FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<DateTime>(dateKey),
        child: child,
      ),
    );
  }
}
