import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Kurulum kimliği (guest login için; backend cihaz başına tek misafir tutar).
/// (Doküman 8)
///
/// Keychain'de saklanır: iOS'ta uygulama silinip kurulsa da aynı kalır.
final class DeviceManager {
  DeviceManager(this._storage);

  final FlutterSecureStorage _storage;

  static const _installIdKey = 'install_id';
  static const _guestSecretKey = 'guest_secret';

  String? _cached;

  /// UUID v4; ilk çağrıda üretilir.
  Future<String> getDeviceId() async {
    final cached = _cached;
    if (cached != null) return cached;
    var id = await _storage.read(key: _installIdKey);
    if (id == null || id.isEmpty) {
      id = _uuidV4();
      await _storage.write(key: _installIdKey, value: id);
    }
    return _cached = id;
  }

  /// Misafir sırrı (backend oluştururken bir kez verir); kurulum kimliğiyle
  /// birlikte saklanır.
  Future<String?> getGuestSecret() => _storage.read(key: _guestSecretKey);

  Future<void> saveGuestSecret(String secret) =>
      _storage.write(key: _guestSecretKey, value: secret);

  /// Sır kaybolduysa (ya da geçersizse) eski misafire girilemez: yeni kurulum
  /// kimliği ile yeni misafir açılır.
  Future<void> resetInstall() async {
    _cached = null;
    await _storage.delete(key: _installIdKey);
    await _storage.delete(key: _guestSecretKey);
  }

  static String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return [
      hex.substring(0, 8),
      hex.substring(8, 12),
      hex.substring(12, 16),
      hex.substring(16, 20),
      hex.substring(20),
    ].join('-');
  }
}
