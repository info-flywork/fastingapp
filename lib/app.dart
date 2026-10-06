import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/home_widgets/water_widget_sync.dart';
import 'package:fastingapp/core/router/app_router.dart';
import 'package:fastingapp/core/theme/app_theme.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_bloc.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Uygulama kökü: global BLoC'lar + MaterialApp.router. (Doküman 12)
final class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(
          value: getIt<AuthBloc>()..add(const AuthCheckRequested()),
        ),
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
          return WaterWidgetTapHandler(
            child: WaterWidgetLocaleSync(
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
