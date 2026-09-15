import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

part 'mixin/profile_view_mixin.dart';
part 'widgets/profile_header.dart';
part 'widgets/profile_menu_card.dart';
part 'widgets/profile_premium_card.dart';
part 'widgets/profile_section.dart';

/// Profil sekmesi.
final class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> with ProfileViewMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorName.colorProfileBack,
      body: SafeArea(
        child: ListView(
          physics: const ClampingScrollPhysics(),
          clipBehavior: Clip.none,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            const ProfileHeader(
              displayName: 'Atilla E.',
              initials: 'AE',
              streakDays: 3,
              isPremium: true,
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
                    trailing: Transform.scale(
                      scale: 0.8,
                      child: CupertinoSwitch(
                        value: pushNotifications,
                        activeTrackColor: ColorName.colorToggleOn,
                        onChanged: onPushNotificationsChanged,
                      ),
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
                    icon: Assets.icons.solarHistory2LineDuotone,
                    title: 'profile.fasting_history'.tr(),
                    onTap: onFastingHistory,
                  ),
                  ProfileMenuRow(
                    icon: Assets.icons.solarHeartLineDuotone,
                    title: 'profile.sync_apple_health'.tr(),
                    trailing: Transform.scale(
                      scale: 0.8,
                      child: CupertinoSwitch(
                        value: appleHealthSync,
                        activeTrackColor: ColorName.colorToggleOn,
                        onChanged: onAppleHealthChanged,
                      ),
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
          ],
        ),
      ),
    );
  }
}
