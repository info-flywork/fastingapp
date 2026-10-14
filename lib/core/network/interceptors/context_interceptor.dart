import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fastingapp/core/managers/device_manager.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

/// İstek bağlamı (backend doküman 13 §1): `X-Timezone` (IANA), `X-App-Version`,
/// `X-Platform`, `X-Install-Id`; yazma isteklerine `Idempotency-Key`.
///
/// Sürüm ve kurulum kimliği bir kez okunur; saat dilimi en fazla 10 dk'da bir
/// yeniden okunur (seyahatte sunucunun "bugün"ü cihazla ayrışmasın). Idempotency anahtarı istek
/// seçeneklerinde saklanır: token yenileme sonrası tekrar denemede aynı kalır.
final class ContextInterceptor extends Interceptor {
  ContextInterceptor(this._deviceManager);

  final DeviceManager _deviceManager;
  static const _uuid = Uuid();
  static const _writeMethods = {'POST', 'PUT', 'PATCH', 'DELETE'};

  Future<_Context>? _context;
  DateTime? _loadedAt;
  static const _timezoneTtl = Duration(minutes: 10);

  Future<_Context> _load() async {
    final results = await Future.wait<Object>([
      FlutterTimezone.getLocalTimezone().then((t) => t.identifier),
      PackageInfo.fromPlatform().then((p) => p.version),
      _deviceManager.getDeviceId(),
    ]);
    return _Context(
      timezone: results[0] as String,
      appVersion: results[1] as String,
      installId: results[2] as String,
    );
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final loadedAt = _loadedAt;
      if (loadedAt == null ||
          DateTime.now().difference(loadedAt) > _timezoneTtl) {
        _context = _load();
        _loadedAt = DateTime.now();
      }
      final context = await _context!;
      options.headers.addAll({
        'X-Timezone': context.timezone,
        'X-App-Version': context.appVersion,
        'X-Install-Id': context.installId,
      });
    } on Object {
      // Bağlam okunamazsa istek yine gider (sunucu varsayılanları kullanır).
      _context = null;
      _loadedAt = null;
    }
    options.headers['X-Platform'] = Platform.isIOS ? 'ios' : 'android';
    if (_writeMethods.contains(options.method.toUpperCase())) {
      options.headers['Idempotency-Key'] ??= options.extra['idempotencyKey'] ??=
          _uuid.v4();
    }
    handler.next(options);
  }
}

final class _Context {
  const _Context({
    required this.timezone,
    required this.appVersion,
    required this.installId,
  });

  final String timezone;
  final String appVersion;
  final String installId;
}
