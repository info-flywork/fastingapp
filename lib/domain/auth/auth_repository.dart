import 'package:fastingapp/core/managers/auth_cache_manager.dart';
import 'package:fastingapp/core/managers/shared_pref_manager.dart';
import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/core/utils/enum/auth_provider_type.dart';
import 'package:fastingapp/core/utils/enum/request_type.dart';
import 'package:fastingapp/data/model/auth/auth_register_request.dart';
import 'package:fastingapp/data/model/auth/auth_response.dart';
import 'package:fastingapp/domain/auth/auth_exception.dart';

/// Login, register, guest, refresh token ve profil işleri. (Doküman 7)
final class AuthRepository {
  const AuthRepository(
    this._networkManager,
    this._authCacheManager,
    this._sharedPrefManager,
  );

  final NetworkManager _networkManager;
  final AuthCacheManager _authCacheManager;
  final SharedPrefManager _sharedPrefManager;

  /// Sosyal giriş ve kayıt.
  Future<AuthResponse> login({
    required AuthProviderType providerType,
    required String token,
    String? deviceId,
  }) async {
    final requestData = AuthRegisterRequest(
      provider: providerType.value,
      idToken: token,
      deviceId: deviceId,
    ).toJson();

    final result = await _networkManager.send<AuthResponse>(
      path: '/auth/register',
      method: RequestType.post,
      data: requestData,
      parserModel: AuthResponse.fromJson,
    );

    if (result == null) throw AuthException.emptyResponse();

    final token0 = result.token;
    final user0 = result.user;
    if (token0 != null) await _authCacheManager.saveToken(token0);
    if (user0 != null) await _authCacheManager.saveUser(user0);

    return result;
  }

  Future<void> logout() => _authCacheManager.clearAll();

  Future<bool> isAuthenticated() async {
    final token = await _authCacheManager.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  bool isFirstLaunch() => _sharedPrefManager.isFirstLaunch;

  Future<void> completeFirstLaunch() =>
      _sharedPrefManager.setFirstLaunchDone();
}
