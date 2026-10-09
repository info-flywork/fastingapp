part of '../hunger_history_log_view.dart';

mixin HungerHistoryLogViewMixin on State<HungerHistoryLogView> {
  HungerHistoryFilter filter = HungerHistoryFilter.all;
  List<HungerCheckinItem> entries = const [];
  bool loading = true;

  HungerRepository get _hunger => getIt<HungerRepository>();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load([HungerHistoryFilter? activeFilter]) async {
    final type = _apiType(activeFilter ?? filter);
    setState(() => loading = true);
    try {
      final items = await _hunger.listCheckins(type: type);
      if (mounted) setState(() => entries = items);
    } on Object {
      if (mounted) setState(() => entries = const []);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  static String _apiType(HungerHistoryFilter f) => switch (f) {
    HungerHistoryFilter.all => 'all',
    HungerHistoryFilter.physical => 'physical',
    HungerHistoryFilter.emotional => 'emotional',
  };

  List<HungerCheckinItem> get filteredEntries => entries;

  void setFilter(HungerHistoryFilter value) {
    setState(() => filter = value);
    unawaited(_load(value));
  }

  void onLogMyHungerTapped() {
    context.pushNamed(
      RoutePaths.hungerLog.name,
      extra: HungerSessionArgs(
        flow: const HungerFlowArgs(),
        resultType: HungerResultType.physical,
      ),
    );
  }
}
