import 'dart:convert';

import 'package:fastingapp/data/model/token/token.dart';
import 'package:fastingapp/data/model/user/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// JWT token'ları ve kullanıcıyı [FlutterSecureStorage]'a yazar/okur.
/// (Doküman 8)
///
/// Erişim token'ı bellekte de tutulur: her istekte Keychain/Keystore okuması
/// yapılmaz. DI'da tekil (singleton) olmalı; yazma/silme önbelleği günceller.
final class AuthCacheManager {
  AuthCacheManager(this._storage);

  final FlutterSecureStorage _storage;

  String? _accessToken;
  bool _accessLoaded = false;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user_json';

  Future<void> saveToken(Token token) async {
    _accessToken = token.accessToken;
    _accessLoaded = true;
    await _storage.write(key: _accessTokenKey, value: token.accessToken);
    await _storage.write(key: _refreshTokenKey, value: token.refreshToken);
  }

  Future<String?> getAccessToken() async {
    if (_accessLoaded) return _accessToken;
    _accessToken = await _storage.read(key: _accessTokenKey);
    _accessLoaded = true;
    return _accessToken;
  }

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveUser(User user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<User?> getUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null || raw.isEmpty) return null;
    return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Yalnızca oturum anahtarları; kurulum kimliği (DeviceManager) kalır.
  Future<void> clearAll() async {
    _accessToken = null;
    _accessLoaded = true;
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
  }
}
