import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/home_widgets/fasting_widget_sync.dart';
import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/core/utils/enum/snackbar_type.dart'
    show SnackBarType;
import 'package:fastingapp/domain/fasting/fasting_repository.dart';
import 'package:fastingapp/domain/revenue_cat/revenue_cat_service.dart';
import 'package:fastingapp/presentation/fasting/bloc/fasting_session_cubit.dart';
import 'package:fastingapp/presentation/fasting/bloc/fasting_session_state.dart';
import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/theme/app_text_styles.dart';
import 'package:fastingapp/core/utils/extensions/future_extensions.dart';
import 'package:fastingapp/core/widgets/app_button.dart';
import 'package:fastingapp/core/widgets/app_button_decoration.dart';
import 'package:fastingapp/core/widgets/bottom_navigation_bar/'
    'app_bottom_nav.dart';
import 'package:fastingapp/core/widgets/horseshoe_arc.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/generated/colors.gen.dart';
import 'package:fastingapp/presentation/fasting/fasting_finish_flow.dart';
import 'package:fastingapp/presentation/fasting/view/fasting_fast_forecast_card.dart';
import 'package:fastingapp/presentation/fasting/view/fasting_mochi_plan_card.dart';
import 'package:fastingapp/presentation/fasting/view/fasting_plan_sheet.dart';
import 'package:fastingapp/presentation/fasting/view/fasting_start_sheet.dart';
import 'package:fastingapp/presentation/home/bloc/home_bloc.dart';
import 'package:fastingapp/presentation/home/bloc/home_state.dart';
import 'package:fastingapp/presentation/home/view/home_view.dart';
import 'package:fastingapp/presentation/home/weight_entry_flow.dart';
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
  var _mealSelected = true;
  var _finishReady = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _syncTabFromSession(_cubit.state);
    unawaited(_cubit.refresh());
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && (_cubit.state.isFasting || _cubit.state.isEating)) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _publishFastingWidget(_cubit.state);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _syncTabFromSession(FastingSessionState session) {
    if (session.isFasting) {
      _mealSelected = false;
    } else if (session.isEating) {
      _mealSelected = true;
    }
  }

  String _planTitle(FastingSessionState session) => session.planTitle;

  /// Seri ana sayfa özetinden (oruç bitince tazelenir).
  int get _streakDays => switch (getIt<HomeBloc>().state) {
    HomeLoaded(:final progress) => progress.streakDays,
    _ => 0,
  };

  void _endFastLocal() {
    if (!mounted) return;
    setState(() {
      _mealSelected = true;
      _finishReady = false;
    });
    _publishFastingWidget(_cubit.state);
  }

  Future<void> _confirmEndFast(FastingSessionState session) async {
    final fast = session.fast;
    if (fast == null) return;
    final confirmed = await AppDialogs.instance.showEndFast(context);
    if (confirmed != true || !mounted) return;
    final saved = await FastingFinishFlow.open();
    if (!mounted || !saved) return;
    _endFastLocal();
  }

  void _onHourglassTap() {
    setState(() => _finishReady = true);
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
    if (!mounted || picked == null || picked == current) return;
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

  Future<void> _pickStart(FastingSessionState session) async {
    if (session.isFasting) return;
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
    if (_cubit.state.errorMessage != null) {
      AppSnackbar.show(
        context: context,
        text: _cubit.state.errorMessage!,
        type: SnackBarType.failure,
      );
    }
    setState(() {
      _mealSelected = false;
      _finishReady = false;
    });
    _publishFastingWidget(_cubit.state);
  }

  Future<void> _startFastNow() async {
    await _cubit.startFast();
    if (!mounted) return;
    if (_cubit.state.errorMessage != null) {
      AppSnackbar.show(
        context: context,
        text: _cubit.state.errorMessage!,
        type: SnackBarType.failure,
      );
      return;
    }
    setState(() {
      _mealSelected = false;
      _finishReady = false;
    });
    _publishFastingWidget(_cubit.state);
  }

  void _publishFastingWidget(FastingSessionState session) {
    final planTitle = _planTitle(session);
    final total = Duration(
      minutes:
          session.plan?.fastMinutes ??
          session.fast?.targetMinutes ??
          _planHours(planTitle) * 60,
    );
    final fasting = session.isFasting;
    final start = session.fast?.startedAt;
    final end = session.fast?.plannedEndAt ?? start?.add(total);
    FastingWidgetSync.rememberLabels(
      fasting: 'fasting_page.widget_fasting'.tr(context: context),
      eating: 'fasting_page.widget_eating'.tr(context: context),
      left: 'fasting_page.widget_left'.tr(context: context),
      headlineFasting: 'fasting_page.widget_you_fasting'.tr(context: context),
      headlineEating: 'fasting_page.widget_you_eating'.tr(context: context),
      startCaption: 'fasting_page.widget_start'.tr(context: context),
      endCaption: 'fasting_page.widget_end'.tr(context: context),
      goalCaption: 'fasting_page.widget_goal'.tr(context: context),
      hoursTemplate: 'fasting_page.widget_hours'.tr(context: context),
      praise: 'fasting_page.widget_great'.tr(context: context),
      localeName: context.locale.languageCode,
      todaysPlanTitle: 'fasting_page.widget_todays_plan'.tr(context: context),
      startFastingCta: 'fasting_page.widget_start_fasting'.tr(context: context),
      todayLabel: 'fasting_page.widget_today'.tr(context: context),
      cheerLabel: 'fasting_page.widget_lets_do_this'.tr(context: context),
      thisWeekTitle: 'fasting_page.widget_this_week'.tr(context: context),
      weekCheer: 'fasting_page.widget_keep_going'.tr(context: context),
      weekdays: 'water_page.weekdays'.tr(context: context),
    );
    unawaited(
      FastingWidgetSync.publish(
        isFasting: fasting,
        start: start,
        end: end,
        statusLabel: fasting
            ? 'fasting_page.widget_fasting'.tr(context: context)
            : 'fasting_page.widget_eating'.tr(context: context),
        leftLabel: 'fasting_page.widget_left'.tr(context: context),
        statusFasting: 'fasting_page.widget_fasting'.tr(context: context),
        statusEating: 'fasting_page.widget_eating'.tr(context: context),
        headlineFasting: 'fasting_page.widget_you_fasting'.tr(context: context),
        headlineEating: 'fasting_page.widget_you_eating'.tr(context: context),
        planLabel: planTitle.replaceAll('-', ':'),
      ),
    );
  }

  int _planHours(String title) {
    final head = title.split('-').first.trim();
    return int.tryParse(head) ?? 16;
  }

  int _eatHours(String title) {
    final parts = title.split('-');
    if (parts.length < 2) return 8;
    return int.tryParse(parts[1].trim()) ?? 8;
  }

  String _mochiStartedClock(FastingSessionState session) {
    final start =
        session.fast?.startedAt ?? session.eatingWindow?.suggestedNextStartAt;
    if (start != null) {
      return DateFormat('HH:mm', context.locale.toString()).format(start);
    }
    // Oruç, yeme penceresi bitince başlar.
    return session.plan?.eatWindow?.end ?? '–';
  }

  String _mochiEndsClock(FastingSessionState session) {
    final planTitle = _planTitle(session);
    final start = session.fast?.startedAt;
    final fastH = session.plan?.fastHours ?? _planHours(planTitle);
    if (start != null) {
      return DateFormat(
        'HH:mm',
        context.locale.toString(),
      ).format(start.add(Duration(hours: fastH)));
    }
    // Oruç, ertesi yeme penceresi başlayınca biter.
    return session.plan?.eatWindow?.start ?? '–';
  }

  String? _startedLabel(FastingSessionState session) {
    final start = session.fast?.startedAt ?? session.eatingWindow?.startedAt;
    return start == null ? null : _boundLabel(start);
  }

  String? _endsLabel(FastingSessionState session) {
    final end = session.fast?.plannedEndAt ?? session.eatingWindow?.endsAt;
    return end == null ? null : _boundLabel(end);
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
    return BlocConsumer<FastingSessionCubit, FastingSessionState>(
      bloc: _cubit,
      listenWhen: (prev, next) =>
          prev.errorMessage != next.errorMessage && next.errorMessage != null,
      listener: (context, state) {
        final msg = state.errorMessage;
        if (msg != null) {
          AppSnackbar.show(
            context: context,
            text: msg,
            type: SnackBarType.failure,
          );
        }
        if (state.isFasting && _mealSelected) {
          setState(() => _mealSelected = false);
        }
        _publishFastingWidget(state);
      },
      builder: (context, session) {
        final planTitle = _planTitle(session);
        final metrics = session.liveMetrics;
        final progress = metrics?.progress ?? 0.0;
        final elapsedText = metrics == null
            ? '00:00:00'
            : formatElapsedHms(metrics.elapsed);
        final percentInt = (progress * 100).round();
        return Scaffold(
          backgroundColor: ColorName.colorProfileBack,
          body: ListView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: AppBottomNav.barClearance),
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
                onBodyTap: () {
                  setState(() {
                    _mealSelected = false;
                    _finishReady = false;
                  });
                  _publishFastingWidget(session);
                },
                onMealTap: () {
                  setState(() {
                    _mealSelected = true;
                    _finishReady = false;
                  });
                  _publishFastingWidget(session);
                },
                onShare: _shareStatus,
              ),
              const SizedBox(height: 20),
              AnimatedSize(
                duration: const Duration(milliseconds: 480),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 480),
                  layoutBuilder: (current, previous) {
                    return ClipRect(
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [...previous, if (current != null) current],
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
                  child: _mealSelected
                      ? _MealStage(
                          key: const ValueKey('meal'),
                          planTitle: planTitle,
                          started: _startedLabel(session),
                          ends: _endsLabel(session),
                          finishReady: _finishReady,
                          progress: progress,
                          elapsedText: elapsedText,
                          percentInt: percentInt,
                          onEditPlan: () => _pickPlan(session),
                          onStart: _finishReady
                              ? () => unawaited(_startFastNow())
                              : () => unawaited(_pickStart(session)),
                          onHourglassTap: _onHourglassTap,
                        )
                      : _BodyStage(
                          key: const ValueKey('body'),
                          planTitle: planTitle,
                          started: _startedLabel(session),
                          ends: _endsLabel(session),
                          progress: progress,
                          elapsedText: elapsedText,
                          percentInt: percentInt,
                          stageTitle: session.fast?.stage?.title,
                          onEditPlan: () => _pickPlan(session),
                          onFinish: () => unawaited(_confirmEndFast(session)),
                        ),
                ),
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
                fastHours: session.plan?.fastHours ?? _planHours(planTitle),
                eatHours: session.plan?.eatHours ?? _eatHours(planTitle),
                startedLabel: _mochiStartedClock(session),
                endsLabel: _mochiEndsClock(session),
                onStart: () => unawaited(_pickStart(session)),
              ),
              const SizedBox(height: 60),
            ],
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
                onTap: () => onShare(anchor).withLoading(anchor),
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

final class _MealStage extends StatelessWidget {
  const _MealStage({
    required this.planTitle,
    required this.started,
    required this.ends,
    required this.finishReady,
    required this.progress,
    required this.elapsedText,
    required this.percentInt,
    required this.onEditPlan,
    required this.onStart,
    required this.onHourglassTap,
    super.key,
  });

  final String planTitle;
  final String? started;
  final String? ends;
  final bool finishReady;
  final double progress;
  final String elapsedText;
  final int percentInt;
  final VoidCallback onEditPlan;
  final VoidCallback onStart;
  final VoidCallback onHourglassTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'fasting_page.meal_time'.tr(),
          textAlign: TextAlign.center,
          style: AppTextStyles.fastingMealTitle,
        ),
        const SizedBox(height: 12),
        _StageCard(
          image: AppImages.breakYourFast,
          titleKey: 'fasting_page.break_title',
          bodyKey: 'fasting_page.break_body',
          onTap: () => context.pushNamed(RoutePaths.eatingWindow.name),
        ),
        const SizedBox(height: 8),
        _FastingArc(
          planTitle: planTitle,
          onEditPlan: onEditPlan,
          onHourglassTap: onHourglassTap,
          progress: progress,
          elapsedText: elapsedText,
          percentInt: percentInt,
        ),
        const SizedBox(height: 16),
        _FastingActions(
          planTitle: planTitle,
          started: started,
          ends: ends,
          onStart: onStart,
          finishReady: finishReady,
        ),
      ],
    );
  }
}

