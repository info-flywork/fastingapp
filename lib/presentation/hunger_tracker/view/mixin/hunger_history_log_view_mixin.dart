part of '../hunger_history_log_view.dart';

mixin HungerHistoryLogViewMixin on State<HungerHistoryLogView> {
  HungerHistoryFilter filter = HungerHistoryFilter.all;
  List<HungerCheckinItem> entries = const [];
  bool loading = true;

  /// Hafta şeridi (`/hunger-checkins/summary.week`).
  List<HungerWeekDay> week = const [];

  HungerRepository get _hunger => getIt<HungerRepository>();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  /// Tümü bir kez yüklenir; filtre sekmeleri istemcide süzer (sekme başına
  /// spinner ve istek yok). Hata boş liste gibi gösterilmez.
  Future<void> _load() async {
    setState(() => loading = entries.isEmpty);
    // Şerit ayrı yüklenir: liste onu beklemez.
    unawaited(
      _hunger
          .getSummary()
          .then((s) {
            if (mounted) setState(() => week = s.week);
          })
          .catchError((Object _) {}),
    );
    try {
      final items = await _hunger.listCheckins();
      if (mounted) setState(() => entries = items);
    } on Object catch (e) {
      if (mounted) AppSnackbar.showError(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
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
