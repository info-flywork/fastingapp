part of '../profile_view.dart';

mixin ProfileViewMixin on State<ProfileView> {
  bool pushNotifications = true;
  bool appleHealthSync = true;

  void onPushNotificationsChanged(bool value) {
    setState(() => pushNotifications = value);
  }

  void onAppleHealthChanged(bool value) {
    setState(() => appleHealthSync = value);
  }

  void onEditProfile() {}

  void onGetPremium() {}

  void onWeightLossTracker() {}

  void onFastingHistory() {}

  void onNotificationInbox() {}

  void onLanguage() {}

  void onFaq() {}

  void onRateApp() {}

  void onShareApp() {}

  void onLogOut() {}
}
