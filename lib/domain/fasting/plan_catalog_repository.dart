import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/core/utils/enum/request_type.dart';

/// Plan kataloğu (`GET /v1/catalog/plans`): planın premium olup olmadığı ve
/// güvenlik onayı isteyip istemediği sunucudan. Kart tasarımı (satırlar,
/// çipler) istemcide kalır; bu bayraklar kartlara uygulanır.
///
/// Açılışta bir kez yüklenir; yüklenemezse çağıranlar yerel varsayılanı
/// kullanır.
final class PlanCatalogRepository {
  PlanCatalogRepository(this._network) {
    instance = this;
  }

  /// Model sınıflarından (ör. `PlansCardData`) DI'sız erişim için.
  static PlanCatalogRepository? instance;

  final NetworkManager _network;
  Map<String, PlanCatalogEntry> _entries = const {};
  Future<void>? _loading;

  bool get isLoaded => _entries.isNotEmpty;

  PlanCatalogEntry? entry(String? code) => code == null ? null : _entries[code];

  /// Yüklenmediyse yükler (eşzamanlı çağrılar tek isteğe katlanır).
  Future<void> ensureLoaded() {
    if (isLoaded) return Future.value();
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<void> _load() async {
    try {
      final result = await _network.send<_PlanCatalog>(
        path: '/catalog/plans',
        method: RequestType.get,
        parserModel: _PlanCatalog.fromJson,
      );
      if (result != null) _entries = result.entries;
    } on Object {
      // Yerel varsayılanlar kullanılır.
    }
  }
}

final class PlanCatalogEntry {
  const PlanCatalogEntry({
    required this.code,
    required this.isPremium,
    required this.requiresSafetyAck,
  });

  final String code;
  final bool isPremium;
  final bool requiresSafetyAck;
}

final class _PlanCatalog implements BaseModel<_PlanCatalog> {
  const _PlanCatalog(this.entries);

  factory _PlanCatalog.fromJson(Map<String, dynamic> json) {
    final entries = <String, PlanCatalogEntry>{};
    final groups = json['groups'];
    if (groups is List) {
      for (final group in groups.whereType<Map<String, dynamic>>()) {
        final plans = group['plans'];
        if (plans is! List) continue;
        for (final p in plans.whereType<Map<String, dynamic>>()) {
          final code = p['code'] as String?;
          if (code == null) continue;
          entries[code] = PlanCatalogEntry(
            code: code,
            isPremium: p['isPremium'] as bool? ?? false,
            requiresSafetyAck: p['requiresSafetyAck'] as bool? ?? false,
          );
        }
      }
    }
    return _PlanCatalog(entries);
  }

  final Map<String, PlanCatalogEntry> entries;

  @override
  _PlanCatalog fromJson(Map<String, dynamic> json) =>
      _PlanCatalog.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}
