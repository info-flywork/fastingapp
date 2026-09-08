import 'package:dio/dio.dart';

/// Ağ katmanı hatalarını anlamlı bir mesajla sarmalar.
final class NetworkException implements Exception {
  const NetworkException(this.message, {this.statusCode});

  factory NetworkException.fromDio(DioException error) {
    return NetworkException(
      error.message ?? 'Beklenmeyen bir ağ hatası oluştu.',
      statusCode: error.response?.statusCode,
    );
  }

  final String message;
  final int? statusCode;

  @override
  String toString() => 'NetworkException($statusCode): $message';
}
