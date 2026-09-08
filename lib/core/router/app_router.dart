import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/router/go_router_refresh_stream.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/core/widgets/bottom_navigation_bar/main_wrapper.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_bloc.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_state.dart';
import 'package:fastingapp/presentation/auth/entry/view/entry_view.dart';
import 'package:fastingapp/presentation/auth/onboard/about_you/bloc/about_you_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/about_you/view/about_you_view.dart';
import 'package:fastingapp/presentation/auth/onboard/diet/bloc/diet_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/diet/view/diet_view.dart';
import 'package:fastingapp/presentation/auth/onboard/doable_highlight/view/doable_highlight_view.dart';
import 'package:fastingapp/presentation/auth/onboard/food_loves/bloc/food_loves_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/food_loves/view/food_loves_view.dart';
import 'package:fastingapp/presentation/auth/onboard/food_prefs_nav_args.dart';
import 'package:fastingapp/presentation/auth/onboard/food_skips/bloc/food_skips_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/food_skips/view/food_skips_view.dart';
import 'package:fastingapp/presentation/auth/onboard/goal/bloc/goal_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/goal/view/goal_view.dart';
import 'package:fastingapp/presentation/auth/onboard/goal_highlight/view/goal_highlight_view.dart';
import 'package:fastingapp/presentation/auth/onboard/language_level/bloc/language_level_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/language_level/view/language_level_view.dart';
import 'package:fastingapp/presentation/auth/onboard/noted_highlight/view/noted_highlight_view.dart';
import 'package:fastingapp/presentation/auth/onboard/obstacles/bloc/obstacles_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/obstacles/view/obstacles_view.dart';
import 'package:fastingapp/presentation/auth/onboard/privacy_highlight/view/privacy_highlight_view.dart';
import 'package:fastingapp/presentation/auth/onboard/starting_point/bloc/starting_point_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/starting_point/starting_point_nav_args.dart';
import 'package:fastingapp/presentation/auth/onboard/starting_point/view/starting_point_view.dart';
import 'package:fastingapp/presentation/auth/onboard/weight_history/bloc/weight_history_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/weight_history/view/weight_history_view.dart';
import 'package:fastingapp/presentation/auth/splash/bloc/splash_bloc.dart';
import 'package:fastingapp/presentation/auth/splash/bloc/splash_event.dart';
import 'package:fastingapp/presentation/auth/splash/view/splash_view.dart';
import 'package:fastingapp/presentation/auth/welcome/bloc/welcome_bloc.dart';
import 'package:fastingapp/presentation/auth/welcome/view/welcome_view.dart';
import 'package:fastingapp/presentation/home/bloc/home_bloc.dart';
import 'package:fastingapp/presentation/home/bloc/home_event.dart';
import 'package:fastingapp/presentation/home/view/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Root navigator anahtarı (dialog/overlay için köke erişim).
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Korumalı (auth gerektiren) rotalar.
const _protectedPaths = <String>{'/home', '/catalog', '/settings', '/profile'};

bool _isProtectedRoute(String location) => _protectedPaths.contains(location);

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
      return RoutePaths.entry.path;
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
      path: RoutePaths.languageLevel.path,
      name: RoutePaths.languageLevel.name,
      builder: (context, state) => BlocProvider(
        create: (_) => getIt<LanguageLevelBloc>(),
        child: const LanguageLevelView(),
      ),
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
        // catalog, settings, profile branch'leri buraya eklenir.
      ],
    ),
  ],
);
