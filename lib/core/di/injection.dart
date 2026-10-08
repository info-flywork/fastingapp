import 'package:dio/dio.dart';
import 'package:fastingapp/core/managers/auth_cache_manager.dart';
import 'package:fastingapp/core/managers/device_manager.dart';
import 'package:fastingapp/core/managers/localization_manager.dart';
import 'package:fastingapp/core/managers/notification_manager.dart';
import 'package:fastingapp/core/managers/permission_manager.dart';
import 'package:fastingapp/core/managers/shared_pref_manager.dart';
import 'package:fastingapp/core/managers/url_launcher_manager.dart';
import 'package:fastingapp/core/network/dio_client.dart';
import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/domain/auth/auth_repository.dart';
import 'package:fastingapp/domain/auth/social_auth_service.dart';
import 'package:fastingapp/domain/fasting/forecast_repository.dart';
import 'package:fastingapp/domain/notification/notifications_repository.dart';
import 'package:fastingapp/domain/notification/push_service.dart';
import 'package:fastingapp/domain/onboarding/onboarding_draft.dart';
import 'package:fastingapp/domain/onboarding/onboarding_repository.dart';
import 'package:fastingapp/domain/product/product_repository.dart';
import 'package:fastingapp/domain/progress/progress_repository.dart';
import 'package:fastingapp/domain/revenue_cat/revenue_cat_service.dart';
import 'package:fastingapp/domain/user/user_repository.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_bloc.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_event.dart';
import 'package:fastingapp/presentation/auth/onboard/about_you/bloc/about_you_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/diet/bloc/diet_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/fasting_plan/bloc/fasting_plan_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/fasting_reason/bloc/fasting_reason_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/food_loves/bloc/food_loves_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/food_skips/bloc/food_skips_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/goal/bloc/goal_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/language_level/bloc/language_level_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/meal_window/bloc/meal_window_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/obstacles/bloc/obstacles_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/starting_point/bloc/starting_point_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/weight_history/bloc/weight_history_bloc.dart';
import 'package:fastingapp/presentation/auth/splash/bloc/splash_bloc.dart';
import 'package:fastingapp/presentation/auth/welcome/bloc/welcome_bloc.dart';
import 'package:fastingapp/presentation/chat/bloc/chat_session_cubit.dart';
import 'package:fastingapp/presentation/home/bloc/home_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

/// Global service locator. (Doküman 12)
final getIt = GetIt.instance;

/// Tüm bağımlılıkları kaydeder. `main` içinde bir kez çağrılır.
Future<void> configureDependencies() async {
  // ── Managers ──
  getIt
    ..registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      ),
    )
    ..registerLazySingleton<AuthCacheManager>(() => AuthCacheManager(getIt()))
    ..registerLazySingleton<SharedPrefManager>(() => SharedPrefManager.instance)
    ..registerLazySingleton<LocalizationManager>(LocalizationManager.new)
    ..registerLazySingleton<NotificationManager>(NotificationManager.new)
    ..registerLazySingleton<PermissionManager>(PermissionManager.new)
    ..registerLazySingleton<UrlLauncherManager>(UrlLauncherManager.new)
    ..registerLazySingleton<DeviceManager>(() => DeviceManager(getIt()))
    // ── Network ──
    ..registerLazySingleton<Dio>(
      () => DioClient.create(
        authCacheManager: getIt(),
        deviceManager: getIt(),
        // Lazy: Dio → AuthBloc → AuthRepository → Dio döngüsü kurulmaz.
        onSessionEnded: () => getIt<AuthBloc>().add(const AuthSessionEnded()),
      ),
    )
    ..registerLazySingleton<NetworkManager>(() => NetworkManager(getIt()))
    // ── Repositories / Services ──
    ..registerLazySingleton<SocialAuthService>(SocialAuthService.new)
    ..registerLazySingleton<PushService>(PushService.new)
    ..registerLazySingleton<AuthRepository>(
      () =>
          AuthRepository(getIt(), getIt(), getIt(), getIt(), getIt(), getIt()),
    )
    ..registerLazySingleton<ForecastRepository>(
      () => ForecastRepository(getIt()),
    )
    ..registerLazySingleton<OnboardingDraft>(OnboardingDraft.new)
    ..registerLazySingleton<OnboardingRepository>(
      () => OnboardingRepository(getIt(), getIt(), getIt(), getIt()),
    )
    ..registerLazySingleton<UserRepository>(() => UserRepository(getIt()))
    ..registerLazySingleton<ProductRepository>(
      () => ProductRepository(getIt(), getIt()),
    )
    ..registerLazySingleton<NotificationsRepository>(
      () => NotificationsRepository(getIt()),
    )
    ..registerLazySingleton<ProgressRepository>(
      () => ProgressRepository(getIt()),
    )
    ..registerLazySingleton<RevenueCatService>(RevenueCatService.new)
    // ── Global BLoCs (singleton) ──
    ..registerLazySingleton<AuthBloc>(() => AuthBloc(getIt()))
    ..registerLazySingleton<ChatSessionCubit>(ChatSessionCubit.new)
    // ── Ekran BLoC'ları (factory) ──
    ..registerFactory<SplashBloc>(() => SplashBloc(getIt()))
    ..registerFactory<WelcomeBloc>(() => WelcomeBloc(getIt(), getIt()))
    ..registerFactory<GoalBloc>(GoalBloc.new)
    ..registerFactory<AboutYouBloc>(AboutYouBloc.new)
    ..registerFactory<StartingPointBloc>(StartingPointBloc.new)
    ..registerFactory<DietBloc>(DietBloc.new)
    ..registerFactory<FoodLovesBloc>(FoodLovesBloc.new)
    ..registerFactory<FoodSkipsBloc>(FoodSkipsBloc.new)
    ..registerFactory<WeightHistoryBloc>(WeightHistoryBloc.new)
    ..registerFactory<ObstaclesBloc>(ObstaclesBloc.new)
    ..registerFactory<FastingReasonBloc>(FastingReasonBloc.new)
    ..registerFactory<FastingPlanBloc>(FastingPlanBloc.new)
    ..registerFactory<MealWindowBloc>(MealWindowBloc.new)
    ..registerFactory<LanguageLevelBloc>(() => LanguageLevelBloc(getIt()))
    ..registerFactory<HomeBloc>(() => HomeBloc(getIt()));
}
