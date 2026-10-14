import 'dart:io';

/// Mağaza bağlantıları (paylaş / değerlendir).
abstract final class StoreLinks {
  static const androidPackage = 'com.flywork.mochifast';

  /// App Store Connect → Uygulama Bilgileri → Apple Kimliği (sayısal).
  /// Boşken iOS paylaşımında bağlantı yerine yalnızca metin gider.
  static const iosAppId = String.fromEnvironment('APP_STORE_ID');

  static String? get current {
    if (Platform.isAndroid) {
      return 'https://play.google.com/store/apps/details?id=$androidPackage';
    }
    if (iosAppId.isEmpty) return null;
    return 'https://apps.apple.com/app/id$iosAppId';
  }
}
