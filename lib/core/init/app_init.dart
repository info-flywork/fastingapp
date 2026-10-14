import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/connectivity/connectivity_service.dart';
import 'package:fastingapp/core/managers/shared_pref_manager.dart';
import 'package:fastingapp/core/remote_images/remote_image_store.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

/// Uygulama başlangıç sırası: binding, prefs, localization, servis init.
/// (Doküman 4)
final class AppInit {
  const AppInit();

  Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Yapılandırma native dosyalardan: GoogleService-Info.plist /
    // google-services.json.
    // Birbirinden bağımsız: sırayla değil birlikte (açılış süresi).
    // Uzak görseller: manifest şimdi (küçük, gömülü); eksik dosyalar ilk kare
    // çizildikten sonra arka planda iner (cihaz başına bir kez).
    await Future.wait([
      Firebase.initializeApp(),
      EasyLocalization.ensureInitialized(),
      SharedPrefManager.instance.init(),
      RemoteImageStore.instance.ensureInitialized(),
    ]);
    // İlk açılışın ağ ve CPU'sunu (giriş, özet) paylaşmasın diye biraz sonra;
    // o arada ekrana gelen görsel zaten anında indirilir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(const Duration(seconds: 3), () {
        unawaited(RemoteImageStore.instance.syncInBackground());
      });
    });
    // İnternet yok sayfası (OfflineGate) + bağlantı gelince yarım kalan
    // görsel indirmeleri sürdürülür.
    final connectivity = ConnectivityService.instance..start();
    connectivity.reconnects.addListener(
      () => unawaited(RemoteImageStore.instance.syncInBackground()),
    );
    // RevenueCat: DI'dan sonra `main` içinde (RevenueCatService.init).
  }
}
