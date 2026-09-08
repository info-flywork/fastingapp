import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/core/utils/enum/request_type.dart';
import 'package:fastingapp/data/model/user/user_progress.dart';
import 'package:fastingapp/domain/progress/progress_exception.dart';

/// Kullanıcı ilerleme verisi. (Doküman 7 / 16)
class ProgressRepository {
  const ProgressRepository(this._networkManager);

  final NetworkManager _networkManager;

  Future<UserProgress> getProgress() async {
    final result = await _networkManager.send<UserProgress>(
      path: '/user/progress',
      method: RequestType.get,
      parserModel: UserProgress.fromJson,
    );
    if (result == null) throw ProgressException.notFound();
    return result;
  }
}
