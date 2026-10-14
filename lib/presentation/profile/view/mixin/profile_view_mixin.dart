part of '../profile_view.dart';

mixin ProfileViewMixin on State<ProfileView> {
  bool pushNotifications = true;
  bool healthSync = true;

  /// Okunmamış bildirim sayısı (Bildirimler satırındaki rozet).
  int unreadNotifications = 0;

  RevenueCatService get _revenueCat => getIt<RevenueCatService>();

  NotificationsRepository get _notifications =>
      getIt<NotificationsRepository>();

  /// Premium rozeti; premium kartı yalnızca premium değilken görünür.
  bool get isPremium => _revenueCat.isPremium.value;

  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    unreadNotifications = _notifications.unread.value;
    _revenueCat.isPremium.addListener(_onPremiumChanged);
    _notifications.unread.addListener(_onUnreadChanged);
    unawaited(_notifications.refreshUnread());
    unawaited(_loadSettings());
    unawaited(_loadLinks());
    // Isıtılmadıysa başlık için profil yüklenir (yüklüyse dokunmaz).
    getIt<ProfileBloc>().add(const ProfileStarted());
  }

  @override
  void dispose() {
    _revenueCat.isPremium.removeListener(_onPremiumChanged);
    _notifications.unread.removeListener(_onUnreadChanged);
    super.dispose();
  }

  void _onPremiumChanged() {
    if (mounted) setState(() {});
  }

  void _onUnreadChanged() {
    if (!mounted) return;
    setState(() => unreadNotifications = _notifications.unread.value);
  }

  ProfileRepository get _profileRepo => getIt<ProfileRepository>();

  /// Anahtarlar sunucudan (`/user/settings`); önceden yalnızca ekrandaydı.
  Future<void> _loadSettings() async {
    try {
      final s = await _profileRepo.getSettings();
      if (!mounted) return;
      setState(() {
        pushNotifications = s.pushEnabled;
        healthSync = s.healthSyncEnabled;
      });
    } on Object {
      // Varsayılanlar kalır.
    }
  }

  /// İyimser: anahtar hemen döner, hata olursa geri alınır.
  Future<void> _saveSetting({
    bool? push,
    bool? health,
    required VoidCallback revert,
  }) async {
    try {
      await _profileRepo.updateSettings(
        pushEnabled: push,
        healthSyncEnabled: health,
      );
    } on Object catch (e) {
      if (!mounted) return;
      setState(revert);
      AppSnackbar.showError(context, e);
    }
  }

  String get healthSyncTitle {
    if (Platform.isIOS) return 'profile.sync_apple_health'.tr();
    return 'profile.sync_health_connect'.tr();
  }

  void onPushNotificationsChanged(bool value) {
    setState(() => pushNotifications = value);
    unawaited(
      _saveSetting(push: value, revert: () => pushNotifications = !value),
    );
  }

  Future<void> onHealthSyncChanged(bool value) async {
    final previous = healthSync;
    setState(() => healthSync = value);
    if (!value) {
      try {
        await getIt<HealthSyncService>().disable();
      } on Object {
        if (mounted) setState(() => healthSync = previous);
      }
      return;
    }
    try {
      final ok = await getIt<HealthSyncService>().enable();
      if (!mounted) return;
      if (!ok) {
        setState(() => healthSync = false);
        AppSnackbar.show(
          context: context,
          text: 'profile.health_sync_denied'.tr(),
          type: SnackBarType.info,
        );
      }
    } on Object {
      if (!mounted) return;
      setState(() => healthSync = previous);
      AppSnackbar.show(
        context: context,
        text: 'profile.health_sync_denied'.tr(),
        type: SnackBarType.failure,
      );
    }
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

  void onFastingHistory() {
    context.pushNamed(RoutePaths.fastingHistory.name);
  }

  void onInsights() {
    context.pushNamed(RoutePaths.insights.name);
  }

  Future<void> onNotificationInbox() async {
    await context.pushNamed(RoutePaths.notifications.name);
    // Kutu açılınca hepsi okundu sayılır; dönüşte rozet tazelenir.
    await _notifications.refreshUnread();
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

  /// Yasal metin / destek adresleri (`/app/config`).
  AppLinks? links = getIt<AppLinksRepository>().cached;

  Future<void> _loadLinks() async {
    final loaded = await getIt<AppLinksRepository>().get();
    if (mounted) setState(() => links = loaded);
  }

  Future<void> onOpenLink(String url) async {
    final ok = await getIt<UrlLauncherManager>().openUrl(url);
    if (!ok && mounted) {
      AppSnackbar.show(
        context: context,
        text: 'common.error_generic'.tr(),
        type: SnackBarType.failure,
      );
    }
  }

  /// Posta uygulaması yoksa adres panoya kopyalanır.
  Future<void> onContactSupport(String email) async {
    final ok = await getIt<UrlLauncherManager>().openEmail(
      email,
      subject: 'MochiFast',
    );
    if (ok || !mounted) return;
    await Clipboard.setData(ClipboardData(text: email));
    if (!mounted) return;
    AppSnackbar.show(
      context: context,
      text: 'profile.support_email_copied'.tr(),
      type: SnackBarType.info,
    );
  }

  /// Mağazanın uygulama içi değerlendirme penceresi; gösterilemiyorsa
  /// (kota / ortam) mağaza sayfası.
  Future<void> onRateApp() async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing(
          appStoreId: StoreLinks.iosAppId.isEmpty ? null : StoreLinks.iosAppId,
        );
      }
    } on Object catch (e) {
      if (mounted) AppSnackbar.showError(context, e);
    }
  }

  Future<void> onShareApp(BuildContext anchor) async {
    final box = anchor.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    final link = StoreLinks.current;
    final text = 'profile.share_app_text'.tr();
    await SharePlus.instance.share(
      ShareParams(
        text: link == null ? text : '$text\n$link',
        sharePositionOrigin: origin,
      ),
    );
  }

  Future<void> onLogOut() async {
    final confirmed = await AppDialogs.instance.showSignOut(context);
    if (confirmed != true || !mounted) return;

    getIt<AuthBloc>().add(const AuthLoggedOut());
    if (!mounted) return;
    context.go(RoutePaths.login.path);
  }
}
