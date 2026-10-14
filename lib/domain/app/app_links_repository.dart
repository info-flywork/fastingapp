import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/core/utils/enum/request_type.dart';

/// Yasal metin adresleri ve destek e-postası (`GET /app/config` → `legal`,
/// `support`). Adresler sunucuda; uygulama güncellemesi gerekmeden değişir.
/// Oturumsuz da çağrılabilir (giriş ekranı).
final class AppLinksRepository {
  AppLinksRepository(this._network);

  final NetworkManager _network;
  AppLinks? _cached;
  Future<AppLinks>? _loading;

  AppLinks? get cached => _cached;

  Future<AppLinks> get() {
    final cached = _cached;
    if (cached != null) return Future.value(cached);
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<AppLinks> _load() async {
    try {
      final result = await _network.send<AppLinks>(
        path: '/app/config',
        method: RequestType.get,
        parserModel: AppLinks.fromJson,
      );
      return _cached = result ?? const AppLinks();
    } on Object {
      return const AppLinks();
    }
  }
}

final class AppLinks implements BaseModel<AppLinks> {
  const AppLinks({this.termsUrl, this.privacyUrl, this.supportEmail});

  factory AppLinks.fromJson(Map<String, dynamic> json) {
    final legal = json['legal'];
    final support = json['support'];
    String? str(Object? map, String key) {
      if (map is! Map<String, dynamic>) return null;
      final v = map[key];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    return AppLinks(
      termsUrl: str(legal, 'termsUrl'),
      privacyUrl: str(legal, 'privacyUrl'),
      supportEmail: str(support, 'email'),
    );
  }

  final String? termsUrl;
  final String? privacyUrl;
  final String? supportEmail;

  @override
  AppLinks fromJson(Map<String, dynamic> json) => AppLinks.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}
