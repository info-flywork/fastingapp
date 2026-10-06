import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/connectivity/connectivity_service.dart';
import 'package:fastingapp/core/managers/shared_pref_manager.dart';
import 'package:fastingapp/core/remote_images/remote_image_store.dart';
import 'package:flutter/widgets.dart';

/// Uygulama başlangıç sırası: binding, prefs, localization, servis init.
/// (Doküman 4)
final class AppInit {
  const AppInit();

  Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
    await SharedPrefManager.instance.init();
    // Uzak görseller: manifest şimdi (küçük, gömülü); eksik dosyalar ilk kare
    // çizildikten sonra arka planda iner (cihaz başına bir kez).
    await RemoteImageStore.instance.ensureInitialized();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(RemoteImageStore.instance.syncInBackground());
    });
    // İnternet yok sayfası (OfflineGate) + bağlantı gelince yarım kalan
    // görsel indirmeleri sürdürülür.
    final connectivity = ConnectivityService.instance..start();
    connectivity.reconnects.addListener(
      () => unawaited(RemoteImageStore.instance.syncInBackground()),
    );
    // TODO(team): env yükleme, RevenueCat init vb.
  }
}
