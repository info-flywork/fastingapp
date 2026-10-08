import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/core/utils/enum/request_type.dart';
import 'package:fastingapp/data/model/user/home_summary.dart';
import 'package:fastingapp/data/model/user/user.dart';

/// Profil güncelleme, premium sync, hesap silme. (Doküman 7)
final class UserRepository {
  const UserRepository(this._networkManager);

  final NetworkManager _networkManager;

  Future<User> getCurrentUser() async {
    final result = await _networkManager.send<User>(
      path: '/user/me',
      method: RequestType.get,
      parserModel: User.fromJson,
    );
    return result ?? const User();
  }

  /// Ana sayfa özeti (tek çağrı).
  Future<HomeSummary> getSummary() async {
    final result = await _networkManager.send<HomeSummary>(
      path: '/user/summary',
      method: RequestType.get,
      parserModel: HomeSummary.fromJson,
    );
    if (result == null) throw StateError('Özet boş');
    return result;
  }

  Future<bool> isPremium() async {
    final user = await getCurrentUser();
    return user.isPremium;
  }

  Future<void> saveAnsweredQuestions({required int level}) async {
    await _networkManager.send<User>(
      path: '/user/onboarding',
      method: RequestType.patch,
      data: {'level': level},
      parserModel: User.fromJson,
    );
  }
}
