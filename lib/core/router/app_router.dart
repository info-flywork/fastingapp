import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/router/go_router_refresh_stream.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/widgets/bottom_navigation_bar/main_wrapper.dart';
import 'package:fastingapp/data/model/onboarding/onboarding_result.dart';
import 'package:fastingapp/domain/gamification/challenges_repository.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_bloc.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_state.dart';
import 'package:fastingapp/presentation/auth/entry/view/entry_view.dart';
import 'package:fastingapp/presentation/auth/login/view/login_view.dart';
import 'package:fastingapp/presentation/auth/onboard/about_you/bloc/about_you_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/about_you/view/about_you_view.dart';
import 'package:fastingapp/presentation/auth/onboard/building_plan/view/building_plan_view.dart';
import 'package:fastingapp/presentation/auth/onboard/diet/bloc/diet_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/diet/view/diet_view.dart';
import 'package:fastingapp/presentation/auth/onboard/doable_highlight/view/doable_highlight_view.dart';
import 'package:fastingapp/presentation/auth/onboard/fasting_plan/bloc/fasting_plan_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/fasting_plan/view/fasting_plan_view.dart';
import 'package:fastingapp/presentation/auth/onboard/fasting_reason/bloc/fasting_reason_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/fasting_reason/view/fasting_reason_view.dart';
import 'package:fastingapp/presentation/auth/onboard/food_loves/bloc/food_loves_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/food_loves/view/food_loves_view.dart';
import 'package:fastingapp/presentation/auth/onboard/food_prefs_nav_args.dart';
import 'package:fastingapp/presentation/auth/onboard/food_skips/bloc/food_skips_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/food_skips/view/food_skips_view.dart';
import 'package:fastingapp/presentation/auth/onboard/goal/bloc/goal_bloc.dart';
import 'package:fastingapp/domain/onboarding/onboarding_draft.dart';
import 'package:fastingapp/presentation/auth/onboard/goal/view/goal_view.dart';
import 'package:fastingapp/presentation/auth/onboard/goal_highlight/view/goal_highlight_view.dart';
import 'package:fastingapp/presentation/auth/onboard/good_company/view/good_company_view.dart';
import 'package:fastingapp/presentation/auth/onboard/meal_window/bloc/meal_window_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/meal_window/view/meal_window_view.dart';
import 'package:fastingapp/presentation/auth/onboard/noted_highlight/view/noted_highlight_view.dart';
import 'package:fastingapp/presentation/auth/onboard/obstacle_highlight/view/obstacle_highlight_view.dart';
import 'package:fastingapp/presentation/auth/onboard/obstacles/bloc/obstacles_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/obstacles/view/obstacles_view.dart';
import 'package:fastingapp/presentation/auth/onboard/plan_highlight/view/plan_highlight_view.dart';
import 'package:fastingapp/presentation/auth/onboard/privacy_highlight/view/privacy_highlight_view.dart';
import 'package:fastingapp/presentation/auth/onboard/reason_highlight/view/reason_highlight_view.dart';
import 'package:fastingapp/presentation/auth/onboard/starting_point/bloc/starting_point_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/starting_point/starting_point_nav_args.dart';
import 'package:fastingapp/presentation/auth/onboard/starting_point/view/starting_point_view.dart';
import 'package:fastingapp/presentation/auth/onboard/weight_history/bloc/weight_history_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/weight_history/view/weight_history_view.dart';
import 'package:fastingapp/presentation/auth/onboard/weight_projection/view/weight_projection_view.dart';
import 'package:fastingapp/presentation/auth/splash/bloc/splash_bloc.dart';
import 'package:fastingapp/presentation/auth/splash/bloc/splash_event.dart';
import 'package:fastingapp/presentation/auth/splash/view/splash_view.dart';
import 'package:fastingapp/presentation/auth/welcome/bloc/welcome_bloc.dart';
import 'package:fastingapp/presentation/body_history/view/body_history_view.dart';
import 'package:fastingapp/presentation/calories_tracker/view/calories_camera_view.dart';
import 'package:fastingapp/presentation/calories_tracker/view/calories_result_view.dart';
import 'package:fastingapp/presentation/calories_tracker/view/calories_tracker_view.dart';
import 'package:fastingapp/presentation/challenges/view/challenge_detail_view.dart';
import 'package:fastingapp/presentation/chat/latest/view/latest_chats_view.dart';
import 'package:fastingapp/presentation/chat/view/chat_view.dart';
import 'package:fastingapp/presentation/fasting/view/eating_window_view.dart';
import 'package:fastingapp/presentation/fasting/view/fasting_body_status_view.dart';
import 'package:fastingapp/presentation/fasting/view/fasting_breath_view.dart';
import 'package:fastingapp/presentation/fasting/view/fasting_finish_view.dart';
import 'package:fastingapp/presentation/fasting/view/fasting_first_time_view.dart';
import 'package:fastingapp/presentation/fasting/view/fasting_history_view.dart';
import 'package:fastingapp/presentation/fasting/view/fasting_quick_walk_view.dart';
import 'package:fastingapp/presentation/fasting/view/fasting_sip_challenge_view.dart';
import 'package:fastingapp/presentation/fasting/view/fasting_struggle_advice_view.dart';
import 'package:fastingapp/presentation/fasting/view/fasting_struggle_view.dart';
import 'package:fastingapp/presentation/fasting/view/fasting_view.dart';
import 'package:fastingapp/presentation/home/bloc/home_bloc.dart';
import 'package:fastingapp/presentation/home/bloc/home_event.dart';
import 'package:fastingapp/presentation/home/bloc/home_state.dart';
import 'package:fastingapp/presentation/home/view/home_view.dart';
import 'package:fastingapp/presentation/hunger_tracker/hunger_result_type.dart';
import 'package:fastingapp/presentation/hunger_tracker/hunger_session_args.dart';
import 'package:fastingapp/presentation/hunger_tracker/hunger_symptom.dart';
import 'package:fastingapp/presentation/hunger_tracker/view/hunger_check_view.dart';
import 'package:fastingapp/presentation/hunger_tracker/view/hunger_first_question_view.dart';
import 'package:fastingapp/presentation/hunger_tracker/view/hunger_fourth_question_view.dart';
import 'package:fastingapp/presentation/hunger_tracker/view/hunger_history_log_view.dart';
import 'package:fastingapp/presentation/hunger_tracker/view/hunger_log_view.dart';
import 'package:fastingapp/presentation/hunger_tracker/view/hunger_result_view.dart';
import 'package:fastingapp/presentation/hunger_tracker/view/hunger_second_question_view.dart';
import 'package:fastingapp/presentation/hunger_tracker/view/hunger_success_view.dart';
import 'package:fastingapp/presentation/hunger_tracker/view/hunger_third_question_view.dart';
import 'package:fastingapp/presentation/hunger_tracker/view/hunger_tracker_view.dart';
import 'package:fastingapp/presentation/insights/insight_topic.dart';
import 'package:fastingapp/presentation/insights/view/insight_detail_view.dart';
import 'package:fastingapp/presentation/insights/view/insights_view.dart';
import 'package:fastingapp/presentation/meal_records/meal_detail_args.dart';
import 'package:fastingapp/presentation/meal_records/view/meal_detail_view.dart';
import 'package:fastingapp/presentation/meal_records/view/meal_records_view.dart';
import 'package:fastingapp/presentation/mochi_world/view/mochi_world_view.dart';
import 'package:fastingapp/presentation/plans/plan_detail_args.dart';
import 'package:fastingapp/presentation/plans/plans_catalog.dart';
import 'package:fastingapp/presentation/plans/view/plan_detail_view.dart';
import 'package:fastingapp/presentation/plans/view/weekly_plan_detail_view.dart';
import 'package:fastingapp/presentation/plans/view/plans_view.dart';
import 'package:fastingapp/presentation/profile/bloc/profile_bloc.dart';
import 'package:fastingapp/presentation/profile/notification_settings/notification_settings_view.dart';
import 'package:fastingapp/presentation/profile/edit_profile/view/edit_diet_type_view.dart';
import 'package:fastingapp/presentation/profile/edit_profile/view/edit_fasting_plan_view.dart';
import 'package:fastingapp/presentation/profile/edit_profile/view/edit_fasting_target_view.dart';
import 'package:fastingapp/presentation/profile/edit_profile/view/edit_gender_view.dart';
import 'package:fastingapp/presentation/profile/edit_profile/view/edit_height_view.dart';
import 'package:fastingapp/presentation/profile/edit_profile/view/edit_preferred_foods_view.dart';
import 'package:fastingapp/presentation/profile/edit_profile/view/edit_profile_view.dart';
import 'package:fastingapp/presentation/profile/edit_profile/view/edit_skipped_foods_view.dart';
import 'package:fastingapp/presentation/profile/faq/view/faq_view.dart';
import 'package:fastingapp/presentation/profile/languages/view/languages_view.dart';
import 'package:fastingapp/presentation/profile/notifications/view/notifications_view.dart';
import 'package:fastingapp/presentation/profile/view/profile_view.dart';
import 'package:fastingapp/presentation/protein_tracker/view/protein_tracker_view.dart';
import 'package:fastingapp/presentation/sleep/view/sleep_view.dart';
import 'package:fastingapp/presentation/steps/view/steps_view.dart';
import 'package:fastingapp/presentation/water/reminder/view/water_reminder_view.dart';
import 'package:fastingapp/presentation/water/reminder/water_reminder_result.dart';
import 'package:fastingapp/presentation/water/view/water_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Root navigator anahtarı (dialog/overlay için köke erişim).
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Oturumsuz açılabilen rotalar: açılış, giriş ve onboarding akışı.
/// Diğer her şey (home, sekmeler, takipçiler, profil) oturum ister.
final _publicPaths = <String>{
  for (final route in [
    RoutePaths.splash,
    RoutePaths.entry,
    RoutePaths.login,
    RoutePaths.onboarding,
    RoutePaths.goalHighlight,
    RoutePaths.aboutYou,
    RoutePaths.privacyHighlight,
    RoutePaths.startingPoint,
    RoutePaths.doableHighlight,
    RoutePaths.diet,
    RoutePaths.foodLoves,
    RoutePaths.foodSkips,
    RoutePaths.notedHighlight,
    RoutePaths.weightHistory,
    RoutePaths.obstacles,
    RoutePaths.obstacleHighlight,
    RoutePaths.fastingReason,
    RoutePaths.reasonHighlight,
    RoutePaths.fastingPlan,
    RoutePaths.planHighlight,
    RoutePaths.mealWindow,
    RoutePaths.buildingPlan,
    RoutePaths.weightProjection,
    RoutePaths.goodCompany,
  ])
    route.path,
};

