import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';

/// Ağ katmanı hatalarını anlamlı bir mesajla sarmalar.
///
/// Backend hata zarfı:
/// `{ status: "error", message, error: { code, details } }`.
/// [message] sunucunun yerelleştirilmiş mesajıdır (yoksa Dio mesajı).
final class NetworkException implements Exception {
  const NetworkException(
    this.message, {
    this.statusCode,
    this.code,
    this.details,
  });

  factory NetworkException.fromDio(DioException error) {
    final body = error.response?.data;
    final envelope = body is Map<String, dynamic> ? body : null;
    final apiError = envelope?['error'];
    final errorMap = apiError is Map<String, dynamic> ? apiError : null;
    final details = errorMap?['details'];
    // Sunucu mesajı yoksa (zaman aşımı, bağlantı yok…) Dio'nun İngilizce
    // teknik metni yerine çevrili genel mesaj.
    final offline = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      _ => false,
    };
    return NetworkException(
      envelope?['message'] as String? ??
          (offline ? 'common.no_connection' : 'common.error_generic').tr(),
      statusCode: error.response?.statusCode,
      code: errorMap?['code'] as String?,
      details: details is Map<String, dynamic> ? details : null,
    );
  }

  final String message;
  final int? statusCode;

  /// Backend hata kodu, ör. `ACCOUNT_PENDING_DELETION`.
  final String? code;
  final Map<String, dynamic>? details;

  @override
  String toString() => 'NetworkException($statusCode): $message';
}

/// Kullanıcıya gösterilecek hata metni: sunucunun yerelleştirilmiş mesajı ya
/// da çevrili genel mesaj (önceden "Bad state: …" gibi ham metin çıkıyordu).
String errorMessageOf(Object error) => switch (error) {
  NetworkException(:final message) when message.isNotEmpty => message,
  _ => 'common.error_generic'.tr(),
};
