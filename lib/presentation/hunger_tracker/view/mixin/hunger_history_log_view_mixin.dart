part of '../hunger_history_log_view.dart';

mixin HungerHistoryLogViewMixin on State<HungerHistoryLogView> {
  HungerHistoryFilter filter = HungerHistoryFilter.all;

  static const entries = <HungerResultType>[
    HungerResultType.physical,
    HungerResultType.emotional,
  ];

  List<HungerResultType> get filteredEntries => switch (filter) {
        HungerHistoryFilter.all => entries,
        HungerHistoryFilter.physical => entries
            .where((e) => e == HungerResultType.physical)
            .toList(),
        HungerHistoryFilter.emotional => entries
            .where((e) => e == HungerResultType.emotional)
            .toList(),
      };

  void setFilter(HungerHistoryFilter value) {
    setState(() => filter = value);
  }

  void onLogMyHungerTapped() {
    context.pushNamed(
      RoutePaths.hungerLog.name,
      extra: HungerResultType.physical,
    );
  }
}
