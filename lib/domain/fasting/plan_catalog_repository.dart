import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/core/utils/enum/request_type.dart';
import 'package:fastingapp/domain/fasting/weekly_schedule.dart';

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
  final Map<String, PlanCatalogDetail> _details = {};
  Future<void>? _loading;

  bool get isLoaded => _entries.isNotEmpty;

  PlanCatalogEntry? entry(String? code) => code == null ? null : _entries[code];

  /// `GET /catalog/plans/:code`. Örnek pencere ve haftalık şablon burada.
  /// Liste yanıtı yetmezse detay ekranı bunu kullanır. Hata → null.
  Future<PlanCatalogDetail?> detail(String code) async {
    final cached = _details[code];
    if (cached != null) return cached;
    try {
      final result = await _network.send<PlanCatalogDetail>(
        path: '/catalog/plans/$code',
        method: RequestType.get,
        parserModel: PlanCatalogDetail.fromJson,
      );
      if (result == null) return null;
      _details[code] = result;
      return result;
    } on Object {
      return null;
    }
  }

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
    this.fastHours,
    this.eatHours,
    this.defaultTiming,
    this.defaultEatStart,
    this.scheduleType,
  });

  final String code;
  final bool isPremium;
  final bool requiresSafetyAck;

  /// Günlük planda oruç / yeme saati. Haftalık planda null olabilir.
  final int? fastHours;
  final int? eatHours;

  /// `skipBreakfast` veya `skip_breakfast`. Katalogdaki varsayılan zamanlama.
  final String? defaultTiming;

  /// Varsayılan zamanlamanın yeme başlangıcı (`HH:mm`).
  final String? defaultEatStart;
  final String? scheduleType;
}

/// `GET /catalog/plans/:code` — liste özeti + örnek pencere + haftalık şablon.
final class PlanCatalogDetail implements BaseModel<PlanCatalogDetail> {
  const PlanCatalogDetail({
    required this.code,
    this.fastHours,
    this.eatHours,
    this.defaultTiming,
    this.defaultEatStart,
    this.scheduleType,
    this.exampleStart,
    this.exampleEnd,
    this.weeklyTemplate = const [],
  });

  factory PlanCatalogDetail.fromJson(Map<String, dynamic> json) {
    final window = json['exampleWindow'];
    final weekly = json['weeklyTemplate'];
    return PlanCatalogDetail(
      code: json['code'] as String? ?? '',
      fastHours: (json['fastHours'] as num?)?.toInt(),
      eatHours: (json['eatHours'] as num?)?.toInt(),
      defaultTiming: json['defaultTiming'] as String?,
      defaultEatStart: json['defaultEatStart'] as String?,
      scheduleType: json['scheduleType'] as String?,
      exampleStart: window is Map ? window['start'] as String? : null,
      exampleEnd: window is Map ? window['end'] as String? : null,
      weeklyTemplate: weekly is List
          ? [
              for (final day in weekly.whereType<Map<String, dynamic>>())
                WeeklyDay.fromJson(day),
            ]
          : const [],
    );
  }

  final String code;
  final int? fastHours;
  final int? eatHours;
  final String? defaultTiming;
  final String? defaultEatStart;
  final String? scheduleType;
  final String? exampleStart;
  final String? exampleEnd;
  final List<WeeklyDay> weeklyTemplate;

  @override
  PlanCatalogDetail fromJson(Map<String, dynamic> json) =>
      PlanCatalogDetail.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
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
            fastHours: (p['fastHours'] as num?)?.toInt(),
            eatHours: (p['eatHours'] as num?)?.toInt(),
            defaultTiming: p['defaultTiming'] as String?,
            defaultEatStart: p['defaultEatStart'] as String?,
            scheduleType: p['scheduleType'] as String?,
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
