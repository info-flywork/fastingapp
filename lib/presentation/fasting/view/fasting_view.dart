import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/home_widgets/fasting_widget_publisher.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/core/sync/data_sync.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/utils/enum/snackbar_type.dart'
    show SnackBarType;
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/core/widgets/bottom_navigation_bar/'
    'app_bottom_nav.dart';
import 'package:fastingapp/core/widgets/horseshoe_arc.dart';
import 'package:fastingapp/domain/fasting/fasting_repository.dart';
import 'package:fastingapp/domain/fasting/mochi_plan_repository.dart';
import 'package:fastingapp/domain/fasting/weekly_schedule.dart';
import 'package:fastingapp/domain/revenue_cat/revenue_cat_service.dart';
import 'package:fastingapp/domain/user/user_repository.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_bloc.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_state.dart';
import 'package:fastingapp/presentation/fasting/bloc/fasting_session_cubit.dart';
import 'package:fastingapp/presentation/fasting/bloc/fasting_session_state.dart';
import 'package:fastingapp/presentation/fasting/fasting_arc_stages.dart';
import 'package:fastingapp/presentation/fasting/fasting_finish_flow.dart';
import 'package:fastingapp/presentation/fasting/view/fasting_fast_forecast_card.dart';
import 'package:fastingapp/presentation/fasting/view/fasting_mochi_plan_card.dart';
import 'package:fastingapp/presentation/fasting/view/fasting_plan_day_card.dart';
import 'package:fastingapp/presentation/fasting/view/fasting_plan_sheet.dart';
import 'package:fastingapp/presentation/fasting/view/fasting_start_sheet.dart';
import 'package:fastingapp/presentation/home/bloc/home_bloc.dart';
import 'package:fastingapp/presentation/home/bloc/home_state.dart';
import 'package:fastingapp/presentation/home/view/home_view.dart';
import 'package:fastingapp/presentation/home/weight_entry_flow.dart';
import 'package:fastingapp/presentation/meal_records/meal_detail_args.dart';
import 'package:fastingapp/presentation/plans/plan_change_flow.dart';
import 'package:fastingapp/presentation/plans/plans_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

/// Oruç sekmesi — öğün zamanı, horseshoe ve aksiyonlar.
final class FastingView extends StatefulWidget {
  const FastingView({super.key});

  @override
  State<FastingView> createState() => _FastingViewState();
}

class _FastingViewState extends State<FastingView> {
  final _cubit = getIt<FastingSessionCubit>();

  /// Seçili sekme kullanıcınındır: oruç başlayınca / bitince kendiliğinden
  /// değişmez. Uygulama açıkken son seçim hatırlanır (ilk açılış: vücut).
  static var _lastMealTab = false;
  var _mealSelected = _lastMealTab;
  Timer? _tick;

