import 'package:flutter/foundation.dart';

/// Sabit string değerleri (baseUrl vb.).
final class StringConstants {
  const StringConstants._();

  /// Backend API kök adresi (`/v1` dahil).
  /// `--dart-define=API_BASE_URL=…` verilirse o kullanılır.
  /// Debug'ta varsayılan yerel API; release'te production.
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kDebugMode) return 'http://127.0.0.1:3000/v1';
    return 'https://mochifast-api.fly-work.com/v1';
  }
}
