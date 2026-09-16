part of '../notifications_view.dart';

mixin NotificationsViewMixin on State<NotificationsView> {
  late List<AppNotificationItem> items = [
    const AppNotificationItem(
      id: 'weight-1',
      kind: NotificationKind.weight,
      titleKey: 'notifications.weight_updates',
      hoursAgo: 8,
      weightKg: 74,
    ),
    const AppNotificationItem(
      id: 'meal-1',
      kind: NotificationKind.meal,
      titleKey: 'notifications.meal_ended',
      hoursAgo: 8,
      bodyKey: 'notifications.meal_ended_body',
    ),
  ];

  String get sectionDateLabel {
    final now = DateTime.now();
    return DateFormat('d MMMM', context.locale.toString()).format(now);
  }

  void onBack() => context.pop();

  void onDismiss(String id) {
    setState(() => items = items.where((e) => e.id != id).toList());
  }
}
