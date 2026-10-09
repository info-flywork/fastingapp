import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:fastingapp/core/managers/auth_cache_manager.dart';
import 'package:fastingapp/core/managers/device_manager.dart';
import 'package:fastingapp/core/managers/localization_manager.dart';
import 'package:fastingapp/core/managers/shared_pref_manager.dart';
import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/core/utils/enum/request_type.dart';
import 'package:fastingapp/data/model/auth/account_deletion.dart';
import 'package:fastingapp/data/model/auth/auth_guest_request.dart';
import 'package:fastingapp/data/model/auth/auth_register_request.dart';
import 'package:fastingapp/data/model/auth/auth_response.dart';
import 'package:fastingapp/data/model/auth/no_content.dart';
import 'package:fastingapp/data/model/user/user.dart';
import 'package:fastingapp/domain/auth/auth_exception.dart';
import 'package:fastingapp/domain/auth/social_auth_service.dart';
import 'package:fastingapp/domain/notification/push_service.dart';
import 'package:fastingapp/domain/revenue_cat/revenue_cat_service.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Login, register, guest, refresh token ve profil işleri. (Doküman 7)
final class AuthRepository {
  const AuthRepository(
    this._networkManager,
    this._authCacheManager,
    this._sharedPrefManager,
    this._deviceManager,
    this._socialAuthService,
    this._pushService,
    this._revenueCat,
  );

  final NetworkManager _networkManager;
  final AuthCacheManager _authCacheManager;
  final SharedPrefManager _sharedPrefManager;
  final DeviceManager _deviceManager;
  final SocialAuthService _socialAuthService;
  final PushService _pushService;
  final RevenueCatService _revenueCat;

  Future<AuthResponse> loginWithGoogle() async =>
      _register(await _socialAuthService.signInWithGoogle());

  Future<AuthResponse> loginWithApple() async =>
      _register(await _socialAuthService.signInWithApple());

  /// Cihaz başına tek misafir; aynı kurulum tekrar çağırırsa aynı hesap döner.
  /// Misafir sırrı oluşturulurken alınır, sonraki girişlerde gönderilir; sır
  /// geçersizse (ör. Keychain silinmiş) yeni kurulum kimliğiyle yeni misafir.
  Future<AuthResponse> loginAsGuest({
    bool restoreAccount = false,
    bool retried = false,
  }) async {
    final request = AuthGuestRequest(
      installId: await _deviceManager.getDeviceId(),
      platform: _platform,
      locale: _locale,
      restoreAccount: restoreAccount ? true : null,
      guestSecret: await _deviceManager.getGuestSecret(),
    );
    try {
      return await _pendingDeletionAware(() async {
        final result = await _networkManager.send<AuthResponse>(
          path: '/auth/guest',
          method: RequestType.post,
          data: request.toJson(),
          parserModel: AuthResponse.fromJson,
        );
        final secret = result?.guestSecret;
        if (secret != null) await _deviceManager.saveGuestSecret(secret);
        return _save(result);
      }, restore: () => loginAsGuest(restoreAccount: true));
    } on NetworkException catch (e) {
      if (retried || e.details?['reason'] != 'guest_secret_invalid') rethrow;
      await _deviceManager.resetInstall();
      return loginAsGuest(restoreAccount: restoreAccount, retried: true);
    }
  }

  /// Hesap silme talebi (7 gün sonra kalıcı). Apple ile girildiyse önce Apple
  /// token'ı iptal edilir. Başarıda yerel oturum kapatılmalıdır (AuthBloc).
  Future<AccountDeletion> deleteAccount() async {
    await _socialAuthService.revokeAppleIfLinked();
    final result = await _networkManager.send<AccountDeletion>(
      path: '/user/me',
      method: RequestType.delete,
      parserModel: AccountDeletion.fromJson,
    );
    if (result == null) throw AuthException.emptyResponse();
    return result;
  }

  /// Backend `409 ACCOUNT_PENDING_DELETION` →
  /// [AccountPendingDeletionException]; kullanıcı onaylarsa [restore] girişi
  /// hesabı geri açarak tekrarlar.
  Future<AuthResponse> _pendingDeletionAware(
    Future<AuthResponse> Function() login, {
    required Future<AuthResponse> Function() restore,
  }) async {
    try {
      return await login();
    } on NetworkException catch (e) {
      final scheduledFor = DateTime.tryParse(
        e.details?['scheduledFor'] as String? ?? '',
      );
      if (e.code != 'ACCOUNT_PENDING_DELETION' || scheduledFor == null) {
        rethrow;
      }
      throw AccountPendingDeletionException<AuthResponse>(
        scheduledFor,
        restore,
      );
    }
  }

