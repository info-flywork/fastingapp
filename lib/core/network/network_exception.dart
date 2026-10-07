import 'package:dio/dio.dart';

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
    return NetworkException(
      envelope?['message'] as String? ??
          error.message ??
          'Beklenmeyen bir ağ hatası oluştu.',
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
