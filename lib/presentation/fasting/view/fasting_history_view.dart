import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/core/sync/data_sync.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/utils/extensions/future_extensions.dart';
import 'package:fastingapp/core/widgets/app_loading.dart';
import 'package:fastingapp/domain/fasting/fasting_repository.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/fasting/view/fasting_entry_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Profil → Oruç geçmişi (`GET /fasts` + `/fasts/stats`).
final class FastingHistoryView extends StatefulWidget {
  const FastingHistoryView({super.key});

  @override
  State<FastingHistoryView> createState() => _FastingHistoryViewState();
}

class _FastingHistoryViewState extends State<FastingHistoryView> {
  final _scroll = ScrollController();
  final _items = <FastHistoryItem>[];
  FastStats _stats = const FastStats();
  var _loading = true;
  var _loadingMore = false;
  var _hasMore = false;
  String? _cursor;
  String? _error;

  FastingRepository get _repo => getIt<FastingRepository>();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    unawaited(_load());
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      unawaited(_loadMore());
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repo.listHistory(),
        _repo.getStats(range: 'all'),
      ]);
      if (!mounted) return;
      final page = results[0] as FastHistoryPage;
      final stats = results[1] as FastStats;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _cursor = page.nextCursor;
        _hasMore = page.hasMore;
        _stats = stats;
        _loading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = errorMessageOf(e);
      });
    }
  }

  Future<void> _loadMore() async {
    final cursor = _cursor;
    if (cursor == null || !_hasMore || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _repo.listHistory(cursor: cursor);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _cursor = page.nextCursor;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } on Object {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  /// Sunucu yalnızca son 30 günün bitmiş oruçlarını düzenletir.
  static bool _canEdit(FastHistoryItem item) =>
      item.status != 'active' &&
      item.status != 'cancelled' &&
      item.endedAt != null &&
      DateTime.now().difference(item.startedAt).inDays < 30;

  Future<FastEntryAction?> _openSheet({
    required DateTime start,
    required DateTime end,
    required bool canDelete,
  }) => showModalBottomSheet<FastEntryAction>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        FastEntrySheet(start: start, end: end, canDelete: canDelete),
  );

  /// Kayda dokununca saatleri düzelt ya da sil (önceden yalnızca okunuyordu).
  Future<void> _editFast(FastHistoryItem item) async {
    final action = await _openSheet(
      start: item.startedAt,
      end: item.endedAt!,
      canDelete: true,
    );
    if (action == null || !mounted) return;
    if (action is FastEntryDelete) {
      final ok = await AppDialogs.instance.showDeleteFast(context);
      if (ok != true || !mounted) return;
    }
    await _write(switch (action) {
      FastEntrySave(:final start, :final end) => () => _repo.updateFast(
        item.id,
        startedAt: start,
        endedAt: end,
      ),
      FastEntryDelete() => () => _repo.deleteFast(item.id),
    });
  }

  /// Uygulamasız yapılmış oruç (son 30 gün).
  Future<void> _addPastFast() async {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 8);
    final action = await _openSheet(
      start: end.subtract(const Duration(hours: 16)),
      end: end.isAfter(now) ? end.subtract(const Duration(days: 1)) : end,
      canDelete: false,
    );
    if (action is! FastEntrySave || !mounted) return;
    await _write(
      () => _repo.addPastFast(startedAt: action.start, endedAt: action.end),
    );
  }

  Future<void> _write(Future<void> Function() call) async {
    try {
      await call().withLoading(context);
      // Seri, hafta, istatistik ve ana sayfa değişir.
      DataSync.afterWrite(profile: true);
      if (mounted) await _load();
    } on Object catch (e) {
      if (mounted) AppSnackbar.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: ColorName.colorBodyPageBg,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    _BackButton(onTap: () => context.pop()),
                    Expanded(
                      child: Text(
                        'fasting_history_page.title'.tr(),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyHistoryTitleSmall,
                      ),
                    ),
                    _AddButton(onTap: () => unawaited(_addPastFast())),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: AppLoading())
                    : _error != null && _items.isEmpty
                    ? _ErrorBody(message: _error!, onRetry: _load)
                    : _items.isEmpty
                    ? const _EmptyBody()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          controller: _scroll,
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: ClampingScrollPhysics(),
                          ),
                          padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 24),
                          itemCount: _items.length + 2 + (_loadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _StatsCard(stats: _stats),
                              );
                            }
                            if (index == 1) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'fasting_history_page.list_title'.tr(),
                                  style: AppTextStyles.notificationsDate,
                                ),
                              );
                            }
                            final i = index - 2;
                            if (i >= _items.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: AppLoading()),
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _HistoryCard(
                                item: _items[i],
                                onTap: _canEdit(_items[i])
                                    ? () => unawaited(_editFast(_items[i]))
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorName.colorWhite,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Transform.rotate(
              angle: math.pi,
              child: Assets.icons.solarAltArrowLeftLinear.svg(
                width: 20,
                height: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});

  final FastStats stats;

  @override
  Widget build(BuildContext context) {
    String hours(int minutes) {
      if (minutes < 60) return '${minutes}m';
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }

    final rate = (stats.completionRate * 100).round();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'fasting_history_page.stats_title'.tr(),
              style: AppTextStyles.notificationsDate,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCell(
                    label: 'fasting_history_page.stat_fasts'.tr(),
                    value: '${stats.fasts}',
                  ),
                ),
                Expanded(
                  child: _StatCell(
                    label: 'fasting_history_page.stat_completed'.tr(),
                    value: '${stats.completedFasts}',
                  ),
                ),
                Expanded(
                  child: _StatCell(
                    label: 'fasting_history_page.stat_rate'.tr(),
                    value: '$rate%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCell(
                    label: 'fasting_history_page.stat_total'.tr(),
                    value: hours(stats.totalFastedMinutes),
                  ),
                ),
                Expanded(
                  child: _StatCell(
                    label: 'fasting_history_page.stat_longest'.tr(),
                    value: hours(stats.longestFastMinutes),
                  ),
                ),
                Expanded(
                  child: _StatCell(
                    label: 'fasting_history_page.stat_avg'.tr(),
                    value: hours(stats.avgFastMinutes),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTextStyles.bodyHistoryTitleSmall),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.notificationsEmptySubtitle),
      ],
    );
  }
}

