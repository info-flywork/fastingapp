part of '../notifications_view.dart';

final class NotificationsEmptyState extends StatelessWidget {
  const NotificationsEmptyState({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Assets.images.notificationEmptyBell.image(
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                Text(
                  'notifications.empty_title'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.notificationsEmptyTitle,
                ),
                const SizedBox(height: 8),
                Text(
                  'notifications.empty_subtitle'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.notificationsEmptySubtitle,
                ),
              ],
            ),
          ),
          AppButton(
            label: 'notifications.back'.tr(),
            onPressed: onBack,
            showIcon: false,
            decoration: AppButtonDecoration.dark(),
          ),
        ],
      ),
    );
  }
}
