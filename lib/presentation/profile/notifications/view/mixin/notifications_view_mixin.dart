part of '../notifications_view.dart';

mixin NotificationsViewMixin on State<NotificationsView> {
  List<AppNotificationItem> items = const [];

  NotificationsRepository get _repository => getIt<NotificationsRepository>();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  /// Liste gelir; ekran açıldığı için hepsi okundu sayılır (rozet sıfırlanır).
  Future<void> _load() async {
    try {
      final inbox = await _repository.list();
      if (!mounted) return;
      final now = DateTime.now();
      setState(() {
        items = [
          for (final n in inbox)
            AppNotificationItem(
              id: n.id,
              kind: n.type.startsWith('weight')
                  ? NotificationKind.weight
                  : NotificationKind.meal,
              titleKey: '',
              title: n.title,
              body: n.body,
              hoursAgo: now.difference(n.createdAt).inHours,
            ),
        ];
      });
      if (inbox.any((n) => n.readAt == null)) {
        unawaited(_repository.markAllRead().catchError((Object _) {}));
      }
    } on Exception {
      // Liste alınamazsa boş durum gösterilir.
    }
  }

  String get sectionDateLabel {
    final now = DateTime.now();
    return DateFormat('d MMMM', context.locale.toString()).format(now);
  }

  void onBack() => context.pop();

  void onDismiss(String id) {
    setState(() => items = items.where((e) => e.id != id).toList());
    unawaited(_repository.remove(id).catchError((Object _) {}));
  }
}
