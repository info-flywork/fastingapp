import 'package:dio/dio.dart';
import 'package:fastingapp/core/managers/auth_cache_manager.dart';

/// Her isteğe `Authorization: Bearer <token>` header'ı ekler.
final class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._authCacheManager);

  final AuthCacheManager _authCacheManager;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _authCacheManager.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
