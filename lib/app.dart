import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/connectivity/offline_gate.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/home_widgets/water_widget_sync.dart';
import 'package:fastingapp/core/managers/localization_manager.dart';
import 'package:fastingapp/core/router/app_router.dart';
import 'package:fastingapp/core/sync/app_sync_scope.dart';
import 'package:fastingapp/core/theme/app_theme.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_bloc.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Uygulama kökü: global BLoC'lar + MaterialApp.router. (Doküman 12)
final class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Bir kez: `build` her dil değişiminde çalışır, oturum kontrolü (ve cihaz
    // kaydı) tekrar etmesin.
    getIt<AuthBloc>().add(const AuthCheckRequested());
  }

  @override
  Widget build(BuildContext context) {
    LocalizationManager.current = context.locale;
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: getIt<AuthBloc>()),
        // Diğer global BLoC'lar buraya eklenir.
      ],
      child: MaterialApp.router(
        title: 'Mochi Fast',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        builder: (context, child) {
          return OfflineGate(
            child: WaterWidgetTapHandler(
              child: WaterWidgetLocaleSync(
                child: AppSyncScope(child: child ?? const SizedBox.shrink()),
              ),
            ),
          );
        },
      ),
    );
  }
}
