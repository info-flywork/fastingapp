import 'dart:convert';

import 'package:fastingapp/data/model/token/token.dart';
import 'package:fastingapp/data/model/user/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// JWT token'ları ve kullanıcıyı [FlutterSecureStorage]'a yazar/okur.
/// (Doküman 8)
final class AuthCacheManager {
  const AuthCacheManager(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user_json';

  Future<void> saveToken(Token token) async {
    await _storage.write(key: _accessTokenKey, value: token.accessToken);
    await _storage.write(key: _refreshTokenKey, value: token.refreshToken);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

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
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
  }
}
