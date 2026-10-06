import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/profile/view/widgets/edit_profile_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'mixin/notifications_view_mixin.dart';
part 'widgets/notification_card.dart';
part 'widgets/notifications_empty_state.dart';

enum NotificationKind { weight, meal }

@immutable
final class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.kind,
    required this.titleKey,
    required this.hoursAgo,
    this.weightKg,
    this.bodyKey,
  });

  final String id;
  final NotificationKind kind;
  final String titleKey;
  final int hoursAgo;
  final double? weightKg;
  final String? bodyKey;
}

/// Bildirim kutusu — liste + boş durum + swipe silme.
final class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView>
    with NotificationsViewMixin {
  @override
  Widget build(BuildContext context) {
    final isEmpty = items.isEmpty;

    return Scaffold(
      backgroundColor: isEmpty
          ? ColorName.colorWhite
          : ColorName.colorProfileBack,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: EditProfileAppBar(
                title: 'notifications.title'.tr(),
                onBack: onBack,
                backButtonColor: ColorName.colorWhite,
              ),
            ),
            Expanded(
              child: isEmpty
                  ? NotificationsEmptyState(onBack: onBack)
                  : ListView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                      children: [
                        Text(
                          'notifications.today_date'.tr(
                            namedArgs: {'date': sectionDateLabel},
                          ),
                          style: AppTextStyles.notificationsDate,
                        ),
                        const SizedBox(height: 12),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: ColorName.colorWhite,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                for (final item in items)
                                  NotificationCard(
                                    key: ValueKey(item.id),
                                    item: item,
                                    onDismissed: () => onDismiss(item.id),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
