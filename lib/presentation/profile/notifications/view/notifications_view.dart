import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/push/push_open_handler.dart';
import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/core/widgets/app_loading.dart';
import 'package:fastingapp/domain/notification/notifications_repository.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/profile/view/widgets/edit_profile_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'mixin/notifications_view_mixin.dart';
part 'widgets/notification_card.dart';
part 'widgets/notifications_empty_state.dart';

enum NotificationKind { weight, fasting, water, streak, other }

@immutable
final class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.kind,
    required this.titleKey,
    required this.createdAt,
    this.weightKg,
    this.bodyKey,
    this.title,
    this.body,
    this.deepLink,
  });

  final String id;
  final NotificationKind kind;
  final String titleKey;
  final DateTime createdAt;
  final double? weightKg;
  final String? bodyKey;

  /// Sunucunun hazırladığı metinler (varsa çeviri anahtarlarının yerine).
  final String? title;
  final String? body;
  final String? deepLink;
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
    // Yüklenirken asla boş durum yok (önce spinner, sonra liste veya boş).
    final showEmpty = !loading && items.isEmpty;

    return Scaffold(
      backgroundColor: showEmpty
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
              child: loading
                  ? const Center(child: AppLoading())
                  : loadFailed && items.isEmpty
                  ? _NotificationsError(onRetry: () => unawaited(retry()))
                  : showEmpty
                  ? NotificationsEmptyState(onBack: onBack)
                  : ListView(
                      controller: scrollController,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                      children: [
                        // Gün gün bölümler (önceden hepsi "Bugün" altında).
                        for (final group in groupedItems) ...[
                          Text(
                            sectionLabel(group.day),
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
                                  for (final item in group.items)
                                    NotificationCard(
                                      key: ValueKey(item.id),
                                      item: item,
                                      onDismissed: () =>
                                          unawaited(onDismiss(item.id)),
                                      onTap: item.deepLink == null
                                          ? null
                                          : () => PushOpenHandler.openDeepLink(
                                              item.deepLink,
                                            ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (loadingMore)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: AppLoading()),
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

/// İlk yükleme başarısız: boş durum gibi görünmesin, tekrar denenebilsin.
final class _NotificationsError extends StatelessWidget {
  const _NotificationsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'notifications.load_failed'.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.notificationsEmptySubtitle,
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'common.retry'.tr(),
            onPressed: onRetry,
            showIcon: false,
            decoration: AppButtonDecoration.dark(),
          ),
        ],
      ),
    );
  }
}