  /// Her saniye artar; yalnızca sayaç/yay bölümü dinler.
  final _clock = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    // Önce özet/önbellek — uzak /fasts/active beklerken boş 00:00:00 kalmasın.
    final hadSession = _cubit.state.fetchedAt != null;
    if (!hadSession) _seedFromHomeSummary();
    final fetchedAt = _cubit.state.fetchedAt;
    // Loading gösterme: iskelet/boş durum uzamasın; arka planda doğrula.
    if (fetchedAt == null ||
        !hadSession ||
        DateTime.now().difference(fetchedAt) > const Duration(minutes: 1)) {
      unawaited(_cubit.refresh(showLoading: false));
    }
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && (_cubit.state.isFasting || _cubit.state.isEating)) {
        _clock.value++;
      }
    });
    // Widget yayını uygulama kökünde (`AppSyncScope`), cubit değiştikçe.
  }

  /// Ana sayfa / disk özetinden anında doldur (ağ yanıtını bekleme).
  void _seedFromHomeSummary() {
    final home = getIt<HomeBloc>().state;
    if (home is HomeLoaded && home.summary != null) {
      final s = home.summary!;
      _cubit.applyFromSummary(
        fast: s.activeFast,
        eatingWindow: s.eatingWindow,
        plan: s.plan,
        serverTime: s.serverTime,
      );
      return;
    }
    final auth = getIt<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;
    final cached = getIt<UserRepository>().cachedSummary(auth.user.id);
    if (cached == null) return;
    _cubit.applyFromSummary(
      fast: cached.activeFast,
      eatingWindow: cached.eatingWindow,
      plan: cached.plan,
      serverTime: cached.serverTime,
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    _clock.dispose();
    super.dispose();
  }

  void _selectTab({required bool meal}) {
    setState(() => _mealSelected = _lastMealTab = meal);
  }

  String _planTitle(FastingSessionState session) => session.planTitle;

  /// Seri ana sayfa özetinden (oruç bitince tazelenir).
  int get _streakDays => switch (getIt<HomeBloc>().state) {
    HomeLoaded(:final progress) => progress.streakDays,
    _ => 0,
  };

  /// Hedefe ulaşılmadıysa "erken bitir" onayı; ulaşıldıysa doğrudan bitirme
  /// ekranı (onay metni "hedefine henüz ulaşmadın" diyor).
  Future<void> _finishFast(FastingSessionState session) async {
    if (session.fast == null) return;
    if (!_goalReached(session)) {
      final confirmed = await AppDialogs.instance.showEndFast(context);
      if (confirmed != true || !mounted) return;
    }
    await FastingFinishFlow.open();
  }

  static bool _goalReached(FastingSessionState session) {
    final fast = session.fast;
    final elapsed = session.liveMetrics?.elapsed;
    if (fast == null || elapsed == null) return false;
    return elapsed.inMinutes >= fast.targetMinutes;
  }

  /// Oruç sekmesindeki plan listesi → [applyPlanChange] (dialog + loading).
  Future<void> _pickPlan(FastingSessionState session) async {
    final plan = session.plan;
    final current =
        PlansCatalog.forPlan(plan?.planCode, timing: plan?.timing) ??
        PlansCatalog.beginnerRow1.first;
    final picked = await showModalBottomSheet<PlansCardData>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FastingPlanSheet(selected: current),
    );
    if (!mounted || picked == null) return;
    // Haftalık plan: aynı plan da seçilebilir (günleri düzenlemek için).
    if (picked.isWeekly) {
      final ok = await openWeeklyPlan(
        context: context,
        session: _cubit,
        plan: picked,
      );
      if (mounted && ok) _publishFastingWidget(_cubit.state);
      return;
    }
    if (picked == current) return;
    final ok = await applyPlanChange(
      context: context,
      session: _cubit,
      planCode: picked.planCode,
      timing: picked.timing,
    );
    if (!mounted || !ok) return;
    _publishFastingWidget(_cubit.state);
  }

  String _shareText(FastingSessionState session) {
    final planTitle = _planTitle(session);
    final started = _startedLabel(session) ?? '–';
    final ends = _endsLabel(session) ?? '–';
    final metrics = session.liveMetrics;
    if (_mealSelected) {
      return 'fasting_page.share_meal'.tr(
        args: [planTitle, started, ends, '$_streakDays'],
      );
    }
    final pct = metrics == null
        ? '0'
        : (metrics.progress * 100).round().toString();
    final elapsed = metrics == null
        ? '00:00:00'
        : formatElapsedHms(metrics.elapsed);
    final percent = 'fasting_page.share_percent'.tr(args: [pct]);
    return 'fasting_page.share_fasting'.tr(
      args: [planTitle, elapsed, percent, started, ends, '$_streakDays'],
    );
  }

  Future<void> _shareStatus(BuildContext anchor) async {
    final box = anchor.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    await SharePlus.instance.share(
      ShareParams(text: _shareText(_cubit.state), sharePositionOrigin: origin),
    );
  }

  /// Moladayken oruç başlatmadan önce onay ister (yemek penceresi kısalır).
  /// Molada değilse ya da kullanıcı onaylarsa `true`.
  Future<bool> _confirmEarlyStart(FastingSessionState session) async {
    final endsAt = session.eatingWindow?.endsAt;
    if (!session.isEating || endsAt == null) return true;
    final remaining = endsAt.difference(DateTime.now());
    if (remaining <= Duration.zero) return true;
    final ok = await AppDialogs.instance.showEarlyFastStart(
      context,
      remaining: remaining,
    );
    return ok ?? false;
  }

  Future<void> _pickStart(FastingSessionState session) async {
    if (session.isFasting) return;
    if (!await _confirmEarlyStart(session) || !mounted) return;
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FastingStartSheet(initial: DateTime.now()),
    );
    if (!mounted || picked == null) return;
    await _cubit.startFast(startedAt: picked);
    if (!mounted) return;
    _showStartError();
  }

  /// Mochi'nin önerdiği süreyi başlatır; kayıtlı planın saatini kullanmaz.
  Future<void> _startMochiPlan(
    FastingSessionState session,
    MochiDailyPlan plan,
  ) async {
    if (session.isFasting) return;
    if (!await _confirmEarlyStart(session) || !mounted) return;
    final now = DateTime.now();
    final initial = plan.startsAt.isAfter(now) ? now : plan.startsAt;
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FastingStartSheet(initial: initial),
    );
    if (!mounted || picked == null) return;
    await _cubit.startFast(
      startedAt: picked,
      targetMinutes: plan.fastHours * 60,
    );
    if (!mounted) return;
    _showStartError();
  }

  void _showStartError() {
    final error = _cubit.state.errorMessage;
    if (error == null) return;
    AppSnackbar.show(context: context, text: error, type: SnackBarType.failure);
  }

  void _publishFastingWidget(FastingSessionState session) =>
      publishFastingWidget(context, session);

  /// Haftalık planda bugünün program günü; günlük planda null.
  WeeklyDay? _todayPlanDay(FastingSessionState session) =>
      session.plan?.dayFor(DateTime.now());

  static String? _todayCheckin(HomeState state) {
    if (state is! HomeLoaded) return null;
    for (final d in state.summary?.week ?? const <SummaryWeekDay>[]) {
      if (d.isToday) return d.checkin;
    }
    return null;
  }

  /// İşaret sunucuya yazılana kadar ekranda hemen görünsün (yalnızca o gün).
  ({DateTime day, String status})? _localCheckin;

  String? get _checkinOverride {
    final local = _localCheckin;
    if (local == null || !DateUtils.isSameDay(local.day, DateTime.now())) {
      return null;
    }
    return local.status;
  }

  /// Azaltılmış gün: "Tamamladım / Atladım" (`PUT /plans/days/:date`).
  Future<void> _checkinToday(bool done) async {
    final previous = _localCheckin;
    setState(
      () => _localCheckin = (
        day: DateTime.now(),
        status: done ? 'done' : 'skipped',
      ),
    );
    try {
      await getIt<FastingRepository>().checkinPlanDay(
        DateTime.now(),
        done: done,
      );
      DataSync.afterWrite();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _localCheckin = previous);
      AppSnackbar.showError(context, e);
    }
  }

  /// Seçili sekmenin at nalı + üst kart modeli. Kart yalnızca ilerleme bir
  /// aşamaya ulaştıysa görünür.
  _ArcView _arcView(FastingSessionState session) {
    final metrics = session.liveMetrics;
    final live = metrics?.elapsed ?? Duration.zero;
    final planTitle = _planTitle(session);
    // Haftalık planda bugünün oruç süresi (Crescendo / özel hafta).
    final fastMinutes =
        session.fast?.targetMinutes ??
        _todayPlanDay(session)?.fastMinutes ??
        session.plan?.fastMinutes ??
        _planHours(planTitle) * 60;

    final eatMinutes = (session.eatingWindow?.eatMinutes ?? 0) > 0
        ? session.eatingWindow!.eatMinutes
        : math.max(60, 24 * 60 - fastMinutes);
    // Oruç bitti, öğün penceresi açık: iki sekme de ana sayfadaki gibi
    // kalan süreyi sayar. Boş 00:00:00 oruç saati değildir.
    if (session.isEating) {
      final remaining = metrics?.remainingToPlannedEnd ?? Duration.zero;
      final used = eatMinutes <= 0
          ? 0.0
          : (live.inSeconds / (eatMinutes * 60)).clamp(0.0, 1.0);
      if (!_mealSelected) {
        return _ArcView(
          stages: const [],
          card: null,
          progress: used,
          elapsed: remaining,
          heading: 'fasting_page.on_break',
          captionKey: 'fasting_page.eating_remaining',
        );
      }
    }

    if (!_mealSelected) {
      // Vücut sekmesi: orucun başından hedefe. Hedef dolunca sayaç hedefte
      // donar, yay %100 kalır — aşım ("Hedef +…") gösterilmez.
      final fasting = session.isFasting;
      final target = Duration(minutes: fastMinutes);
      final goalReached = fasting && live >= target;
      final elapsed = !fasting ? Duration.zero : (goalReached ? target : live);
      final hours = elapsed.inSeconds / 3600;
      return _ArcView(
        stages: bodyArcStages(
          targetHours: fastMinutes / 60,
          elapsedHours: hours,
          active: fasting,
        ),
        card: fasting
            ? bodyStage(
                bodyPlanStageIndex(
                  targetHours: fastMinutes / 60,
                  elapsedHours: hours,
                ),
                reached: true,
              )
            : null,
        progress: fasting
            ? (goalReached ? 1.0 : (metrics?.progress ?? 0.0))
            : 0.0,
        elapsed: elapsed,
        goalReached: goalReached,
        // Hedef doldu → "orucunu boz" aşaması; öğün kaydet göster.
        showSaveMeal: goalReached,
      );
    }

    // Öğün sekmesi: 24 saatlik döngü (oruç + pencere) tek yayda. Oruçta
    // "orucunu boz" noktasına doğru dolar; kart pencere açılınca başlar.
    final cappedFastMinutes = session.isFasting
        ? live.inMinutes.clamp(0, fastMinutes)
        : null;
    final fastingGoalReached =
        session.isFasting && live.inMinutes >= fastMinutes;
    final cycle = mealCycleArc(
      fastMinutes: fastMinutes,
      eatMinutes: eatMinutes,
      fastElapsedMinutes: cappedFastMinutes,
      eatElapsedMinutes: session.isEating ? live.inMinutes : null,
      forceAllReached: fastingGoalReached,
    );
    final nextStart = session.plan?.eatWindow?.end;
    // Sayaç saniyeli kalsın; hedef aşımında yalnızca üst sınıra tut (dakikaya yuvarlama yok).
    final target = Duration(minutes: fastMinutes);
    final displayElapsed = session.isEating
        ? (metrics?.remainingToPlannedEnd ?? Duration.zero)
        : session.isFasting
        ? (live > target ? target : live)
        : Duration.zero;
    final eatStage = session.isEating
        ? eatingStageIndex(live.inMinutes, eatMinutes)
        : -1;
    // Yazı, yayın konumunu değil öğün penceresindeki gerçek payı söylesin.
    // Yayın başı ~%22'de; yeni biten oruçta bu "geçen süre" gibi okunuyordu.
    final eatingShare = session.isEating && eatMinutes > 0
        ? (live.inSeconds / (eatMinutes * 60)).clamp(0.0, 1.0)
        : null;
    return _ArcView(
      heading: session.isEating ? 'fasting_page.on_break' : null,
      stages: session.isEating ? const [] : cycle.stages,
      card: null,
      // Hedef dolunca yay görsel olarak tam dolu (24s döngü payı değil).
      progress: fastingGoalReached
          ? 1.0
          : session.isEating
          ? (eatingShare ?? cycle.progress)
          : cycle.progress,
      captionProgress: eatingShare,
      elapsed: displayElapsed,
      captionKey: session.isEating ? 'fasting_page.eating_remaining' : null,
      goalReached: fastingGoalReached,
      // Ne oruç ne pencere: planın saatine göre bilgi.
      note: !session.isFasting && !session.isEating && nextStart != null
          ? 'fasting_page.next_fast_at'.tr(args: [nextStart])
          : null,
      // Orucunu boz aşaması (hedef doldu veya pencerenin ilk dilimi).
      showSaveMeal: fastingGoalReached || eatStage == 0,
    );
  }

  /// Plan etiketi `14-10` veya `14:10` olabilir.
  List<String> _planParts(String title) =>
      title.replaceAll(':', '-').split('-').map((e) => e.trim()).toList();

  int _planHours(String title) {
    final parts = _planParts(title);
    return int.tryParse(parts.isNotEmpty ? parts.first : '') ?? 16;
  }

  Duration _fastTarget(FastingSessionState session) {
    final minutes =
        session.fast?.targetMinutes ??
        _todayPlanDay(session)?.fastMinutes ??
        session.plan?.fastMinutes ??
        _planHours(_planTitle(session)) * 60;
    return Duration(minutes: minutes);
  }

  /// Aktif oruç yoksa sıradaki oruç başlangıcı (yeme penceresi değil).
  DateTime? _nextFastStart(FastingSessionState session) {
    final eat = session.eatingWindow;
    return eat?.suggestedNextStartAt ??
        eat?.endsAt ??
        _clockToday(session.plan?.eatWindow?.end);
  }

  DateTime? _clockToday(String? hm) {
    final parts = hm?.split(':');
    if (parts == null || parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, h, m);
  }

  /// Aktif oruç yokken "başladı" denmez: sıradaki saat gelecek zamandır.
  String _startedCaption(FastingSessionState session) {
    if (session.isFasting) return 'fasting_page.started_label';
    if (session.isEating) return 'fasting_page.eating_started_label';
    return 'fasting_page.next_starts_label';
  }

  String _endsCaption(FastingSessionState session) {
    if (session.isFasting) return 'fasting_page.ends_label';
    if (session.isEating) return 'fasting_page.next_starts_label';
    return 'fasting_page.next_ends_label';
  }

  String? _startedLabel(FastingSessionState session) {
    final eat = session.eatingWindow;
    if (session.isEating && eat != null) return _boundLabel(eat.startedAt);
    final start = session.fast?.startedAt ?? _nextFastStart(session);
    return start == null ? null : _boundLabel(start);
  }

  String? _endsLabel(FastingSessionState session) {
    final fast = session.fast;
    if (fast != null) {
      // Hedef süre ile chip (14:10) aynı kalsın; sunucu plannedEnd saparsa
      // start + hedef kullanılır.
      return _boundLabel(fast.startedAt.add(_fastTarget(session)));
    }
    final eat = session.eatingWindow;
    if (session.isEating && eat != null) {
      return _boundLabel(eat.suggestedNextStartAt ?? eat.endsAt);
    }
    final start = _nextFastStart(session);
    return start == null ? null : _boundLabel(start.add(_fastTarget(session)));
  }

  String _boundLabel(DateTime value) {
    final locale = context.locale.toString();
    final day = DateUtils.isSameDay(value, DateTime.now())
        ? 'fasting_page.start_sheet_today'.tr()
        : DateFormat('d MMM', locale).format(value);
    final clock = context.locale.languageCode == 'en'
        ? DateFormat('h:mm a', locale).format(value)
        : DateFormat('HH:mm', locale).format(value);
    return '$day, $clock';
  }

  @override
  Widget build(BuildContext context) {
    // Hatalar işlemi başlatan yerde gösterilir; widget yayını uygulama
    // kökünde (`AppSyncScope`). Sekme durum değişince kendiliğinden değişmez.
    return BlocBuilder<FastingSessionCubit, FastingSessionState>(
      bloc: _cubit,
      builder: (context, session) {
        final planTitle = _planTitle(session);
        return Scaffold(
          backgroundColor: ColorName.colorProfileBack,
          // ListView ekrandan çıkan kartları atıp geri gelince yeniden
          // kuruyordu: kendi verisini yükleyen kartlar (tahmin, challenge,
          // Mochi planı) önce boş gelip sonra açılıyor, kaydırırken sayfa
          // zıplıyordu. Sayfa kısa; hepsi bir kez kurulur ve yaşar.
          body: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: AppBottomNav.barClearance),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: getIt<RevenueCatService>().isPremium,
                  builder: (context, isPremium, _) =>
                      BlocSelector<HomeBloc, HomeState, int>(
                        bloc: getIt<HomeBloc>(),
                        selector: (_) => _streakDays,
                        builder: (context, streakDays) => HomeTopBar(
                          streakDays: streakDays,
                          isPremium: isPremium,
                          onPremiumTapped: () => unawaited(
                            getIt<RevenueCatService>().presentPaywall(),
                          ),
                          onChatTapped: () =>
                              context.pushNamed(RoutePaths.chat.name),
                        ),
                      ),
                ),
                const SizedBox(height: 16),
                _ActionRow(
                  mealSelected: _mealSelected,
                  onBodyTap: () => _selectTab(meal: false),
                  onMealTap: () => _selectTab(meal: true),
                  onShare: _shareStatus,
                ),
                const SizedBox(height: 20),
                // Haftalık plan: bugün oruç günü değilse günün kartı (serbest /
                // 500 kcal); oruç yine de isteğe bağlı başlatılabilir.
                if (_todayPlanDay(session) case final day?
                    when day.type != WeeklyDayType.fast &&
                        !session.isFasting &&
                        !session.isEating) ...[
                  BlocSelector<HomeBloc, HomeState, String?>(
                    bloc: getIt<HomeBloc>(),
                    selector: _todayCheckin,
                    builder: (context, checkin) => FastingPlanDayCard(
                      day: day,
                      checkin: _checkinOverride ?? checkin,
                      onCheckin: (done) => unawaited(_checkinToday(done)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Saniyelik sayaç yalnızca bu bölümü yeniden kurar (sayfanın tamamını değil).
                ValueListenableBuilder<int>(
                  valueListenable: _clock,
                  builder: (context, _, _) {
                    final view = _arcView(session);
                    return AnimatedSize(
                      duration: const Duration(milliseconds: 480),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 480),
                        layoutBuilder: (current, previous) {
                          return ClipRect(
                            child: Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                ...previous,
                                if (current != null) current,
                              ],
                            ),
                          );
                        },
                        transitionBuilder: (child, animation) {
                          return AnimatedBuilder(
                            animation: animation,
                            builder: (context, child) {
                              final reverse =
                                  animation.status == AnimationStatus.reverse;
                              final toRight = !_mealSelected;
                              final dx = reverse
                                  ? (toRight
                                        ? 1 - animation.value
                                        : animation.value - 1)
                                  : (toRight
                                        ? animation.value - 1
                                        : 1 - animation.value);
                              return FractionalTranslation(
                                translation: Offset(dx, 0),
                                child: Opacity(
                                  opacity: animation.value,
                                  child: child,
                                ),
                              );
                            },
                            child: child,
                          );
                        },
                        child: _StageView(
                          key: ValueKey(_mealSelected ? 'meal' : 'body'),
                          view: view,
                          bodyMode: !_mealSelected,
                          planTitle: planTitle,
                          started: _startedLabel(session),
                          ends: _endsLabel(session),
                          startedCaption: _startedCaption(session),
                          endsCaption: _endsCaption(session),
                          state: session.isFasting
                              ? (_goalReached(session)
                                    ? _FastState.goalReached
                                    : _FastState.fasting)
                              : session.isEating
                              ? _FastState.eating
                              : _FastState.idle,
                          onEditPlan: () => _pickPlan(session),
                          onAction: session.isFasting
                              ? () => unawaited(_finishFast(session))
                              : () => unawaited(_pickStart(session)),
                          onCardTap: () => context.pushNamed(
                            _mealSelected
                                ? RoutePaths.eatingWindow.name
                                : RoutePaths.bodyStatus.name,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Kartların 12px üst boşluğuyla birlikte aralık 16.
                const SizedBox(height: 4),
                const FastingFastForecastCard(),
                const SizedBox(height: 4),
                const HomeChallengeCard(),
                const SizedBox(height: 4),
                // Su, adım, kilo, açlık: ana sayfayla aynı veri (/user/summary).
                BlocBuilder<HomeBloc, HomeState>(
                  bloc: getIt<HomeBloc>(),
                  builder: (context, home) {
                    final summary = home is HomeLoaded ? home.summary : null;
                    return Column(
                      children: [
                        HomeMetricCards(
                          waterMl: summary?.waterMl ?? 0,
                          waterGoalMl: summary?.waterGoalMl ?? 2500,
                          steps: summary?.steps ?? 0,
                          stepsGoal: summary?.stepsGoal ?? 8000,
                          waterUnit: summary?.waterUnit ?? 'ml',
                          onWaterTapped: () =>
                              context.pushNamed(RoutePaths.water.name),
                          onStepsTapped: () =>
                              context.pushNamed(RoutePaths.steps.name),
                        ),
                        const SizedBox(height: 4),
                        HomeWeightCard(
                          currentKg: summary?.weightCurrentKg,
                          startKg: summary?.weightStartKg,
                          goalKg: summary?.weightGoalKg,
                          unit: summary?.weightUnit ?? 'kg',
                          onTap: () =>
                              context.pushNamed(RoutePaths.bodyHistory.name),
                          onEditTap: () => unawaited(
                            WeightEntryFlow.open(
                              context,
                              currentKg: summary?.weightCurrentKg,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        HomeHungerTrackerCard(
                          physicalCount: summary?.hungerPhysical ?? 0,
                          emotionalCount: summary?.hungerEmotional ?? 0,
                          onTap: () =>
                              context.pushNamed(RoutePaths.hungerTracker.name),
                        ),
                      ],
                    );
                  },
                ),
                FastingMochiPlanCard(
                  onStart: (plan) => unawaited(_startMochiPlan(session, plan)),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        );
      },
    );
  }
}

final class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.mealSelected,
    required this.onBodyTap,
    required this.onMealTap,
    required this.onShare,
  });

  final bool mealSelected;
  final VoidCallback onBodyTap;
  final VoidCallback onMealTap;
  final Future<void> Function(BuildContext anchor) onShare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Builder(
            builder: (anchor) {
              return _CircleButton(
                onTap: () => unawaited(onShare(anchor)),
                child: Assets.icons.solarSquareShareLineLineDuotone.svg(),
              );
            },
          ),
          const Spacer(),
          _ModeToggle(
            mealSelected: mealSelected,
            onBodyTap: onBodyTap,
            onMealTap: onMealTap,
          ),
          const Spacer(),
          _CircleButton(
            onTap: () => context.pushNamed(RoutePaths.water.name),
            child: Transform.scale(
              scale: 1.45,
              child: AppImages.water.image(
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: ColorName.colorBlack.withValues(alpha: 0.05),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 40, height: 40, child: Center(child: child)),
        ),
      ),
    );
  }
}

final class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.mealSelected,
    required this.onBodyTap,
    required this.onMealTap,
  });

  final bool mealSelected;
  final VoidCallback onBodyTap;
  final VoidCallback onMealTap;

  static const _segmentWidth = 44.0;
  static const _gap = 8.0;
  static const _duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorUnitToggleBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ColorName.colorBlack.withValues(alpha: 0.12),
            offset: const Offset(0, 1),
            blurRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          width: _segmentWidth * 2 + _gap,
          height: 32,
          child: Stack(
            children: [
              IgnorePointer(
                child: AnimatedAlign(
                  duration: _duration,
                  curve: Curves.easeOutCubic,
                  alignment: mealSelected
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: const _SelectedPill(width: _segmentWidth),
                ),
              ),
              Row(
                children: [
                  _ModeSegment(
                    onTap: onBodyTap,
                    child: Transform.scale(
                      scale: 1.25,
                      child: AppImages.human.image(
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: _gap),
                  _ModeSegment(
                    onTap: onMealTap,
                    child: AppImages.forkClosest.image(
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _SelectedPill extends StatelessWidget {
  const _SelectedPill({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorName.colorBlack.withValues(alpha: 0.05),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: SizedBox(width: width, height: 32),
    );
  }
}

final class _ModeSegment extends StatelessWidget {
  const _ModeSegment({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _ModeToggle._segmentWidth,
        height: 32,
        child: Center(child: child),
      ),
    );
  }
}

/// Bir sekmenin at nalı modeli ([_FastingViewState._arcView]).
@immutable
final class _ArcView {
  const _ArcView({
    required this.stages,
    required this.card,
    required this.progress,
    required this.elapsed,
    this.heading,
    this.goalReached = false,
    this.note,
    this.showSaveMeal = false,
    this.captionProgress,
    this.captionKey,
  });

  final List<ArcStage> stages;

  /// Ulaşılan son aşama; hiçbir aşamaya ulaşılmadıysa null (kart yok).
  final ArcStage? card;
  final double progress;
  final Duration elapsed;
  final String? heading;

  /// Hedef süre doldu — sayaç donar, üst yazı "Hedefe ulaştın".
  final bool goalReached;

  /// Yay altında bilgi satırı (ör. planına göre sonraki oruç saati).
  final String? note;

  /// "Orucunu boz" aşamasında Öğün kaydet butonu.
  final bool showSaveMeal;

  /// "Geçen süre %" yazısı. Yoksa yayın ilerlemesi kullanılır.
  final double? captionProgress;

  /// Verilirse yüzde yazısı yerine bu anahtar (öğün penceresinde kalan süre).
  final String? captionKey;

  int get percent => ((captionProgress ?? progress) * 100).round();
}

/// Oruç ekranının durumu (butonlar buna göre).
enum _FastState { idle, fasting, goalReached, eating }

final class _StageView extends StatelessWidget {
  const _StageView({
    required this.view,
    required this.bodyMode,
    required this.planTitle,
    required this.started,
    required this.ends,
    required this.startedCaption,
    required this.endsCaption,
    required this.state,
    required this.onEditPlan,
    required this.onAction,
    required this.onCardTap,
    super.key,
  });

  final _ArcView view;
  final bool bodyMode;
  final String planTitle;
  final String? started;
  final String? ends;
  final String startedCaption;
  final String endsCaption;
  final _FastState state;
  final VoidCallback onEditPlan;
  final VoidCallback onAction;
  final VoidCallback onCardTap;

  @override
  Widget build(BuildContext context) {
    final card = view.card;
    return Column(
      children: [
        if (view.heading != null) ...[
          Text(
            view.heading!.tr(),
            textAlign: TextAlign.center,
            style: AppTextStyles.fastingMealTitle,
          ),
          const SizedBox(height: 12),
        ],
        // Kart yalnızca bir aşamaya ulaşıldıysa; aşama değişince yumuşak geçiş.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: card == null
              ? const SizedBox(key: ValueKey('no-card'), width: double.infinity)
              : Padding(
                  key: ValueKey(card.titleKey),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _StageCard(
                    image: card.image,
                    title: card.titleKey.tr(),
                    body: card.bodyKey.tr(),
                    onTap: onCardTap,
                  ),
                ),
        ),
        _FastingArc(
          planTitle: planTitle,
          onEditPlan: onEditPlan,
          stages: view.stages,
          progressColor: bodyMode
              ? ColorName.colorMealPositive
              : ColorName.colorPlanFasting,
          progress: view.progress,
          elapsedText: formatElapsedHms(view.elapsed),
          caption: view.goalReached
              ? 'fasting_page.goal_reached'.tr()
              : view.captionKey != null
              ? view.captionKey!.tr()
              : 'fasting_page.time_passed'.tr(args: ['${view.percent}']),
        ),
        if (view.note != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              view.note!,
              textAlign: TextAlign.center,
              style: AppTextStyles.fastingBreakBody,
            ),
          ),
        ],
        const SizedBox(height: 16),
        _FastingActions(
          planTitle: planTitle,
          started: started,
          ends: ends,
          startedCaption: startedCaption,
          endsCaption: endsCaption,
          state: state,
          showSaveMeal: view.showSaveMeal,
          onAction: onAction,
          onSaveMeal: () => context.pushNamed(
            RoutePaths.mealDetail.name,
            extra: MealDetailArgs(initialEatenAt: DateTime.now()),
          ),
        ),
      ],
    );
  }
}

final class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.image,
    required this.title,
    required this.body,
    this.onTap,
  });

  final AppImageAsset image;
  final String title;
  final String body;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final picture = image.image(width: 48, height: 48, fit: BoxFit.contain);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                picture,
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.fastingBreakTitle),
                      Text(
                        body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.fastingBreakBody,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Assets.icons.solarAltArrowUpLineDuotoneRight.svg(
                  width: 20,
                  height: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _FastingArc extends StatelessWidget {
  const _FastingArc({
    required this.planTitle,
    required this.onEditPlan,
    required this.stages,
    required this.progressColor,
    required this.progress,
    required this.elapsedText,
    required this.caption,
  });

  final Color progressColor;

  final String planTitle;
  final VoidCallback onEditPlan;

  /// Aşama işaretleri; konumları sabit, ilerleme ulaşınca renklenir.
  final List<ArcStage> stages;
  final double progress;
  final String elapsedText;

  /// Sayaç üstü satır ("Geçen süre %75" ya da "Hedefe ulaştın").
  final String caption;

  static const _arcTop = 18.0;
  static const _marker = 54.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final arcSize = Size(
              constraints.maxWidth,
              HorseshoeArc.diameterDefault + 5,
            );
            final arcStart = _pointOnArc(arcSize, 0);
            final height = _arcTop + arcStart.dy + _marker / 2 + 6;

            return SizedBox(
              height: height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: _arcTop,
                    left: 0,
                    right: 0,
                    height: arcSize.height,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        HorseshoeArc(
                          progress: progress,
                          minProgress: 0,
                          progressColor: progressColor,
                          trackColor: ColorName.colorUnitToggleBg,
                        ),
                        child!,
                        for (final stage in stages)
                          _ArcMarker(
                            key: ValueKey(stage.index),
                            center: _pointOnArc(arcSize, stage.t),
                            image: stage.image,
                            reached: stage.isReached,
                            current: stage.isCurrent,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      child: _ArcCaption(
        planTitle: planTitle,
        onEditPlan: onEditPlan,
        elapsedText: elapsedText,
        caption: caption,
      ),
    );
  }
}

Offset _pointOnArc(Size size, double t) {
  final radius = HorseshoeArc.radiusFor(size);
  final angle =
      HorseshoeArc.startRad + HorseshoeArc.sweepDegrees * math.pi / 180 * t;
  return Offset(
    size.width / 2 + radius * math.cos(angle),
    size.height / 2 + radius * math.sin(angle),
  );
}

final class _ArcCaption extends StatelessWidget {
  const _ArcCaption({
    required this.planTitle,
    required this.onEditPlan,
    required this.elapsedText,
    required this.caption,
  });

  final String planTitle;
  final VoidCallback onEditPlan;
  final String elapsedText;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(caption, style: AppTextStyles.fastingTimePassed),
        Text(elapsedText, style: AppTextStyles.fastingTimer),
        const SizedBox(height: 8),
        _PlanChip(title: planTitle, onEditPlan: onEditPlan),
      ],
    );
  }
}