final class _BodyStage extends StatelessWidget {
  const _BodyStage({
    required this.planTitle,
    required this.started,
    required this.ends,
    required this.progress,
    required this.elapsedText,
    required this.percentInt,
    required this.onEditPlan,
    required this.onFinish,
    this.stageTitle,
    super.key,
  });

  final String planTitle;
  final String? started;
  final String? ends;
  final double progress;
  final String elapsedText;
  final int percentInt;
  final String? stageTitle;
  final VoidCallback onEditPlan;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StageCard(
          image: AppImages.a1Light,
          titleKey: 'fasting_page.body_title',
          bodyKey: 'fasting_page.body_body',
          titleOverride: stageTitle,
          onTap: () => context.pushNamed(RoutePaths.bodyStatus.name),
        ),
        const SizedBox(height: 8),
        _FastingArc(
          planTitle: planTitle,
          onEditPlan: onEditPlan,
          bodyMode: true,
          progress: progress,
          elapsedText: elapsedText,
          percentInt: percentInt,
        ),
        const SizedBox(height: 16),
        _FastingActions(
          planTitle: planTitle,
          started: started,
          ends: ends,
          onStart: onFinish,
          fasting: true,
        ),
      ],
    );
  }
}

final class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.image,
    required this.titleKey,
    required this.bodyKey,
    this.titleOverride,
    this.onTap,
  });

  final AppImageAsset image;
  final String titleKey;
  final String bodyKey;
  final String? titleOverride;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
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
                image.image(width: 48, height: 48, fit: BoxFit.contain),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleOverride ?? titleKey.tr(),
                        style: AppTextStyles.fastingBreakTitle,
                      ),
                      Text(
                        bodyKey.tr(),
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
    required this.progress,
    required this.elapsedText,
    required this.percentInt,
    this.bodyMode = false,
    this.onHourglassTap,
  });

  final String planTitle;
  final VoidCallback onEditPlan;
  final double progress;
  final String elapsedText;
  final int percentInt;
  final bool bodyMode;
  final VoidCallback? onHourglassTap;

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
            final breakFast = _pointOnArc(arcSize, progress);
            final nourish = _pointOnArc(arcSize, 0.5);
            final nextFast = _pointOnArc(arcSize, 1);
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
                          progressColor: bodyMode
                              ? ColorName.colorMealPositive
                              : ColorName.colorPlanFasting,
                          trackColor: ColorName.colorUnitToggleBg,
                        ),
                        child!,
                        if (bodyMode) ...[
                          _ArcMarker(
                            center: breakFast,
                            image: AppImages.a1Light,
                          ),
                          _ArcMarker(
                            center: _pointOnArc(arcSize, 0.44),
                            image: AppImages.a3,
                            dimmed: true,
                          ),
                          _ArcMarker(
                            center: _pointOnArc(arcSize, 0.66),
                            image: AppImages.a4,
                            dimmed: true,
                          ),
                          _ArcMarker(
                            center: _pointOnArc(arcSize, 0.92),
                            image: AppImages.a6,
                            dimmed: true,
                          ),
                        ] else ...[
                          _ArcMarker(
                            center: breakFast,
                            image: AppImages.breakYourFast,
                          ),
                          _ArcMarker(
                            center: nourish,
                            image: AppImages.darkNorusih,
                            scale: 1.35,
                          ),
                          _ArcMarker(
                            center: nextFast,
                            image: AppImages.darkFast,
                            scale: 1.25,
                            onTap: onHourglassTap,
                          ),
                        ],
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
        percentInt: percentInt,
      ),
    );
  }
}

