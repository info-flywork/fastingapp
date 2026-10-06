import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/widgets/bottom_navigation_bar/app_bottom_nav.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_bloc.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_event.dart';
import 'package:fastingapp/presentation/chat/view/widgets/ai_chat_header_icon.dart';
import 'package:fastingapp/presentation/profile/view/widgets/profile_menu_card.dart';
import 'package:fastingapp/presentation/profile/view/widgets/profile_section.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
              ProfileHeader(
                displayName: 'Atilla E.',
                initials: 'AE',
                streakDays: 3,
                isPremium: true,
                onChatTapped: onChatTapped,
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
              const SizedBox(height: 12),
              ProfilePremiumCard(onGetPremium: onGetPremium),
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
