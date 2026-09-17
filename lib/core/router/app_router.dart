import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/router/go_router_refresh_stream.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/widgets/bottom_navigation_bar/main_wrapper.dart';
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
import 'package:fastingapp/presentation/auth/onboard/goal/view/goal_view.dart';
import 'package:fastingapp/presentation/auth/onboard/goal_highlight/view/goal_highlight_view.dart';
import 'package:fastingapp/presentation/auth/onboard/good_company/view/good_company_view.dart';
import 'package:fastingapp/presentation/auth/onboard/language_level/bloc/language_level_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/language_level/view/language_level_view.dart';
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
import 'package:fastingapp/presentation/auth/welcome/view/welcome_view.dart';
import 'package:fastingapp/presentation/chat/latest/view/latest_chats_view.dart';
import 'package:fastingapp/presentation/chat/view/chat_view.dart';
import 'package:fastingapp/presentation/home/bloc/home_bloc.dart';
import 'package:fastingapp/presentation/home/bloc/home_event.dart';
import 'package:fastingapp/presentation/home/view/home_view.dart';
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
import 'package:fastingapp/presentation/tabs/placeholder_tab_view.dart';
import 'package:fastingapp/presentation/water/reminder/view/water_reminder_view.dart';
import 'package:fastingapp/presentation/water/reminder/water_reminder_result.dart';
import 'package:fastingapp/presentation/water/view/water_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Root navigator anahtarı (dialog/overlay için köke erişim).
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Korumalı (auth gerektiren) rotalar.
/// Not: Shell (home + tablar) şu an UI geliştirme için açık;
/// giriş akışı hazır olunca tekrar korumaya alınır.
const _protectedPaths = <String>{};

bool _isProtectedRoute(String location) => _protectedPaths.contains(location);

/// GoRouter yapılandırması. Auth guard [AuthBloc] state'ine göre çalışır.
/// (Doküman 11)
final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: RoutePaths.home.path,
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
        child: const LoginView(),
      ),
    ),
    GoRoute(
      path: RoutePaths.welcome.path,
      name: RoutePaths.welcome.name,
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<WelcomeBloc>(),
        child: const WelcomeView(),
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
        create: (_) => getIt<StartingPointBloc>(),
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
      builder: (context, state) => const WeightProjectionView(),
    ),
    GoRoute(
      path: RoutePaths.goodCompany.path,
      name: RoutePaths.goodCompany.name,
      builder: (context, state) => const GoodCompanyView(),
    ),
    GoRoute(
      path: RoutePaths.languageLevel.path,
      name: RoutePaths.languageLevel.name,
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<LanguageLevelBloc>(),
        child: const LanguageLevelView(),
      ),
    ),
    GoRoute(
      path: RoutePaths.water.path,
      name: RoutePaths.water.name,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const WaterView(),
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
              builder: (context, state) => BlocProvider(
                create: (_) => getIt<HomeBloc>()..add(const HomeStarted()),
                child: const HomeView(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.fasting.path,
              name: RoutePaths.fasting.name,
              builder: (context, state) =>
                  const PlaceholderTabView(titleKey: 'home.nav_fasting'),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.plans.path,
              name: RoutePaths.plans.name,
              builder: (context, state) =>
                  const PlaceholderTabView(titleKey: 'home.nav_plans'),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.insights.path,
              name: RoutePaths.insights.name,
              builder: (context, state) =>
                  const PlaceholderTabView(titleKey: 'home.nav_insights'),
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
