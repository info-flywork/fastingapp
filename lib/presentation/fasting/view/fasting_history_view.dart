import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/core/sync/data_sync.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/utils/extensions/future_extensions.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/core/widgets/app_loading.dart';
import 'package:fastingapp/domain/fasting/fasting_repository.dart';
import 'package:fastingapp/generated/app_images.g.dart';
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

  /// Yeni yükleme başlayınca artar: eski yüklemenin cevabı yenisini ezmesin.
  int _loadGen = 0;

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

  /// Liste varken yeniden yükleme (düzenle / sil / aşağı çek) sayfayı
  /// spinner'a çevirmez; mevcut liste kalır, cevap gelince yenilenir.
  Future<void> _load() async {
    final gen = ++_loadGen;
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repo.listHistory(),
        _repo.getStats(range: 'all'),
      ]);
      if (!mounted || gen != _loadGen) return;
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
      if (!mounted || gen != _loadGen) return;
      setState(() {
        _loading = false;
        _error = errorMessageOf(e);
      });
      // Liste görünürken hata sessiz kalmasın.
      if (_items.isNotEmpty) AppSnackbar.showError(context, e);
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

  /// Liste ay ay gruplanır (yeniden eskiye; ay başlığı + oruç kartları).
  List<_Row> _rows(BuildContext context) {
    final locale = context.locale.toString();
    final rows = <_Row>[];
    DateTime? month;
    for (final item in _items) {
      final m = DateTime(item.startedAt.year, item.startedAt.month);
      if (m != month) {
        month = m;
        rows.add(_MonthRow(DateFormat.yMMMM(locale).format(m)));
      }
      rows.add(_FastRow(item));
    }
    return rows;
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
                    ? _EmptyBody(onAdd: () => unawaited(_addPastFast()))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: Builder(
                          builder: (context) {
                            final rows = _rows(context);
                            return ListView.builder(
                              controller: _scroll,
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: ClampingScrollPhysics(),
                              ),
                              padding: EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                bottom + 24,
                              ),
                              itemCount:
                                  rows.length + 1 + (_loadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: _StatsCard(stats: _stats),
                                  );
                                }
                                final i = index - 1;
                                if (i >= rows.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(child: AppLoading()),
                                  );
                                }
                                return switch (rows[i]) {
                                  _MonthRow(:final label) => Padding(
                                    padding: EdgeInsets.only(
                                      top: i == 0 ? 0 : 12,
                                      bottom: 10,
                                    ),
                                    child: Text(
                                      label,
                                      style: AppTextStyles.notificationsDate,
                                    ),
                                  ),
                                  _FastRow(:final item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _HistoryCard(
                                      item: item,
                                      onTap: _canEdit(item)
                                          ? () => unawaited(_editFast(item))
                                          : null,
                                    ),
                                  ),
                                };
                              },
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

sealed class _Row {
  const _Row();
}

final class _MonthRow extends _Row {
  const _MonthRow(this.label);

  final String label;
}

final class _FastRow extends _Row {
  const _FastRow(this.item);

  final FastHistoryItem item;
}

