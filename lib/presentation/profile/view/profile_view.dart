import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/utils/enum/snackbar_type.dart';
import 'package:fastingapp/core/widgets/bottom_navigation_bar/app_bottom_nav.dart';
import 'package:fastingapp/domain/notification/notifications_repository.dart';
import 'package:fastingapp/domain/revenue_cat/revenue_cat_service.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_bloc.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_event.dart';
import 'package:fastingapp/presentation/chat/view/widgets/ai_chat_header_icon.dart';
import 'package:fastingapp/presentation/home/bloc/home_bloc.dart';
import 'package:fastingapp/presentation/home/bloc/home_state.dart';
import 'package:fastingapp/presentation/profile/bloc/profile_bloc.dart';
import 'package:fastingapp/presentation/profile/view/widgets/profile_menu_card.dart';
import 'package:fastingapp/presentation/profile/view/widgets/profile_section.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

part 'mixin/profile_view_mixin.dart';
part 'widgets/profile_header.dart';
part 'widgets/profile_premium_card.dart';

/// Profil sekmesi.
final class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> with ProfileViewMixin {
  Widget _profileSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Transform.scale(
      scale: 0.85,
      alignment: Alignment.centerRight,
      child: CupertinoSwitch(
        value: value,
        activeTrackColor: ColorName.colorToggleOn,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ColorName.colorProfileBack,
        body: SafeArea(
          top: false,
          child: ListView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              // Ad ve avatar ProfileBloc'tan, seri ana sayfa özetinden.
              BlocBuilder<ProfileBloc, ProfileState>(
                bloc: getIt<ProfileBloc>(),
                builder: (context, profile) {
                  final name = profile.name?.trim() ?? '';
                  return BlocSelector<HomeBloc, HomeState, int>(
                    bloc: getIt<HomeBloc>(),
                    selector: (state) =>
                        state is HomeLoaded ? state.progress.streakDays : 0,
                    builder: (context, streakDays) => ProfileHeader(
                      // Adı olmayan (misafir) hesap.
                      displayName: name.isEmpty
                          ? 'profile.guest_name'.tr()
                          : name,
                      initials: profile.initials,
                      avatarUrl: profile.avatarUrl,
                      localPhotoPath: profile.localPhotoPath,
                      streakDays: streakDays,
                      isPremium: isPremium,
                      onChatTapped: onChatTapped,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              ProfileSection(
                title: 'profile.account'.tr(),
                child: ProfileMenuCard(
                  children: [
                    ProfileMenuRow(
                      icon: Assets.icons.solarPen2LineDuotone,
                      title: 'profile.edit_profile'.tr(),
                      onTap: onEditProfile,
                    ),
                    ProfileMenuRow(
                      icon: Assets.icons.solarBellLineDuotone,
                      title: 'profile.push_notifications'.tr(),
                      subtitle: 'profile.push_notifications_subtitle'.tr(),
                      trailing: _profileSwitch(
                        value: pushNotifications,
                        onChanged: onPushNotificationsChanged,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isPremium) ...[
                const SizedBox(height: 12),
                ProfilePremiumCard(onGetPremium: onGetPremium),
              ],
              const SizedBox(height: 24),
              ProfileSection(
                title: 'profile.activity_data'.tr(),
                child: ProfileMenuCard(
                  children: [
                    ProfileMenuRow(
                      icon: Assets.icons.solarChartLineDuotone,
                      title: 'profile.weight_loss_tracker'.tr(),
                      onTap: onWeightLossTracker,
                    ),
                    ProfileMenuRow(
                      icon: Assets.icons.calories,
                      title: 'profile.calories_tracker'.tr(),
                      onTap: onCaloriesTracker,
                    ),
                    ProfileMenuRow(
                      icon: Assets.icons.sleep,
                      title: 'profile.sleep_tracker'.tr(),
                      onTap: onSleepTracker,
                    ),
                    ProfileMenuRow(
                      icon: Assets.icons.solarHistory2LineDuotone,
                      title: 'profile.fasting_history'.tr(),
                      onTap: onFastingHistory,
                    ),
                    ProfileMenuRow(
                      icon: Assets.icons.solarHeartLineDuotone,
                      title: healthSyncTitle,
                      subtitle: 'profile.health_sync_subtitle'.tr(),
                      trailing: _profileSwitch(
                        value: healthSync,
                        onChanged: onHealthSyncChanged,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ProfileSection(
                title: 'profile.support_app'.tr(),
                child: ProfileMenuCard(
                  children: [
                    ProfileMenuRow(
                      icon: Assets.icons.archiveBook,
                      title: 'profile.insights'.tr(),
                      onTap: onInsights,
                    ),
                    ProfileMenuRow(
                      icon: Assets.icons.solarBellLineDuotone,
                      title: 'profile.notification_inbox'.tr(),
                      trailing: unreadNotifications > 0
                          ? _UnreadBadge(count: unreadNotifications)
                          : null,
                      onTap: onNotificationInbox,
                    ),
                    ProfileMenuRow(
                      icon: Assets.icons.hugeiconsTranslate,
                      title: 'profile.language'.tr(),
                      onTap: onLanguage,
                    ),
                    ProfileMenuRow(
                      icon: Assets.icons.solarQuestionCircleLineDuotone,
                      title: 'profile.faq'.tr(),
                      onTap: onFaq,
                    ),
                    ProfileMenuRow(
                      icon: Assets.icons.solarCart3LineDuotone,
                      title: 'profile.restore_purchases'.tr(),
                      onTap: onRestorePurchases,
                    ),
                    ProfileMenuRow(
                      icon: Assets.icons.solarHandStarsLineDuotone,
                      title: 'profile.rate_app'.tr(),
                      onTap: onRateApp,
                    ),
                    ProfileMenuRow(
                      icon: Assets.icons.solarShareLineDuotone,
                      title: 'profile.share_app'.tr(),
                      onTap: onShareApp,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ProfileLogoutCard(onTap: onLogOut),
              const SizedBox(height: AppBottomNav.barClearance),
            ],
          ),
        ),
      ),
    );
  }
}

/// Okunmamış bildirim rozeti (99+ kısaltılır).
final class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: ColorName.colorOptionNegative,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: ColorName.colorWhite,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
