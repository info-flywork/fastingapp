import 'package:dio/dio.dart';
import 'package:fastingapp/core/managers/auth_cache_manager.dart';
import 'package:fastingapp/core/network/interceptors/auth_interceptor.dart';
import 'package:fastingapp/core/network/interceptors/expired_token_interceptor.dart';
import 'package:fastingapp/core/network/interceptors/language_interceptor.dart';
import 'package:fastingapp/core/utils/constants/string_constants.dart';
import 'package:fastingapp/domain/auth/auth_repository.dart';
import 'package:flutter/foundation.dart';

/// Dio instance üreticisi. Interceptor zinciri burada kurulur. (Doküman 10)
final class DioClient {
  const DioClient._();

  static Dio create({
    required AuthCacheManager authCacheManager,
    required AuthRepository Function() authRepositoryProvider,
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
      AuthInterceptor(authCacheManager),
      ExpiredTokenInterceptor(authCacheManager, authRepositoryProvider),
      if (kDebugMode) LogInterceptor(requestBody: true, responseBody: true),
    ]);

    return dio;
  }
}
