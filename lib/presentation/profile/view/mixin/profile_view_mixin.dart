part of '../profile_view.dart';

mixin ProfileViewMixin on State<ProfileView> {
  bool pushNotifications = true;
  bool healthSync = true;

  /// Okunmamış bildirim sayısı (Bildirimler satırındaki rozet).
  int unreadNotifications = 0;

  RevenueCatService get _revenueCat => getIt<RevenueCatService>();

  /// Premium rozeti; premium kartı yalnızca premium değilken görünür.
  bool get isPremium => _revenueCat.isPremium.value;

  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    _revenueCat.isPremium.addListener(_onPremiumChanged);
    unawaited(_loadUnread());
    // Isıtılmadıysa başlık için profil yüklenir (yüklüyse dokunmaz).
    getIt<ProfileBloc>().add(const ProfileStarted());
  }

  @override
  void dispose() {
    _revenueCat.isPremium.removeListener(_onPremiumChanged);
    super.dispose();
  }

  void _onPremiumChanged() {
    if (mounted) setState(() {});
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

  void onGetPremium() => unawaited(_revenueCat.presentPaywall());

  Future<void> onRestorePurchases() async {
    if (_restoring) return;
    _restoring = true;
    try {
      final premium = await _revenueCat.restore();
      if (!mounted) return;
      AppSnackbar.show(
        context: context,
        text: premium
            ? 'profile.restore_success'.tr()
            : 'profile.restore_none'.tr(),
        type: premium ? SnackBarType.success : SnackBarType.info,
      );
    } on Object {
      if (!mounted) return;
      AppSnackbar.show(
        context: context,
        text: 'profile.restore_failed'.tr(),
        type: SnackBarType.failure,
      );
    } finally {
      _restoring = false;
    }
  }

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
    context.go(RoutePaths.login.path);
  }
}
