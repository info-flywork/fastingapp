import 'dart:io';

/// RevenueCat ayarları (backend doküman 11). Public SDK anahtarları uygulamaya
/// gömülmek içindir (gizli değil); `--dart-define=REVENUECAT_IOS_KEY=…` /
/// `REVENUECAT_ANDROID_KEY` verilirse o kullanılır.
final class RevenueCatConstants {
  const RevenueCatConstants._();

  /// Sunucudaki `REVENUECAT_ENTITLEMENT` ile aynı olmalı.
  static const entitlement = 'mochifast_pro';

  /// Paywall'ın gösterdiği offering.
  static const offering = 'default';

  static String get apiKey {
    if (Platform.isIOS) {
      const key = String.fromEnvironment('REVENUECAT_IOS_KEY');
      return key.isNotEmpty ? key : 'appl_UFnwqbdvtbmRPlGTKzUxwqKTwTw';
    }
    if (Platform.isAndroid) {
      const key = String.fromEnvironment('REVENUECAT_ANDROID_KEY');
      return key.isNotEmpty ? key : 'goog_TZAjuTFqvBtYlbCBzrXbthmhcrD';
    }
    return '';
  }
}