final class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item, this.onTap});

  final FastHistoryItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toString();
    final date = DateFormat.yMMMd(locale).format(item.startedAt);
    final start = DateFormat.jm(locale).format(item.startedAt);
    final end = item.endedAt != null
        ? DateFormat.jm(locale).format(item.endedAt!)
        : '—';
    // Sürmekte olan oruç: süre şimdiye kadar geçen (önceden "— / 16h").
    final minutes =
        item.durationMinutes ??
        (item.status == 'active'
            ? DateTime.now().difference(item.startedAt).inMinutes
            : 0);
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    final duration = minutes <= 0
        ? '—'
        : mins == 0
        ? '${hours}h'
        : '${hours}h ${mins}m';
    final targetH = (item.targetMinutes / 60).round();
    final statusKey = switch (item.status) {
      'completed' => 'fasting_history_page.status_completed',
      'endedEarly' => 'fasting_history_page.status_ended_early',
      'cancelled' => 'fasting_history_page.status_cancelled',
      'active' => 'fasting_history_page.status_active',
      _ => 'fasting_history_page.status_completed',
    };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ColorName.colorWhite,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(date, style: AppTextStyles.notificationsDate),
                  ),
                  Text(
                    statusKey.tr(),
                    style: AppTextStyles.notificationsEmptySubtitle.copyWith(
                      color: item.goalReached
                          ? ColorName.colorOptionSelected
                          : ColorName.colorTitle.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.planCode != null && item.planCode!.isNotEmpty
                    ? '${item.planCode} · $duration / ${targetH}h'
                    : '$duration / ${targetH}h',
                style: AppTextStyles.bodyHistoryTitleSmall.copyWith(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$start → $end',
                style: AppTextStyles.notificationsEmptySubtitle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'fasting_history_page.empty_title'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.notificationsEmptyTitle,
            ),
            const SizedBox(height: 8),
            Text(
              'fasting_history_page.empty_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.notificationsEmptySubtitle,
            ),
          ],
        ),
      ),
    );
  }
}

final class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'fasting_history_page.error'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.notificationsEmptyTitle,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => unawaited(onRetry()),
              child: Text('fasting_history_page.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

final class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorName.colorWhite,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.add_rounded, color: ColorName.colorTitle),
        ),
      ),
    );
  }
}
