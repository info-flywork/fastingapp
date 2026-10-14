import 'dart:async';

import 'package:fastingapp/core/connectivity/connectivity_service.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/home_widgets/fasting_widget_publisher.dart';
import 'package:fastingapp/core/home_widgets/fasting_widget_sync.dart';
import 'package:fastingapp/core/home_widgets/water_widget_sync.dart';
import 'package:fastingapp/data/model/user/home_summary.dart';
import 'package:fastingapp/domain/notification/notifications_repository.dart';
import 'package:fastingapp/domain/nutrition/nutrition_repository.dart';
import 'package:fastingapp/domain/trackers/health_sync_service.dart';
import 'package:fastingapp/domain/trackers/trackers_repository.dart';
import 'package:fastingapp/presentation/fasting/bloc/fasting_session_cubit.dart';
import 'package:fastingapp/presentation/fasting/bloc/fasting_session_state.dart';
import 'package:fastingapp/presentation/home/bloc/home_bloc.dart';
import 'package:fastingapp/presentation/home/bloc/home_event.dart';
import 'package:fastingapp/presentation/home/bloc/home_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Uygulama genelinde veri tazeliği ve ana ekran widget'ları.
///
/// - Ön plana dönüş (en fazla ~30 sn'de bir), gün dönümü (gece yarısı) ve
///   internet geri gelince ana sayfa özeti sessizce yenilenir; özet oruç
///   durumunu da [FastingSessionCubit]'e taşır.
/// - Oruç durumu hangi ekrandan değişirse değişsin oruç widget'ı yayınlanır.
/// - Özetteki hafta ve bugünkü su widget'lara yazılır.
final class AppSyncScope extends StatefulWidget {
  const AppSyncScope({required this.child, super.key});

  final Widget child;

  @override
  State<AppSyncScope> createState() => _AppSyncScopeState();
}

class _AppSyncScopeState extends State<AppSyncScope> {
  static const _resumeThrottle = Duration(seconds: 30);

  late final AppLifecycleListener _lifecycle;
  Timer? _midnight;
  DateTime _lastRefresh = DateTime.now();
  DateTime _day = DateUtils.dateOnly(DateTime.now());
  String? _lastWeek;

  ConnectivityService get _connectivity => ConnectivityService.instance;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: _onResume,
      // Ana ekrana dönülürken widget'ın geri sayım resmi tazelensin.
      onHide: () => unawaited(FastingWidgetSync.refresh()),
    );
    _connectivity.reconnects.addListener(_onReconnect);
    _scheduleMidnight();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _connectivity.reconnects.removeListener(_onReconnect);
    _midnight?.cancel();
    super.dispose();
  }

  void _onResume() {
    final dayChanged = !DateUtils.isSameDay(_day, DateTime.now());
    if (dayChanged) _scheduleMidnight();
    if (!dayChanged &&
        DateTime.now().difference(_lastRefresh) < _resumeThrottle) {
      return;
    }
    _refresh();
  }

  void _onReconnect() => _refresh();

  /// Bir sonraki yerel gece yarısından hemen sonra (DST'de de doğru gün).
  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = DateTime.now();
    _day = DateUtils.dateOnly(now);
    final next = DateTime(now.year, now.month, now.day + 1, 0, 0, 5);
    _midnight = Timer(next.difference(now), () {
      _scheduleMidnight();
      _refresh();
    });
  }

  /// Yalnızca ana sayfa bir kez yüklendiyse (oturum açık, onboarding bitmiş).
  void _refresh() {
    final home = getIt<HomeBloc>();
    if (home.state is! HomeLoaded && home.state is! HomeError) return;
    _lastRefresh = DateTime.now();
    getIt<NutritionRepository>().invalidate();
    home.add(const HomeRefreshRequested());
    unawaited(getIt<NotificationsRepository>().refreshUnread());
    unawaited(getIt<HealthSyncService>().sync());
  }

  static bool _fastingChanged(FastingSessionState a, FastingSessionState b) =>
      a.fast?.id != b.fast?.id ||
      a.fast?.startedAt != b.fast?.startedAt ||
      a.fast?.plannedEndAt != b.fast?.plannedEndAt ||
      a.eatingWindow?.endsAt != b.eatingWindow?.endsAt ||
      a.plan?.signature != b.plan?.signature;

  DateTime? _waterWeekAt;

  /// Su widget'ının hafta çubukları sunucudan (en fazla 30 dk'da bir).
  Future<void> _syncWaterWeek() async {
    final last = _waterWeekAt;
    if (last != null &&
        DateTime.now().difference(last) < const Duration(minutes: 30) &&
        DateUtils.isSameDay(last, DateTime.now())) {
      return;
    }
    _waterWeekAt = DateTime.now();
    try {
      await WaterWidgetSync.saveServerWeek(
        await getIt<TrackersRepository>().getWaterWeek(),
      );
    } on Object {
      _waterWeekAt = null;
    }
  }

  void _onSummary(HomeSummary summary) {
    unawaited(WaterWidgetSync.setUnit(summary.waterUnit));
    unawaited(_syncWaterWeek());
    unawaited(
      WaterWidgetSync.updateToday(
        currentMl: summary.waterMl,
        goalMl: summary.waterGoalMl,
      ),
    );
    final week = _weekProgress(summary);
    final encoded = week?.join(',');
    if (week == null || encoded == _lastWeek) return;
    _lastWeek = encoded;
    unawaited(
      FastingWidgetSync.saveWeek(week).then((_) => FastingWidgetSync.refresh()),
    );
  }

  /// Sunucu haftası → Pazartesi-önce 0–1 oranlar (hedef: plan süresi).
  static List<double>? _weekProgress(HomeSummary summary) {
    if (summary.week.isEmpty) return null;
    final target = summary.plan?.fastMinutes ?? 960;
    final week = List<double>.filled(7, 0);
    for (final day in summary.week) {
      final date = DateTime.tryParse(day.date);
      if (date == null || target <= 0) continue;
      // Haftalık planda serbest gün -1; sunucu ilerlemesi (azaltılmış gün
      // işareti dahil) varsa o.
      week[date.weekday - 1] = !day.isRequiredDay
          ? -1
          : (day.progress ?? day.fastedMinutes / target).clamp(0.0, 1.0);
    }
    return week;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<FastingSessionCubit, FastingSessionState>(
          bloc: getIt<FastingSessionCubit>(),
          listenWhen: _fastingChanged,
          listener: (context, state) => publishFastingWidget(context, state),
        ),
        // Çıkışta özet temizlenir: sonraki kullanıcının haftası aynı
        // görünse de widget'a yeniden yazılsın.
        BlocListener<HomeBloc, HomeState>(
          bloc: getIt<HomeBloc>(),
          listenWhen: (a, b) => a is HomeLoaded && b is HomeInitial,
          listener: (context, state) {
            _lastWeek = null;
            _waterWeekAt = null;
          },
        ),
        BlocListener<HomeBloc, HomeState>(
          bloc: getIt<HomeBloc>(),
          listenWhen: (a, b) =>
              b is HomeLoaded && (a is! HomeLoaded || a.summary != b.summary),
          listener: (context, state) {
            final summary = (state as HomeLoaded).summary;
            if (summary != null) _onSummary(summary);
          },
        ),
      ],
      child: widget.child,
    );
  }
}
