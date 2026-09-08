import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/managers/shared_pref_manager.dart';
import 'package:flutter/widgets.dart';

/// Uygulama başlangıç sırası: binding, prefs, localization, servis init.
/// (Doküman 4)
final class AppInit {
  const AppInit();

  Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
    await SharedPrefManager.instance.init();
    // TODO(team): env yükleme, RevenueCat init vb.
  }
}