Offset _pointOnArc(Size size, double t) {
  final radius = (math.min(size.width, size.height) - HorseshoeArc.stroke) / 2;
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
    required this.percentInt,
  });

  final String planTitle;
  final VoidCallback onEditPlan;
  final String elapsedText;
  final int percentInt;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'fasting_page.time_passed'.tr(args: ['$percentInt']),
          style: AppTextStyles.fastingTimePassed,
        ),
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

final class _ArcMarker extends StatelessWidget {
  const _ArcMarker({
    required this.center,
    required this.image,
    this.scale = 1,
    this.dimmed = false,
    this.onTap,
  });

  final Offset center;
  final AppImageAsset image;
  final double scale;
  final bool dimmed;
  final VoidCallback? onTap;

  static const _gray = ColorFilter.matrix(<double>[
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

  @override
  Widget build(BuildContext context) {
    const size = _FastingArc._marker;
    return Positioned(
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
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
                child: Transform.scale(
                  scale: scale,
                  child: dimmed
                      ? ColorFiltered(
                          colorFilter: _gray,
                          child: image.image(fit: BoxFit.contain),
                        )
                      : image.image(fit: BoxFit.contain),
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
    required this.onStart,
    this.fasting = false,
    this.finishReady = false,
  });

  final String planTitle;
  final String? started;
  final String? ends;
  final VoidCallback onStart;
  final bool fasting;
  final bool finishReady;

  @override
  Widget build(BuildContext context) {
    final label = finishReady
        ? 'fasting_page.start_now_cta'.tr()
        : fasting
        ? 'fasting_page.finish_early'.tr()
        : 'fasting_page.start_cta'.tr(args: [planTitle]);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _TimeRow(started: started, ends: ends),
          const SizedBox(height: 20),
          AppButton(
            label: label,
            onPressed: onStart,
            showIcon: false,
            decoration: finishReady
                ? AppButtonDecoration.fastingStart()
                : fasting
                ? AppButtonDecoration.dark()
                : AppButtonDecoration.fastingStart(),
          ),
          if (fasting) ...[
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
  const _TimeRow({required this.started, required this.ends});

  final String? started;
  final String? ends;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'fasting_page.started_label'.tr(),
              style: AppTextStyles.fastingBoundLabel,
            ),
            Text(started ?? '–', style: AppTextStyles.fastingBoundValue),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'fasting_page.ends_label'.tr(),
              style: AppTextStyles.fastingBoundLabel,
            ),
            Text(ends ?? '–', style: AppTextStyles.fastingBoundValue),
          ],
        ),
      ],
    );
  }
}
