import 'package:dio/dio.dart';
import 'package:fastingapp/core/managers/auth_cache_manager.dart';
import 'package:fastingapp/data/model/token/token.dart';

/// Oturum yenileme (backend doküman 13 §1 #5).
///
/// - `401 TOKEN_EXPIRED`: tek uçuşlu refresh. [QueuedInterceptor] hataları sırayla
///   işler; aynı anda süresi dolan istekler ilk refresh'i bekler, sonra yeni
///   token'la tekrar denenir (ikinci kez refresh yapılmaz).
/// - Refresh reddedilirse (`REFRESH_REUSED`, `UNAUTHENTICATED`) ya da oturum
///   sunucuda kapanmışsa (`401 UNAUTHENTICATED`, `410 GONE`) [onSessionEnded].
///
/// Refresh ve tekrar deneme interceptor'sız ayrı bir Dio ile yapılır (döngü ve
/// kuyruk kilitlenmesi olmaz); başlıklar özgün istekte zaten ekli.
final class ExpiredTokenInterceptor extends QueuedInterceptor {
  ExpiredTokenInterceptor(
    this._authCacheManager, {
    required String baseUrl,
    required void Function() onSessionEnded,
  }) : _onSessionEnded = onSessionEnded,
       _plain = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: const Duration(seconds: 15),
           receiveTimeout: const Duration(seconds: 15),
           headers: {'Content-Type': 'application/json'},
         ),
       );

  final AuthCacheManager _authCacheManager;
  final void Function() _onSessionEnded;
  final Dio _plain;

  static const _retriedKey = 'tokenRetried';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final code = _errorCode(err.response);
    final options = err.requestOptions;
    final isAuthCall = options.path.startsWith('/auth/');

    if (status == 401 &&
        code == 'TOKEN_EXPIRED' &&
        options.extra[_retriedKey] != true &&
        !isAuthCall) {
      final token = await _freshAccessToken(_bearerOf(options));
      if (token == null) {
        await _endSession();
        return handler.next(err);
      }
      options
        ..headers['Authorization'] = 'Bearer $token'
        ..extra[_retriedKey] = true;
      try {
        return handler.resolve(await _plain.fetch<dynamic>(options));
      } on DioException catch (retryError) {
        return handler.next(retryError);
      }
    }

    final sessionGone =
        !isAuthCall &&
        options.headers['Authorization'] != null &&
        ((status == 401 && code == 'UNAUTHENTICATED') || status == 410);
    if (sessionGone) await _endSession();
    handler.next(err);
  }

  /// Başka bir istek zaten yenilediyse saklanan token; değilse refresh.
  Future<String?> _freshAccessToken(String? sent) async {
    final stored = await _authCacheManager.getAccessToken();
    if (stored != null && stored.isNotEmpty && stored != sent) return stored;
    final refreshToken = await _authCacheManager.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;
    try {
      final response = await _plain.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data?['data'];
      final token = data is Map<String, dynamic> ? data['token'] : null;
      if (token is! Map<String, dynamic>) return null;
      final pair = Token.fromJson(token);
      await _authCacheManager.saveToken(pair);
      return pair.accessToken;
    } on DioException {
      return null;
    }
  }

  Future<void> _endSession() async {
    await _authCacheManager.clearAll();
    _onSessionEnded();
  }

  static String? _bearerOf(RequestOptions options) {
    final header = options.headers['Authorization'];
    return header is String && header.startsWith('Bearer ')
        ? header.substring(7)
        : null;
  }

  static String? _errorCode(Response<dynamic>? response) {
    final body = response?.data;
    if (body is! Map<String, dynamic>) return null;
    final error = body['error'];
    return error is Map<String, dynamic> ? error['code'] as String? : null;
  }
}
