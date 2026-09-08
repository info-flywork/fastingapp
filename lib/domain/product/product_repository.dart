import 'package:fastingapp/core/managers/shared_pref_manager.dart';
import 'package:fastingapp/core/network/network_manager.dart';

/// Ürün/katalog verisi ve cache. (Doküman 7)
class ProductRepository {
  const ProductRepository(this._networkManager, this._sharedPrefManager);

  // İskelet: katalog metodları proje API'sine göre eklenir.
  // ignore: unused_field
  final NetworkManager _networkManager;
  // ignore: unused_field
  final SharedPrefManager _sharedPrefManager;
}
