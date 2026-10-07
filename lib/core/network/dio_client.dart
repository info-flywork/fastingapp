import 'package:dio/dio.dart';
import 'package:fastingapp/core/managers/auth_cache_manager.dart';
import 'package:fastingapp/core/managers/device_manager.dart';
import 'package:fastingapp/core/network/interceptors/auth_interceptor.dart';
import 'package:fastingapp/core/network/interceptors/context_interceptor.dart';
import 'package:fastingapp/core/network/interceptors/expired_token_interceptor.dart';
import 'package:fastingapp/core/network/interceptors/language_interceptor.dart';
import 'package:fastingapp/core/utils/constants/string_constants.dart';
import 'package:flutter/foundation.dart';

/// Dio instance üreticisi. Interceptor zinciri burada kurulur. (Doküman 10)
final class DioClient {
  const DioClient._();

  /// [onSessionEnded]: oturum kurtarılamadığında (refresh reddi, hesap kapalı)
  /// çağrılır; global çıkışı tetikler.
  static Dio create({
    required AuthCacheManager authCacheManager,
    required DeviceManager deviceManager,
    required void Function() onSessionEnded,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: StringConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      LanguageInterceptor(),
      ContextInterceptor(deviceManager),
      AuthInterceptor(authCacheManager),
      ExpiredTokenInterceptor(
        authCacheManager,
        baseUrl: StringConstants.baseUrl,
        onSessionEnded: onSessionEnded,
      ),
      if (kDebugMode) LogInterceptor(requestBody: true, responseBody: true),
    ]);

    return dio;
  }
}
