import 'dart:async';

import 'package:fastingapp/core/managers/auth_cache_manager.dart';
import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/core/sync/data_sync.dart';
import 'package:fastingapp/core/utils/constants/revenue_cat_constants.dart';
import 'package:fastingapp/core/utils/enum/request_type.dart';
import 'package:fastingapp/data/model/subscription/subscription_status.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

/// RevenueCat (purchases_flutter) + sunucu abonelik senkronu
/// (backend doküman 11).
///
/// - `app_user_id` = backend kullanıcı UUID'si: açılışta önbellekteki
///   kullanıcıyla `configure`, her girişte `logIn` ([AuthRepository]).
///   Oturumsuz satın alma anonim kimliğe düşer; `logIn` onu kullanıcıya bağlar.
/// - Erişim kararını sunucu verir (`POST /subscription/sync`); CustomerInfo
///   yalnızca anlık UI içindir (sunucuya ulaşılamazsa).
/// - Paywall tamamen RevenueCat Paywalls'ta (`default` offering).
final class RevenueCatService {
  RevenueCatService(this._networkManager, this._authCacheManager);

  final NetworkManager _networkManager;
  final AuthCacheManager _authCacheManager;

  /// Premium durumu (profil rozeti, kilitli planlar, üst bar).
  final ValueNotifier<bool> isPremium = ValueNotifier(false);

  /// Sunucuda sync 20/saat sınırlı; mağaza güncellemeleri bunu aşmasın.
  static const _syncThrottle = Duration(minutes: 1);

  Future<void>? _configuring;
  bool _configured = false;
  DateTime? _lastSync;

  /// Bir kez yapılandırır (sonraki çağrılar aynı Future'ı bekler).
  Future<void> init() => _configuring ??= _configure();

