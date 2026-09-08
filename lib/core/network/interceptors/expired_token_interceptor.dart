import 'package:dio/dio.dart';
import 'package:fastingapp/core/managers/auth_cache_manager.dart';
import 'package:fastingapp/domain/auth/auth_repository.dart';

/// 401 (expired token) durumunda refresh dener ve isteği tekrar eder.
///
/// [AuthRepository], DI'daki döngüyü (Dio → AuthRepository → NetworkManager →
/// Dio) kırmak için lazy provider ile alınır.
///
/// İskelet: refresh + retry akışının detayı proje API'sine göre doldurulur.
final class ExpiredTokenInterceptor extends Interceptor {
  ExpiredTokenInterceptor(this._authCacheManager, this._authRepository);

  // İskelet aşamasında refresh akışı henüz kullanılmıyor.
  // ignore: unused_field
  final AuthCacheManager _authCacheManager;
  // ignore: unused_field
  final AuthRepository Function() _authRepository;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = err.response?.statusCode == 401;
    if (!isUnauthorized) {
      handler.next(err);
      return;
    }

    // TODO(team): refresh token → yeni access token → isteği retry et.
    // final refreshed = await _authRepository().refreshToken();
    // if (refreshed) { ...retry... }

    handler.next(err);
  }
}
