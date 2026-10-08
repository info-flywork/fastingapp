import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/app.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/init/app_init.dart';
import 'package:fastingapp/core/managers/localization_manager.dart';
import 'package:fastingapp/core/push/push_open_handler.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  await const AppInit().initialize();
  await configureDependencies();
  runApp(
    EasyLocalization(
      supportedLocales: LocalizationManager.supportedLocales,
      path: LocalizationManager.translationsPath,
      fallbackLocale: LocalizationManager.fallbackLocale,
      child: const MyApp(),
    ),
  );
  // Push'a dokunma: okundu + ilgili ekran.
  PushOpenHandler.start();
}
