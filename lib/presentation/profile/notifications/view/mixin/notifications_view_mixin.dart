part of '../notifications_view.dart';

mixin NotificationsViewMixin on State<NotificationsView> {
  List<AppNotificationItem> items = const [];

  /// İlk ağ yanıtı gelene kadar true — bu sırada boş durum gösterilmez.
  bool loading = true;
  bool loadingMore = false;

  /// İlk sayfa alınamadı (önceden boş durum gösteriliyordu).
  bool loadFailed = false;
  bool hasMore = false;
  String? _nextCursor;

  final ScrollController scrollController = ScrollController();

  NotificationsRepository get _repository => getIt<NotificationsRepository>();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
    _seedFromCache();
    unawaited(_load());
  }

  /// Varsa son ilk sayfayı hemen boya; ağ yanıtı sessizce günceller.
  void _seedFromCache() {
    final cached = _repository.cachedInbox;
    if (cached == null) return;
    items = [for (final n in cached.items) _mapOne(n)];
    _nextCursor = cached.nextCursor;
    hasMore = cached.hasMore;
    loading = false;
  }

  @override
  void dispose() {
    scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!hasMore || loadingMore || loading) return;
    final pos = scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      unawaited(_loadMore());
    }
  }

  /// Liste gelir; ekran açıldığı için hepsi okundu sayılır (rozet sıfırlanır).
  /// Bu ekranda silinen bildirimler (sunucu onaylasa da yoldaki eski liste
  /// cevabı onları geri getirmesin).
  final _removedIds = <String>{};

  Future<void> _load() async {
    // Önbellek yoksa spinner; varsa mevcut liste kalsın (boş flaş yok).
    if (items.isEmpty && mounted) setState(() => loading = true);
    try {
      final page = await _repository.list();
      if (!mounted) return;
      setState(() {
        loadFailed = false;
        // Silme yoldayken başlamış okuma, silinen bildirimi geri getirmesin.
        items = [
          for (final n in page.items)
            if (!_removedIds.contains(n.id)) _mapOne(n),
        ];
        _nextCursor = page.nextCursor;
        hasMore = page.hasMore;
        loading = false;
      });
      if (page.items.any((n) => n.readAt == null)) {
        unawaited(_repository.markAllRead().catchError((Object _) {}));
      }
      _fillIfShort();
    } on Object {
      if (mounted) {
        setState(() {
          loading = false;
          loadFailed = true;
        });
      }
    }
  }

  Future<void> retry() => _load();

  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null || !hasMore || loadingMore) return;
    setState(() => loadingMore = true);
    try {
      final page = await _repository.list(cursor: cursor);
      if (!mounted) return;
      setState(() {
        items = [
          ...items,
          for (final n in page.items)
            if (!_removedIds.contains(n.id)) _mapOne(n),
        ];
        _nextCursor = page.nextCursor;
        hasMore = page.hasMore;
        loadingMore = false;
      });
      _fillIfShort();
    } on Object {
      if (mounted) setState(() => loadingMore = false);
    }
  }

  /// İlk sayfa ekranı doldurmuyorsa sonraki sayfayı da çek.
  void _fillIfShort() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !hasMore || loadingMore) return;
      if (!scrollController.hasClients) return;
      if (scrollController.position.maxScrollExtent <= 0) {
        unawaited(_loadMore());
      }
    });
  }

  AppNotificationItem _mapOne(InboxNotification n) => AppNotificationItem(
    id: n.id,
    kind: switch (n.category.isNotEmpty
        ? n.category
        : n.type.split('_').first) {
      'weight' => NotificationKind.weight,
      'fasting' || 'fast' || 'meal' || 'eating' => NotificationKind.fasting,
      'water' => NotificationKind.water,
      'streak' => NotificationKind.streak,
      _ => NotificationKind.other,
    },
    titleKey: '',
    title: n.title,
    body: n.body,
    createdAt: n.createdAt,
    deepLink: n.deepLink,
  );

  /// Gün gün (yeniden eskiye) gruplar.
  List<({DateTime day, List<AppNotificationItem> items})> get groupedItems {
    final groups = <({DateTime day, List<AppNotificationItem> items})>[];
    for (final item in items) {
      final day = DateUtils.dateOnly(item.createdAt);
      if (groups.isEmpty || groups.last.day != day) {
        groups.add((day: day, items: []));
      }
      groups.last.items.add(item);
    }
    return groups;
  }

  String sectionLabel(DateTime day) {
    final today = DateUtils.dateOnly(DateTime.now());
    final date = DateFormat('d MMMM', context.locale.toString()).format(day);
    if (day == today) {
      return 'notifications.today_date'.tr(namedArgs: {'date': date});
    }
    if (day == today.subtract(const Duration(days: 1))) {
      return 'notifications.yesterday_date'.tr(namedArgs: {'date': date});
    }
    return date;
  }

  void onBack() => context.pop();

  /// Silinemezse (ör. çevrimdışı) bildirim yerine geri konur; önceden
  /// ekrandan kalkıyor ama sunucuda kalıp sonra geri geliyordu.
  Future<void> onDismiss(String id) async {
    final index = items.indexWhere((e) => e.id == id);
    if (index < 0) return;
    final removed = items[index];
    _removedIds.add(id);
    setState(() => items = items.where((e) => e.id != id).toList());
    try {
      await _repository.remove(id);
    } on Object catch (e) {
      _removedIds.remove(id);
      if (!mounted) return;
      setState(() {
        final next = List<AppNotificationItem>.of(items);
        next.insert(index.clamp(0, next.length), removed);
        items = next;
      });
      AppSnackbar.showError(context, e);
    }
  }
}
