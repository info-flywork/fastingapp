import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fastingapp/core/managers/device_manager.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

/// İstek bağlamı (backend doküman 13 §1): `X-Timezone` (IANA), `X-App-Version`,
/// `X-Platform`, `X-Install-Id`; yazma isteklerine `Idempotency-Key`.
///
/// Saat dilimi ve sürüm bir kez okunur. Idempotency anahtarı istek
/// seçeneklerinde saklanır: token yenileme sonrası tekrar denemede aynı kalır.
final class ContextInterceptor extends Interceptor {
  ContextInterceptor(this._deviceManager);

  final DeviceManager _deviceManager;
  static const _uuid = Uuid();
  static const _writeMethods = {'POST', 'PUT', 'PATCH', 'DELETE'};

  Future<_Context>? _context;

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
      final context = await (_context ??= _load());
      options.headers.addAll({
        'X-Timezone': context.timezone,
        'X-App-Version': context.appVersion,
        'X-Install-Id': context.installId,
      });
    } on Object {
      // Bağlam okunamazsa istek yine gider (sunucu varsayılanları kullanır).
      _context = null;
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