String _hm(int minutes) {
  if (minutes <= 0) return '—';
  if (minutes < 60) return '${minutes}m';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

/// Üstte maskot + başarı halkası, altında 3B ikonlu altı istatistik.
final class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});

  final FastStats stats;

  @override
  Widget build(BuildContext context) {
    final rate = stats.completionRate.clamp(0.0, 1.0);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppImages.mascotClock.image(width: 84, height: 84),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'fasting_history_page.stats_title'.tr(),
                        style: AppTextStyles.notificationsEmptySubtitle,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'fasting_history_page.stats_headline'.tr(
                          args: ['${stats.fasts}'],
                        ),
                        style: AppTextStyles.homeChallengeTitle.copyWith(
                          fontSize: 22,
                          height: 28 / 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'fasting_history_page.stats_completed_of'.tr(
                          args: ['${stats.completedFasts}', '${stats.fasts}'],
                        ),
                        style: AppTextStyles.notificationsEmptySubtitle
                            .copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                _RateRing(rate: rate),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    image: AppImages.streakFlame,
                    value: _hm(stats.totalFastedMinutes),
                    label: 'fasting_history_page.stat_total'.tr(),
                    tint: ColorName.colorFastingWidgetChip,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(
                    image: AppImages.kingSl,
                    value: _hm(stats.longestFastMinutes),
                    label: 'fasting_history_page.stat_longest'.tr(),
                    tint: ColorName.colorPlanFasting,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(
                    image: AppImages.sandClock,
                    value: _hm(stats.avgFastMinutes),
                    label: 'fasting_history_page.stat_avg'.tr(),
                    tint: ColorName.colorHungerGreen,
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

/// Başarı oranı halkası (tamamlanan / tüm oruçlar).
final class _RateRing extends StatelessWidget {
  const _RateRing({required this.rate});

  final double rate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: rate),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: value,
              strokeWidth: 7,
              strokeCap: StrokeCap.round,
              backgroundColor: ColorName.colorHungerGreen,
              valueColor: const AlwaysStoppedAnimation(ColorName.colorToggleOn),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(value * 100).round()}%',
                    style: AppTextStyles.notificationsDate,
                  ),
                  Text(
                    'fasting_history_page.stat_rate'.tr(),
                    style: AppTextStyles.notificationsEmptySubtitle.copyWith(
                      fontSize: 10,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.image,
    required this.value,
    required this.label,
    required this.tint,
  });

  final AppImageAsset image;
  final String value;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          image.image(width: 28, height: 28),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: AppTextStyles.bodyHistoryTitleSmall.copyWith(fontSize: 17),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.notificationsEmptySubtitle.copyWith(
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Durum rozeti: renk + 3B ikon.
({AppImageAsset image, Color fg, Color bg, String key}) _statusStyle(
  FastHistoryItem item,
) => switch (item.status) {
  'active' => (
    image: AppImages.sandClock,
    fg: ColorName.colorVibrantBlue,
    bg: ColorName.colorPlanChipBreakfastBg,
    key: 'fasting_history_page.status_active',
  ),
  'cancelled' => (
    image: AppImages.redWarning,
    fg: ColorName.colorOptionNegative,
    bg: ColorName.colorNegativeV2.withValues(alpha: 0.10),
    key: 'fasting_history_page.status_cancelled',
  ),
  'endedEarly' when !item.goalReached => (
    image: AppImages.yellowLightning,
    fg: ColorName.colorWarningOrange,
    bg: ColorName.colorPlanChipDinnerBg,
    key: 'fasting_history_page.status_ended_early',
  ),
  _ => (
    image: AppImages.greenTick3d,
    fg: ColorName.colorPhysicalHungerBadgeText,
    bg: ColorName.colorHungerGreen,
    key: 'fasting_history_page.status_completed',
  ),
};

final class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item, this.onTap});

  final FastHistoryItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toString();
    final day = DateFormat.d(locale).format(item.startedAt);
    final weekday = DateFormat.E(locale).format(item.startedAt);
    final start = DateFormat.Hm(locale).format(item.startedAt);
    final end = item.endedAt != null
        ? DateFormat.Hm(locale).format(item.endedAt!)
        : '—';
    // Sürmekte olan oruç: süre şimdiye kadar geçen.
    final minutes =
        item.durationMinutes ??
        (item.status == 'active'
            ? DateTime.now().difference(item.startedAt).inMinutes
            : 0);
    final target = item.targetMinutes;
    final progress = target <= 0 ? 0.0 : (minutes / target).clamp(0.0, 1.0);
    final style = _statusStyle(item);
    final plan = item.planCode;

    return Material(
      color: ColorName.colorWhite,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gün rozeti: gün numarası + kısa gün adı.
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      day,
                      style: AppTextStyles.bodyHistoryTitleSmall.copyWith(
                        fontSize: 20,
                        height: 1.1,
                        color: style.fg,
                      ),
                    ),
                    Text(
                      weekday,
                      style: AppTextStyles.notificationsEmptySubtitle.copyWith(
                        fontSize: 12,
                        color: style.fg,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: _hm(minutes),
                              style: AppTextStyles.bodyHistoryTitleSmall
                                  .copyWith(fontSize: 18),
                              children: [
                                TextSpan(
                                  text: ' / ${_hm(target)}',
                                  style: AppTextStyles
                                      .notificationsEmptySubtitle
                                      .copyWith(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _StatusPill(
                          image: style.image,
                          text: style.key.tr(),
                          fg: style.fg,
                          bg: style.bg,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: ColorName.colorPlanArcTrack,
                        valueColor: AlwaysStoppedAnimation(style.fg),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Assets.icons.solarClockCircleLineDuotone.svg(
                          width: 16,
                          height: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$start → $end',
                          style: AppTextStyles.notificationsEmptySubtitle
                              .copyWith(fontSize: 13),
                        ),
                        const Spacer(),
                        if (plan != null && plan.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: ColorName.colorHomeChipBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              formatPlanLabel(plan, null),
                              style: AppTextStyles.homeAlreadyInCount,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.image,
    required this.text,
    required this.fg,
    required this.bg,
  });

  final AppImageAsset image;
  final String text;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 3, 10, 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          image.image(width: 18, height: 18),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.homeAlreadyInCount.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

/// Henüz oruç yok: maskot + geçmiş oruç ekleme çağrısı.
final class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppImages.mascotClockv2.image(width: 160, height: 160),
            const SizedBox(height: 16),
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
            const SizedBox(height: 24),
            AppButton(
              label: 'fasting_history_page.entry_add_title'.tr(),
              onPressed: onAdd,
              showIcon: false,
              decoration: AppButtonDecoration.homeJoin(),
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
