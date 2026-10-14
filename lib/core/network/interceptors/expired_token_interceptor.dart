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
///   Refresh ağ hatasıyla düşerse oturum korunur; özgün istek hatayla döner.
///
/// Ana Dio'nun interceptor kuyruğuna girmemek için iki ayrı istemci:
/// - [_refreshDio]: yalnızca `POST /auth/refresh`
/// - [_retryDio]: yenileme sonrası başarısız isteğin tekrar denemesi
/// Böylece uzun retry (SSE / upload) refresh bağlantı havuzunu bloke etmez.
final class ExpiredTokenInterceptor extends QueuedInterceptor {
  ExpiredTokenInterceptor(
    this._authCacheManager, {
    required String baseUrl,
    required this._onSessionEnded,
  }) : _refreshDio = _plainDio(baseUrl),
       _retryDio = _plainDio(baseUrl);

  final AuthCacheManager _authCacheManager;
  final void Function() _onSessionEnded;

  /// Yalnızca token yenileme.
  final Dio _refreshDio;

  /// Yalnızca 401 sonrası tekrar deneme.
  final Dio _retryDio;

  static const _retriedKey = 'tokenRetried';

  static Dio _plainDio(String baseUrl) => Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

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
      final String? token;
      try {
        token = await _freshAccessToken(_bearerOf(options));
      } on DioException catch (refreshError) {
        // Ağ/sunucu hatası: oturum kapatılmaz, istek hatayla düşer (sonra tekrar denenir).
        return handler.next(refreshError);
      }
      if (token == null) {
        await _endSession();
        return handler.next(err);
      }
      try {
        final retry = await _retryOptions(options, token);
        return handler.resolve(await _retryDio.fetch<dynamic>(retry));
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
  ///
  /// `null`: refresh sunucu tarafından reddedildi (oturum biter). Geçici hatalar
  /// (bağlantı yok, zaman aşımı, 5xx, 429) [DioException] olarak fırlatılır.
  Future<String?> _freshAccessToken(String? sent) async {
    final stored = await _authCacheManager.getAccessToken();
    if (stored != null && stored.isNotEmpty && stored != sent) return stored;
    final refreshToken = await _authCacheManager.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;
    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data?['data'];
      final token = data is Map<String, dynamic> ? data['token'] : null;
      if (token is! Map<String, dynamic>) return null;
      final pair = Token.fromJson(token);
      await _authCacheManager.saveToken(pair);
      return pair.accessToken;
    } on DioException catch (e) {
      if (_isRefreshRejected(e.response?.statusCode)) return null;
      rethrow;
    }
  }

  /// Tekrar deneme seçenekleri: yeni Bearer + FormData klonu (akış bir kez okunur).
  static Future<RequestOptions> _retryOptions(
    RequestOptions options,
    String token,
  ) async {
    Object? data = options.data;
    if (data is FormData) {
      data = data.clone();
    }
    return options.copyWith(
      data: data,
      headers: Map<String, dynamic>.from(options.headers)
        ..['Authorization'] = 'Bearer $token',
      extra: Map<String, dynamic>.from(options.extra)..[_retriedKey] = true,
    );
  }

  /// Yalnızca sunucunun açık reddi oturumu bitirir (`REFRESH_REUSED`,
  /// `UNAUTHENTICATED`, hesap silinmiş vb.).
  static bool _isRefreshRejected(int? status) =>
      status == 400 || status == 401 || status == 403 || status == 410;

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
