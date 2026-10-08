part of '../profile_view.dart';

mixin ProfileViewMixin on State<ProfileView> {
  bool pushNotifications = true;
  bool healthSync = true;

  /// Okunmamış bildirim sayısı (Bildirimler satırındaki rozet).
  int unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadUnread());
  }

  Future<void> _loadUnread() async {
    try {
      final count = await getIt<NotificationsRepository>().unreadCount();
      if (mounted) setState(() => unreadNotifications = count);
    } on Exception {
      // Rozet gösterilmez.
    }
  }

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

  void onInsights() {
    context.pushNamed(RoutePaths.insights.name);
  }

  Future<void> onNotificationInbox() async {
    await context.pushNamed(RoutePaths.notifications.name);
    // Kutu açılınca hepsi okundu sayılır; dönüşte rozet tazelenir.
    await _loadUnread();
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

  Future<void> onLogOut() async {
    final confirmed = await AppDialogs.instance.showSignOut(context);
    if (confirmed != true || !mounted) return;

    getIt<AuthBloc>().add(const AuthLoggedOut());
    if (!mounted) return;
    context.go(RoutePaths.welcome.path);
  }
}
