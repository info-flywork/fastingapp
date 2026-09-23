part of '../profile_view.dart';

mixin ProfileViewMixin on State<ProfileView> {
  bool pushNotifications = true;
  bool healthSync = true;

  String get healthSyncTitle {
    if (Platform.isIOS) return 'profile.sync_apple_health'.tr();
    return 'profile.sync_google_fit'.tr();
  }

  void onPushNotificationsChanged(bool value) {
    setState(() => pushNotifications = value);
  }

  void onHealthSyncChanged(bool value) {
    setState(() => healthSync = value);
  }

  void onEditProfile() {
    context.pushNamed(RoutePaths.editProfile.name);
  }

  void onGetPremium() {}

  void onWeightLossTracker() {
    context.pushNamed(RoutePaths.bodyHistory.name);
  }

  void onCaloriesTracker() {
    context.pushNamed(RoutePaths.caloriesTracker.name);
  }

  void onSleepTracker() {
    context.pushNamed(RoutePaths.sleep.name);
  }

  void onFastingHistory() {}

  void onInsights() {}

  void onNotificationInbox() {
    context.pushNamed(RoutePaths.notifications.name);
  }

  void onLanguage() {
    context.pushNamed(RoutePaths.languages.name);
  }

  void onFaq() {
    context.pushNamed(RoutePaths.faq.name);
  }

  void onChatTapped() {
    context.pushNamed(RoutePaths.chat.name);
  }

  void onRateApp() {}

  void onShareApp() {}

  void onLogOut() {}
}
