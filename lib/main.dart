import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/app.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/init/app_init.dart';
import 'package:fastingapp/core/managers/localization_manager.dart';
import 'package:fastingapp/core/push/push_open_handler.dart';
import 'package:fastingapp/domain/revenue_cat/revenue_cat_service.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  await const AppInit().initialize();
  await configureDependencies();
  // RevenueCat: önbellekteki kullanıcıyla (yoksa anonim); açılışı bekletmez.
  unawaited(getIt<RevenueCatService>().init());
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