  Future<void> _configure() async {
    final apiKey = RevenueCatConstants.apiKey;
    if (apiKey.isEmpty) return;
    try {
      final user = await _authCacheManager.getUser();
      if (user?.isPremium ?? false) isPremium.value = true;
      if (kDebugMode) await Purchases.setLogLevel(LogLevel.debug);
      final userId = await _sessionUserId(user?.id);
      await Purchases.configure(
        PurchasesConfiguration(apiKey)..appUserID = userId,
      );
      _configured = true;
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfo);
      if (userId != null) unawaited(sync());
    } on Object catch (e) {
      debugPrint('RevenueCat configure: $e');
    }
  }

  /// Girişten sonra (misafir dahil). Kullanıcı değiştiyse (ör. hesap
  /// birleştirme) RevenueCat kimliği de değişir; ardından sunucu senkronu.
  Future<void> logIn(String? userId) async {
    if (!_isUuid(userId)) return;
    await init();
    if (!_configured) return;
    try {
      if (await Purchases.appUserID != userId) {
        await Purchases.logIn(userId!);
      }
    } on Object catch (e) {
      debugPrint('RevenueCat logIn: $e');
    }
    await sync(force: true);
  }

  /// Çıkışta: sonraki kullanıcı bu hesabın aboneliğini görmesin.
  Future<void> logOut() async {
    isPremium.value = false;
    _lastSync = null;
    _serverPremium = null;
    if (!_configured) return;
    try {
      if (!await Purchases.isAnonymous) await Purchases.logOut();
    } on Object catch (e) {
      debugPrint('RevenueCat logOut: $e');
    }
  }

  /// Sunucunun en son bildirdiği premium (yerel satın almadan bağımsız);
  /// bilinmiyorsa null.
  bool? _serverPremium;

  /// `POST /subscription/sync`: sunucu RevenueCat'ten okur, premium'u
  /// günceller (bekleyen premium planı da etkinleştirir). Oturum yoksa
  /// çağrılmaz. Sonuç premium mu.
  /// [keepPremium]: satın almanın hemen ardından sunucu henüz RevenueCat'i
  /// görmemiş olabilir; "premium değil" yanıtı yerel premium'u düşürmez.
  Future<bool> sync({bool force = false, bool keepPremium = false}) async {
    final last = _lastSync;
    if (!force &&
        last != null &&
        DateTime.now().difference(last) < _syncThrottle) {
      return isPremium.value;
    }
    final token = await _authCacheManager.getAccessToken();
    if (token == null || token.isEmpty) return isPremium.value;
    _lastSync = DateTime.now();
    try {
      final result = await _networkManager.send<SubscriptionStatus>(
        path: '/subscription/sync',
        method: RequestType.post,
        data: const <String, dynamic>{},
        parserModel: SubscriptionStatus.fromJson,
      );
      if (result != null && (result.isPremium || !keepPremium)) {
        isPremium.value = result.isPremium;
      }
      if (result != null) {
        // Sunucu premium'a geçince bekleyen premium planı etkinleştirir:
        // plan / profil / ana sayfa her yerde tazelenmeli (önceden yalnızca
        // ana sayfadaki "Premium" hapından alınca yenileniyordu).
        if (result.isPremium && _serverPremium == false) {
          DataSync.afterWrite(profile: true);
        }
        _serverPremium = result.isPremium;
        return result.isPremium;
      }
    } on Object catch (e) {
      // Sunucuya ulaşılamadı / billing kapalı (503): anlık UI mağazadan.
      debugPrint('Abonelik senkronu: $e');
      await _applyStoreEntitlement();
    }
    return isPremium.value;
  }

  /// RevenueCat paywall'ı. Satın alma / geri yüklemeden sonra sunucu
  /// senkronlanır. Kullanıcı premium ise true.
  Future<bool> presentPaywall() async {
    await init();
    if (!_configured) return isPremium.value;
    try {
      Offering? offering;
      try {
        final offerings = await Purchases.getOfferings();
        offering =
            offerings.getOffering(RevenueCatConstants.offering) ??
            offerings.current;
      } on Object catch (e) {
        debugPrint('RevenueCat offerings: $e');
      }
      final result = await RevenueCatUI.presentPaywall(
        offering: offering,
        displayCloseButton: true,
      );
      if (result == PaywallResult.purchased ||
          result == PaywallResult.restored) {
        // Sunucu senkronu başarısız / gecikmeli olsa da satın alma geçerli.
        isPremium.value = true;
        final confirmed = await sync(force: true, keepPremium: true);
        if (!confirmed) unawaited(_confirmPurchaseLater());
      }
    } on Object catch (e) {
      debugPrint('RevenueCat paywall: $e');
    }
    return isPremium.value;
  }

  /// Satın alma sunucuya birkaç saniye geç yansıyabilir (RevenueCat):
  /// premium'u düşürmeden birkaç kez yeniden senkronlanır.
  Future<void> _confirmPurchaseLater() async {
    _confirmingPurchase = true;
    try {
      for (final wait in const [3, 10, 30]) {
        await Future<void>.delayed(Duration(seconds: wait));
        if (await sync(force: true, keepPremium: true)) return;
      }
    } finally {
      _confirmingPurchase = false;
    }
  }

  bool _confirmingPurchase = false;

  /// Sunucu yanıtındaki premium (ör. `/user/summary`); satın alma henüz
  /// sunucuya yansımadıysa yerel premium düşürülmez.
  void applyServerPremium(bool premium) {
    _serverPremium = premium;
    if (!premium && _confirmingPurchase) return;
    isPremium.value = premium;
  }

  /// "Satın alımları geri yükle". Mağaza hatası fırlatılır (UI mesaj
  /// gösterir). Sonuç premium mu.
  Future<bool> restore() async {
    await init();
    if (!_configured) throw StateError('RevenueCat yapılandırılmadı');
    final info = await Purchases.restorePurchases();
    if (_hasEntitlement(info)) isPremium.value = true;
    return sync(force: true);
  }

  /// Satın alma sonrası tekrar: mağaza premium dediği hâlde sunucu henüz
  /// bilmiyorsa (`PREMIUM_REQUIRED` / kota) birkaç saniye senkronlayıp yeniden
  /// dener. Önceden satın almadan hemen sonraki ilk tekrar 402 alabiliyordu.
  Future<T> retryAfterUpgrade<T>(Future<T> Function() call) async {
    for (final wait in const [0, 2, 4]) {
      if (wait > 0) {
        await Future<void>.delayed(Duration(seconds: wait));
        await sync(force: true, keepPremium: true);
      }
      try {
        return await call();
      } on NetworkException catch (e) {
        if (!needsUpgrade(e) || !isPremium.value || wait == 4) rethrow;
      }
    }
    return call();
  }

  /// Backend `402 PREMIUM_REQUIRED` ya da yükseltilebilir
  /// `429 QUOTA_EXCEEDED` → paywall gösterilmeli.
  static bool needsUpgrade(Object error) {
    if (error is! NetworkException) return false;
    if (error.code == 'PREMIUM_REQUIRED') return true;
    return error.code == 'QUOTA_EXCEEDED' &&
        error.details?['upgradeAvailable'] == true;
  }

  /// Mağazada yetki değiştiyse (satın alma, yenileme, iade) sunucuya sor.
  void _onCustomerInfo(CustomerInfo info) {
    final active = _hasEntitlement(info);
    if (active == isPremium.value) return;
    if (active) isPremium.value = true;
    unawaited(sync());
  }

  Future<void> _applyStoreEntitlement() async {
    if (!_configured) return;
    try {
      isPremium.value = _hasEntitlement(await Purchases.getCustomerInfo());
    } on Object {
      // Son bilinen değer kalır.
    }
  }

  static bool _hasEntitlement(CustomerInfo info) =>
      info.entitlements.active.containsKey(RevenueCatConstants.entitlement);

  /// Oturum varsa önbellekteki kullanıcı kimliği; yoksa anonim (null).
  Future<String?> _sessionUserId(String? cachedId) async {
    final token = await _authCacheManager.getAccessToken();
    if (token == null || token.isEmpty) return null;
    return _isUuid(cachedId) ? cachedId : null;
  }

  /// Sunucu UUID olmayan kimlikleri yok sayar; RevenueCat'e de gönderilmez.
  static bool _isUuid(String? id) =>
      id != null &&
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      ).hasMatch(id);
}