  /// Firebase ID token ile giriş ya da kayıt. Misafir oturumu varsa backend
  /// hesabı yükseltir (Authorization header'ı interceptor ekler).
  /// Kimlik başka bir hesaba bağlıysa sunucu o hesaba geçer (birleştirme yok).
  Future<AuthResponse> _register(
    SocialCredential credential, {
    bool restoreAccount = false,
  }) async {
    final hasName =
        credential.givenName != null || credential.familyName != null;
    final request = AuthRegisterRequest(
      provider: 'firebase',
      idToken: credential.idToken,
      deviceId: await _deviceManager.getDeviceId(),
      fullName: hasName
          ? {
              'givenName': credential.givenName,
              'familyName': credential.familyName,
            }
          : null,
      platform: _platform,
      locale: _locale,
      restoreAccount: restoreAccount ? true : null,
    );
    return _pendingDeletionAware(
      () async => _save(
        await _networkManager.send<AuthResponse>(
          path: '/auth/register',
          method: RequestType.post,
          data: request.toJson(),
          parserModel: AuthResponse.fromJson,
        ),
      ),
      restore: () => _register(credential, restoreAccount: true),
    );
  }

  Future<AuthResponse> _save(AuthResponse? result) async {
    if (result == null) throw AuthException.emptyResponse();
    final token = result.token;
    final user = result.user;
    if (token != null) await _authCacheManager.saveToken(token);
    if (user != null) await _authCacheManager.saveUser(user);
    // Tüm girişler buradan geçer (onboarding misafiri dahil): RevenueCat
    // kimliği = kullanıcı UUID'si. Girişi bekletmez.
    unawaited(_revenueCat.logIn(user?.id));
    return result;
  }

  /// Çıkış: sunucuda bu cihazın oturumu kapanır (push token silinir), sonra
  /// yerel temizlik. Sunucuya ulaşılamasa da yerel çıkış yapılır.
  Future<void> logout() async {
    try {
      await _networkManager.send<NoContent>(
        path: '/auth/logout',
        method: RequestType.post,
        data: const <String, dynamic>{},
        parserModel: NoContent.fromJson,
      );
    } on Exception {
      // Oturum zaten geçersiz olabilir; yerel çıkış yine yapılır.
    }
    await endLocalSession();
  }

  /// Yalnızca yerel oturum (token, kullanıcı, Firebase/Google, RevenueCat)
  /// temizlenir.
  Future<void> endLocalSession() async {
    await _revenueCat.logOut();
    await _socialAuthService.signOut().catchError((_) {});
    await _authCacheManager.clearAll();
  }

  /// Saklı token varsa önbellekteki kullanıcı (yoksa boş kullanıcı); token
  /// yoksa null.
  Future<User?> cachedSession() async {
    final token = await _authCacheManager.getAccessToken();
    if (token == null || token.isEmpty) return null;
    return await _authCacheManager.getUser() ?? const User();
  }

  Future<bool> isAuthenticated() async => await cachedSession() != null;

  /// Cihaz kaydı (`PUT /devices/current`): açılışta ve girişte. Sunucu cihazın
  /// saat dilimini, dilini ve sürümünü günceller; push token burada
  /// gönderilmez (alan gönderilmezse sunucu dokunmaz). Hata yutulur.
  Future<void> registerDevice() async {
    try {
      final results = await Future.wait<String>([
        FlutterTimezone.getLocalTimezone().then((t) => t.identifier),
        PackageInfo.fromPlatform().then((p) => p.version),
        _deviceManager.getDeviceId(),
      ]);
      final os = Platform.operatingSystemVersion;
      final push = await _pushService.currentToken();
      _pushService.listenTokenRefresh(() => unawaited(registerDevice()));
      await _networkManager.send<NoContent>(
        path: '/devices/current',
        method: RequestType.put,
        data: {
          'installId': results[2],
          'platform': _platform,
          'appVersion': results[1],
          'osVersion': os.length > 32 ? os.substring(0, 32) : os,
          'timezone': results[0],
          'locale': ?_locale,
          'pushEnabled': push.enabled,
          // Token yoksa alan gönderilmez (sunucudaki token korunur).
          'pushToken': ?push.token,
        },
        parserModel: NoContent.fromJson,
      );
    } on Object {
      // Kayıt bir sonraki açılışta tekrar denenir.
    }
  }

  bool isFirstLaunch() => _sharedPrefManager.isFirstLaunch;

  Future<void> completeFirstLaunch() => _sharedPrefManager.setFirstLaunchDone();

  static String get _platform => Platform.isIOS ? 'ios' : 'android';

  /// Desteklenmeyen dil gönderilmez (backend reddeder; varsayılanı kullanır).
  static String? get _locale {
    final locale = PlatformDispatcher.instance.locale;
    return LocalizationManager.isSupported(locale) ? locale.languageCode : null;
  }
}
