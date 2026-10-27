part of '../hunger_history_log_view.dart';

mixin HungerHistoryLogViewMixin on State<HungerHistoryLogView> {
  HungerHistoryFilter filter = HungerHistoryFilter.all;

  HungerStore get _store => getIt<HungerStore>();

  /// Bellekteki liste (tekrar açılışta beklemeden dolu; yeni kayıt anında).
  List<HungerCheckinItem> get entries => _store.entries ?? const [];

  /// Yalnızca hiç yüklenmemişken.
  bool get loading => _store.entries == null;

  /// Hafta şeridi (`/hunger-checkins/summary.week`).
  List<HungerWeekDay> get week => _store.week;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
    unawaited(_load());
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  /// Tümü bir kez yüklenir; filtre sekmeleri istemcide süzer (sekme başına
  /// spinner ve istek yok). Hata boş liste gibi gösterilmez.
  Future<void> _load() async {
    try {
      await _store.load();
    } on Object catch (e) {
      if (mounted && _store.entries == null) AppSnackbar.showError(context, e);
    }
  }

  List<HungerCheckinItem> get filteredEntries => switch (filter) {
    HungerHistoryFilter.all => entries,
    HungerHistoryFilter.physical =>
      entries.where((e) => e.typeEnum == HungerResultType.physical).toList(),
    HungerHistoryFilter.emotional =>
      entries.where((e) => e.typeEnum == HungerResultType.emotional).toList(),
  };

  void setFilter(HungerHistoryFilter value) {
    setState(() => filter = value);
  }

  /// Soru akışıyla kayıt: önceden cevapsız kayıt ekranı açılıyor, sonuç hep
  /// "Fiziksel" görünüyordu.
  void onLogMyHungerTapped() {
    context.pushNamed(
      RoutePaths.hungerCheck.name,
      extra: const HungerFlowArgs(),
    );
  }
}