final class _PlanChip extends StatelessWidget {
  const _PlanChip({required this.title, required this.onEditPlan});

  final String title;
  final VoidCallback onEditPlan;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorName.colorWhite,
        borderRadius: BorderRadius.circular(21),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(11, 3, 7, 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: AppTextStyles.fastingPlanChip),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onEditPlan,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: _PenIcon(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _PenIcon extends StatelessWidget {
  const _PenIcon();

  @override
  Widget build(BuildContext context) {
    return AppImages.solarPenBold1.image(
      width: 18,
      height: 18,
      fit: BoxFit.contain,
    );
  }
}

const _grayFilter = ColorFilter.matrix(<double>[
  0.2126,
  0.7152,
  0.0722,
  0,
  48,
  0.2126,
  0.7152,
  0.0722,
  0,
  48,
  0.2126,
  0.7152,
  0.0722,
  0,
  48,
  0,
  0,
  0,
  0.9,
  0,
]);

final class _ArcMarker extends StatelessWidget {
  const _ArcMarker({
    required this.center,
    required this.image,
    required this.reached,
    required this.current,
    super.key,
  });

  final Offset center;
  final AppImageAsset image;

  /// İlerleme bu işarete ulaştı: renkli; ulaşmadıysa gri.
  final bool reached;

  /// İçinde bulunulan aşama: hafif büyük.
  final bool current;

  @override
  Widget build(BuildContext context) {
    const size = _FastingArc._marker;
    final picture = image.image(fit: BoxFit.contain);
    return Positioned(
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      child: IgnorePointer(
        child: AnimatedScale(
          scale: current ? 1.12 : 1,
          duration: const Duration(milliseconds: 300),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ColorName.colorWhite,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ColorName.colorBlack.withValues(alpha: 0.05),
                  offset: const Offset(0, 1.3),
                  blurRadius: 5.4,
                ),
                BoxShadow(
                  color: ColorName.colorBlack.withValues(alpha: 0.1),
                  offset: const Offset(0, 1.3),
                  blurRadius: 5.4,
                ),
              ],
            ),
            child: ClipOval(
              child: SizedBox(
                width: size,
                height: size,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: reached
                      ? picture
                      : ColorFiltered(colorFilter: _grayFilter, child: picture),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _FastingActions extends StatelessWidget {
  const _FastingActions({
    required this.planTitle,
    required this.started,
    required this.ends,
    required this.startedCaption,
    required this.endsCaption,
    required this.state,
    required this.onAction,
    required this.onSaveMeal,
    this.showSaveMeal = false,
  });

  final String planTitle;
  final String? started;
  final String? ends;
  final String startedCaption;
  final String endsCaption;
  final _FastState state;
  final VoidCallback onAction;
  final VoidCallback onSaveMeal;
  final bool showSaveMeal;

  @override
  Widget build(BuildContext context) {
    final fasting =
        state == _FastState.fasting || state == _FastState.goalReached;
    // Mola: erken başlatılabilir ama onay ister; buton ikincil görünür.
    final primaryLabel = switch (state) {
      _FastState.fasting => 'fasting_page.finish_early'.tr(),
      _FastState.goalReached => 'fasting_page.finish_cta'.tr(),
      _FastState.idle => 'fasting_page.start_cta'.tr(args: [planTitle]),
      _FastState.eating => 'fasting_page.start_early'.tr(),
    };
    final showStruggle = fasting && state != _FastState.goalReached;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _TimeRow(
            started: started,
            ends: ends,
            startedCaption: startedCaption,
            endsCaption: endsCaption,
          ),
          const SizedBox(height: 20),
          AppButton(
            label: primaryLabel,
            onPressed: onAction,
            showIcon: false,
            decoration: switch (state) {
              _FastState.fasting => AppButtonDecoration.dark(),
              _FastState.eating => AppButtonDecoration.fastingAnother(),
              _ => AppButtonDecoration.fastingStart(),
            },
          ),
          // Orucunu boz: erken bitir ile zorlanıyorum arasında.
          if (showSaveMeal) ...[
            const SizedBox(height: 10),
            AppButton(
              label: 'fasting_page.save_meal'.tr(),
              onPressed: onSaveMeal,
              showIcon: false,
              decoration: AppButtonDecoration.fastingAnother(),
            ),
          ],
          // Zorlanma yalnızca hedefe ulaşmadan önce anlamlı.
          if (showStruggle) ...[
            const SizedBox(height: 10),
            AppButton(
              label: 'fasting_page.struggling'.tr(),
              onPressed: () =>
                  context.pushNamed(RoutePaths.fastingStruggle.name),
              showIcon: false,
              decoration: AppButtonDecoration.fastingStruggle(),
            ),
          ],
        ],
      ),
    );
  }
}

final class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.started,
    required this.ends,
    required this.startedCaption,
    required this.endsCaption,
  });

  final String? started;
  final String? ends;
  final String startedCaption;
  final String endsCaption;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(startedCaption.tr(), style: AppTextStyles.fastingBoundLabel),
            Text(started ?? '–', style: AppTextStyles.fastingBoundValue),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(endsCaption.tr(), style: AppTextStyles.fastingBoundLabel),
            Text(ends ?? '–', style: AppTextStyles.fastingBoundValue),
          ],
        ),
      ],
    );
  }
}