bool _isProtectedRoute(String location) => !_publicPaths.contains(location);

/// GoRouter yapılandırması. Auth guard [AuthBloc] state'ine göre çalışır.
/// (Doküman 11)
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: RoutePaths.splash.path,
  refreshListenable: GoRouterRefreshStream(getIt<AuthBloc>().stream),
  redirect: (context, state) {
    final authState = context.read<AuthBloc>().state;
    final location = state.matchedLocation;
    final isOnSplash = location == RoutePaths.splash.path;

    // Oturum henüz bilinmiyorsa yalnızca korumalı rotaları splash'te tut.
    // Aksi halde splash → onboarding/welcome yönlendirmesi AuthInitial'a
    // çarpıp geri splash'e düşer ve uygulama takılır.
    if (authState is AuthInitial &&
        _isProtectedRoute(location) &&
        !isOnSplash) {
      return RoutePaths.splash.path;
    }
    if (authState is AuthUnauthenticated && _isProtectedRoute(location)) {
      return RoutePaths.login.path;
    }
    // Onboarding'i bitmemiş oturum (misafir) korumalı ekrana giremez.
    if (authState is AuthAuthenticated &&
        !authState.user.isAnsweredQuestions &&
        _isProtectedRoute(location)) {
      return RoutePaths.onboarding.path;
    }
    return null;
  },
  routes: [
    GoRoute(
      path: RoutePaths.splash.path,
      name: RoutePaths.splash.name,
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<SplashBloc>()..add(const SplashStarted()),
        child: const SplashView(),
      ),
    ),
    GoRoute(
      path: RoutePaths.entry.path,
      name: RoutePaths.entry.name,
      builder: (context, state) => const EntryView(),
    ),
    GoRoute(
      path: RoutePaths.login.path,
      name: RoutePaths.login.name,
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<WelcomeBloc>(),
        child: LoginView(
          afterOnboarding: state.uri.queryParameters['from'] == 'onboarding',
        ),
      ),
    ),
    // Onboarding ilk adım: hedef seçimi.
    GoRoute(
      path: RoutePaths.onboarding.path,
      name: RoutePaths.onboarding.name,
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<GoalBloc>(),
        child: const GoalView(),
      ),
    ),
    GoRoute(
      path: RoutePaths.goalHighlight.path,
      name: RoutePaths.goalHighlight.name,
      builder: (context, state) => const GoalHighlightView(),
    ),
    GoRoute(
      path: RoutePaths.aboutYou.path,
      name: RoutePaths.aboutYou.name,
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<AboutYouBloc>(),
        child: const AboutYouView(),
      ),
    ),
    GoRoute(
      path: RoutePaths.privacyHighlight.path,
      name: RoutePaths.privacyHighlight.name,
      builder: (context, state) => const PrivacyHighlightView(),
    ),
    GoRoute(
      path: RoutePaths.startingPoint.path,
      name: RoutePaths.startingPoint.name,
      builder: (context, state) => BlocProvider(
        create: (_) => StartingPointBloc(
          allowGoalAboveCurrent:
              getIt<OnboardingDraft>().goal != OnboardingGoal.loseWeight,
        ),
        child: const StartingPointView(),
      ),
    ),
    GoRoute(
      path: RoutePaths.doableHighlight.path,
      name: RoutePaths.doableHighlight.name,
      builder: (context, state) {
        final args = state.extra is StartingPointNavArgs
            ? state.extra! as StartingPointNavArgs
            : const StartingPointNavArgs(weightKg: 70, goalWeightKg: 65);
        return DoableHighlightView(args: args);
      },
    ),
    GoRoute(
      path: RoutePaths.diet.path,
      name: RoutePaths.diet.name,
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<DietBloc>(),
        child: const DietView(),
      ),
    ),
    GoRoute(
      path: RoutePaths.foodLoves.path,
      name: RoutePaths.foodLoves.name,
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<FoodLovesBloc>(),
        child: const FoodLovesView(),
      ),
    ),
    GoRoute(
      path: RoutePaths.foodSkips.path,
      name: RoutePaths.foodSkips.name,
      builder: (context, state) {
        final prefs = state.extra is FoodPrefsNavArgs
            ? state.extra! as FoodPrefsNavArgs
            : const FoodPrefsNavArgs();
        return BlocProvider(
          create: (_) => getIt<FoodSkipsBloc>(),
          child: FoodSkipsView(prefs: prefs),
        );
      },
    ),
    GoRoute(
      path: RoutePaths.notedHighlight.path,
      name: RoutePaths.notedHighlight.name,
      builder: (context, state) {
        final args = state.extra is FoodPrefsNavArgs
            ? state.extra! as FoodPrefsNavArgs
            : const FoodPrefsNavArgs();
        return NotedHighlightView(args: args);
      },
    ),
    GoRoute(
      path: RoutePaths.weightHistory.path,
      name: RoutePaths.weightHistory.name,
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<WeightHistoryBloc>(),
        child: const WeightHistoryView(),
      ),
    ),
    GoRoute(
      path: RoutePaths.obstacles.path,
      name: RoutePaths.obstacles.name,
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<ObstaclesBloc>(),
        child: const ObstaclesView(),
      ),
    ),
    GoRoute(
      path: RoutePaths.obstacleHighlight.path,
      name: RoutePaths.obstacleHighlight.name,
      builder: (context, state) => const ObstacleHighlightView(),
    ),
    GoRoute(
      path: RoutePaths.fastingReason.path,
      name: RoutePaths.fastingReason.name,
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<FastingReasonBloc>(),
        child: const FastingReasonView(),
      ),
    ),
    GoRoute(
      path: RoutePaths.reasonHighlight.path,
      name: RoutePaths.reasonHighlight.name,
      builder: (context, state) {
        final reason = state.extra is OnboardingFastingReason
            ? state.extra! as OnboardingFastingReason
            : OnboardingFastingReason.specialDate;
        return ReasonHighlightView(reason: reason);
      },
    ),
    GoRoute(
      path: RoutePaths.fastingPlan.path,
      name: RoutePaths.fastingPlan.name,
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<FastingPlanBloc>(),
        child: const FastingPlanView(),
      ),
    ),
    GoRoute(
      path: RoutePaths.planHighlight.path,
      name: RoutePaths.planHighlight.name,
      builder: (context, state) {
        final plan = state.extra is OnboardingFastingPlan
            ? state.extra! as OnboardingFastingPlan
            : OnboardingFastingPlan.sixteenEight;
        return PlanHighlightView(plan: plan);
      },
    ),
    GoRoute(
      path: RoutePaths.mealWindow.path,
      name: RoutePaths.mealWindow.name,
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<MealWindowBloc>(),
        child: const MealWindowView(),
      ),
    ),
    GoRoute(
      path: RoutePaths.buildingPlan.path,
      name: RoutePaths.buildingPlan.name,
      builder: (context, state) => const BuildingPlanView(),
    ),
    GoRoute(
      path: RoutePaths.weightProjection.path,
      name: RoutePaths.weightProjection.name,
      builder: (context, state) {
        // Sunucu projeksiyonu (BuildingPlan gönderiminden); yoksa varsayılanlar.
        final p = state.extra is WeightProjection
            ? state.extra! as WeightProjection
            : const WeightProjection();
        return WeightProjectionView(
          currentWeightKg: p.currentWeightKg ?? 74,
          goalWeightKg: p.goalWeightKg ?? 68,
          weeklyLossKg: p.weeklyLossKg ?? 0.4,
          targetDate: p.targetDate,
        );
      },
    ),
    GoRoute(
      path: RoutePaths.goodCompany.path,
      name: RoutePaths.goodCompany.name,
      builder: (context, state) => const GoodCompanyView(),
    ),
    GoRoute(
      path: RoutePaths.water.path,
      name: RoutePaths.water.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra;
        int? initialMl;
        int? dailyGoalMl;
        if (extra is Map) {
          initialMl = extra['initialMl'] as int?;
          dailyGoalMl = extra['dailyGoalMl'] as int?;
        }
        final home = getIt<HomeBloc>().state;
        if (home is HomeLoaded) {
          initialMl ??= home.summary?.waterMl;
          dailyGoalMl ??= home.summary?.waterGoalMl;
        }
        return WaterView(
          initialMl: initialMl ?? 0,
          dailyGoalMl: dailyGoalMl ?? 2500,
        );
      },
      routes: [
        GoRoute(
          path: RoutePaths.waterReminder.path,
          name: RoutePaths.waterReminder.name,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final args = state.extra is WaterReminderArgs
                ? state.extra! as WaterReminderArgs
                : null;
            return WaterReminderView(args: args);
          },
        ),
      ],
    ),
    GoRoute(
      path: RoutePaths.steps.path,
      name: RoutePaths.steps.name,
      parentNavigatorKey: rootNavigatorKey,
      // Ana sayfa özetinden tohumla: ekran 0/8000 ile açılıp zıplamasın.
      builder: (context, state) {
        final home = getIt<HomeBloc>().state;
        final summary = home is HomeLoaded ? home.summary : null;
        return StepsView(
          initialSteps: summary?.steps ?? 0,
          dailyGoalSteps: summary?.stepsGoal ?? 8000,
        );
      },
    ),
    GoRoute(
      path: RoutePaths.bodyHistory.path,
      name: RoutePaths.bodyHistory.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const BodyHistoryView(),
    ),
    GoRoute(
      path: RoutePaths.caloriesTracker.path,
      name: RoutePaths.caloriesTracker.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const CaloriesTrackerView(),
    ),
    GoRoute(
      path: RoutePaths.caloriesCamera.path,
      name: RoutePaths.caloriesCamera.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const CaloriesCameraView(),
    ),
    GoRoute(
      path: RoutePaths.caloriesResult.path,
      name: RoutePaths.caloriesResult.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final photoPath = state.extra is String ? state.extra! as String : '';
        return CaloriesResultView(photoPath: photoPath);
      },
    ),
    GoRoute(
      path: RoutePaths.proteinTracker.path,
      name: RoutePaths.proteinTracker.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const ProteinTrackerView(),
    ),
    GoRoute(
      path: RoutePaths.sleep.path,
      name: RoutePaths.sleep.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const SleepView(),
    ),
    GoRoute(
      path: RoutePaths.eatingWindow.path,
      name: RoutePaths.eatingWindow.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const EatingWindowView(),
    ),
    GoRoute(
      path: RoutePaths.bodyStatus.path,
      name: RoutePaths.bodyStatus.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const FastingBodyStatusView(),
    ),
    GoRoute(
      path: RoutePaths.fastingStruggle.path,
      name: RoutePaths.fastingStruggle.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const FastingStruggleView(),
    ),
    GoRoute(
      path: RoutePaths.fastingStruggleAdvice.path,
      name: RoutePaths.fastingStruggleAdvice.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra;
        final args = extra is FastingStruggleAdviceArgs
            ? extra
            : FastingStruggleAdviceArgs(
                bodyText: 'fasting_struggle.hungry_body'.tr(),
                reason: FastingStruggleReason.hungry,
              );
        return FastingStruggleAdviceView(args: args);
      },
    ),
    GoRoute(
      path: RoutePaths.fastingSipChallenge.path,
      name: RoutePaths.fastingSipChallenge.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final body = state.extra as String?;
        return FastingSipChallengeView(
          bodyText: body ?? 'fasting_struggle.hungry_body'.tr(),
        );
      },
    ),
    GoRoute(
      path: RoutePaths.fastingQuickWalk.path,
      name: RoutePaths.fastingQuickWalk.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final body = state.extra as String?;
        return FastingQuickWalkView(
          bodyText: body ?? 'fasting_struggle.energy_body'.tr(),
        );
      },
    ),
    GoRoute(
      path: RoutePaths.fastingBreath.path,
      name: RoutePaths.fastingBreath.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final body = state.extra as String?;
        return FastingBreathView(
          bodyText: body ?? 'fasting_struggle.craving_body'.tr(),
        );
      },
    ),
    GoRoute(
      path: RoutePaths.fastingFinish.path,
      name: RoutePaths.fastingFinish.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra;
        final args = extra is FastingFinishArgs
            ? extra
            : FastingFinishArgs(
                fastId: '',
                planTitle: '16-8',
                start: DateTime.now().subtract(
                  const Duration(hours: 12, minutes: 12, seconds: 39),
                ),
                end: DateTime.now(),
              );
        return FastingFinishView(args: args);
      },
    ),
    GoRoute(
      path: RoutePaths.fastingFirstTime.path,
      name: RoutePaths.fastingFirstTime.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra;
        final args = extra is FastingFirstTimeArgs
            ? extra
            : const FastingFirstTimeArgs(
                elapsed: Duration(hours: 12, minutes: 12, seconds: 39),
              );
        return FastingFirstTimeView(args: args);
      },
    ),
    GoRoute(
      path: RoutePaths.fastingHistory.path,
      name: RoutePaths.fastingHistory.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const FastingHistoryView(),
    ),
    GoRoute(
      path: RoutePaths.challengeDetail.path,
      name: RoutePaths.challengeDetail.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) =>
          ChallengeDetailView(initial: state.extra! as Challenge),
    ),
    GoRoute(
      path: RoutePaths.insights.path,
      name: RoutePaths.insights.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const InsightsView(),
    ),
    GoRoute(
      path: RoutePaths.insightDetail.path,
      name: RoutePaths.insightDetail.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final topic = InsightTopic.fromName(state.pathParameters['topic']);
        return InsightDetailView(topic: topic);
      },
    ),
    GoRoute(
      path: RoutePaths.mealRecords.path,
      name: RoutePaths.mealRecords.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const MealRecordsView(),
    ),
    GoRoute(
      path: RoutePaths.mealDetail.path,
      name: RoutePaths.mealDetail.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra;
        if (extra is MealDetailArgs) {
          return MealDetailView(
            mealId: extra.mealId,
            initialEatenAt: extra.initialEatenAt,
          );
        }
        return const MealDetailView();
      },
    ),
    GoRoute(
      path: RoutePaths.hungerTracker.path,
      name: RoutePaths.hungerTracker.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const HungerTrackerView(),
    ),
    GoRoute(
      path: RoutePaths.hungerCheck.path,
      name: RoutePaths.hungerCheck.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final args = state.extra is HungerFlowArgs
            ? state.extra! as HungerFlowArgs
            : const HungerFlowArgs();
        return HungerCheckView(args: args);
      },
    ),
    GoRoute(
      path: RoutePaths.hungerFirstQuestion.path,
      name: RoutePaths.hungerFirstQuestion.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final args = state.extra is HungerFlowArgs
            ? state.extra! as HungerFlowArgs
            : const HungerFlowArgs();
        return HungerFirstQuestionView(args: args);
      },
    ),
    GoRoute(
      path: RoutePaths.hungerSecondQuestion.path,
      name: RoutePaths.hungerSecondQuestion.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final args = state.extra is HungerFlowArgs
            ? state.extra! as HungerFlowArgs
            : const HungerFlowArgs();
        return HungerSecondQuestionView(args: args);
      },
    ),
    GoRoute(
      path: RoutePaths.hungerThirdQuestion.path,
      name: RoutePaths.hungerThirdQuestion.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final args = state.extra is HungerFlowArgs
            ? state.extra! as HungerFlowArgs
            : const HungerFlowArgs();
        return HungerThirdQuestionView(args: args);
      },
    ),
    GoRoute(
      path: RoutePaths.hungerFourthQuestion.path,
      name: RoutePaths.hungerFourthQuestion.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final args = state.extra is HungerFlowArgs
            ? state.extra! as HungerFlowArgs
            : const HungerFlowArgs();
        return HungerFourthQuestionView(args: args);
      },
    ),
    GoRoute(
      path: RoutePaths.hungerResult.path,
      name: RoutePaths.hungerResult.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra;
        if (extra is HungerSessionArgs) {
          return HungerResultView(type: extra.resultType, session: extra);
        }
        final type = extra is HungerResultType
            ? extra
            : HungerResultType.physical;
        return HungerResultView(type: type);
      },
    ),
    GoRoute(
      path: RoutePaths.hungerLog.path,
      name: RoutePaths.hungerLog.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra;
        if (extra is HungerSessionArgs) {
          return HungerLogView(type: extra.resultType, session: extra);
        }
        final type = extra is HungerResultType
            ? extra
            : HungerResultType.physical;
        return HungerLogView(type: type);
      },
    ),
    GoRoute(
      path: RoutePaths.hungerSuccess.path,
      name: RoutePaths.hungerSuccess.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const HungerSuccessView(),
    ),
    GoRoute(
      path: RoutePaths.hungerHistoryLog.path,
      name: RoutePaths.hungerHistoryLog.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const HungerHistoryLogView(),
    ),
    GoRoute(
      path: RoutePaths.planDetail.path,
      name: RoutePaths.planDetail.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final args = state.extra is PlanDetailArgs
            ? state.extra! as PlanDetailArgs
            : PlanDetailArgs(plan: PlansCatalog.beginnerRow1.first);
        return PlanDetailView(args: args);
      },
    ),
    GoRoute(
      path: RoutePaths.weeklyPlanDetail.path,
      name: RoutePaths.weeklyPlanDetail.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final args = state.extra is WeeklyPlanDetailArgs
            ? state.extra! as WeeklyPlanDetailArgs
            : WeeklyPlanDetailArgs(plan: PlansCatalog.weeklyRow.first);
        return WeeklyPlanDetailView(args: args);
      },
    ),
    GoRoute(
      path: RoutePaths.chat.path,
      name: RoutePaths.chat.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const ChatView(),
      routes: [
        GoRoute(
          path: RoutePaths.latestChats.path,
          name: RoutePaths.latestChats.name,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const LatestChatsView(),
        ),
      ],
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainWrapper(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.home.path,
              name: RoutePaths.home.name,
              builder: (context, state) {
                final home = getIt<HomeBloc>();
                // Splash ısıtmadıysa (veya timeout) burada başlat.
                if (home.state is HomeInitial || home.state is HomeError) {
                  home.add(const HomeStarted());
                }
                // Profil (yüklüyse dokunmaz): Profili Düzenle hazır açılır.
                getIt<ProfileBloc>().add(const ProfileStarted());
                return BlocProvider<HomeBloc>.value(
                  value: home,
                  child: const HomeView(),
                );
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.fasting.path,
              name: RoutePaths.fasting.name,
              builder: (context, state) => const FastingView(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.mochiWorld.path,
              name: RoutePaths.mochiWorld.name,
              builder: (context, state) => const MochiWorldView(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.plans.path,
              name: RoutePaths.plans.name,
              builder: (context, state) => const PlansView(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.profile.path,
              name: RoutePaths.profile.name,
              builder: (context, state) => const ProfileView(),
              routes: [
                GoRoute(
                  path: RoutePaths.notifications.path,
                  name: RoutePaths.notifications.name,
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => const NotificationsView(),
                ),
                GoRoute(
                  path: RoutePaths.languages.path,
                  name: RoutePaths.languages.name,
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => const LanguagesView(),
                ),
                GoRoute(
                  path: RoutePaths.faq.path,
                  name: RoutePaths.faq.name,
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => const FaqView(),
                ),
                GoRoute(
                  path: RoutePaths.notificationSettings.path,
                  name: RoutePaths.notificationSettings.name,
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => const NotificationSettingsView(),
                ),
                GoRoute(
                  path: RoutePaths.editProfile.path,
                  name: RoutePaths.editProfile.name,
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => const EditProfileView(),
                  routes: [
                    GoRoute(
                      path: RoutePaths.editFastingTarget.path,
                      name: RoutePaths.editFastingTarget.name,
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) {
                        final initial = state.extra is OnboardingGoal
                            ? state.extra! as OnboardingGoal
                            : null;
                        return EditFastingTargetView(initial: initial);
                      },
                    ),
                    GoRoute(
                      path: RoutePaths.editFastingPlan.path,
                      name: RoutePaths.editFastingPlan.name,
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) {
                        final initial = state.extra is OnboardingFastingPlan
                            ? state.extra! as OnboardingFastingPlan
                            : null;
                        return EditFastingPlanView(initial: initial);
                      },
                    ),
                    GoRoute(
                      path: RoutePaths.editGender.path,
                      name: RoutePaths.editGender.name,
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) {
                        final initial = state.extra is OnboardingGender
                            ? state.extra! as OnboardingGender
                            : null;
                        return EditGenderView(initial: initial);
                      },
                    ),
                    GoRoute(
                      path: RoutePaths.editHeight.path,
                      name: RoutePaths.editHeight.name,
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) {
                        final extra = state.extra;
                        if (extra is HeightEditResult) {
                          return EditHeightView(
                            initialHeightCm: extra.heightCm,
                            initialAge: extra.age,
                          );
                        }
                        return const EditHeightView();
                      },
                    ),
                    GoRoute(
                      path: RoutePaths.editDietType.path,
                      name: RoutePaths.editDietType.name,
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) {
                        final initial = state.extra is OnboardingDiet
                            ? state.extra! as OnboardingDiet
                            : null;
                        return EditDietTypeView(initial: initial);
                      },
                    ),
                    GoRoute(
                      path: RoutePaths.editPreferredFoods.path,
                      name: RoutePaths.editPreferredFoods.name,
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) {
                        final initial = state.extra is Set<OnboardingFoodLove>
                            ? state.extra! as Set<OnboardingFoodLove>
                            : state.extra is List
                            ? Set<OnboardingFoodLove>.from(state.extra! as List)
                            : <OnboardingFoodLove>{};
                        return EditPreferredFoodsView(initial: initial);
                      },
                    ),
                    GoRoute(
                      path: RoutePaths.editSkippedFoods.path,
                      name: RoutePaths.editSkippedFoods.name,
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (context, state) {
                        final initial = state.extra is Set<OnboardingFoodSkip>
                            ? state.extra! as Set<OnboardingFoodSkip>
                            : state.extra is List
                            ? Set<OnboardingFoodSkip>.from(state.extra! as List)
                            : <OnboardingFoodSkip>{};
                        return EditSkippedFoodsView(initial: initial);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
