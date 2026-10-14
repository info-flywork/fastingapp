import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/core/utils/enum/request_type.dart';

/// Mochi World (`GET /v1/world`): bölge ilerlemeleri, sağlık, hafta.
/// Son yanıt bellekte: sekme tekrar açılınca ada hemen çizilir.
final class WorldRepository {
  WorldRepository(this._network);

  final NetworkManager _network;

  WorldData? cached;

  Future<WorldData> get() async {
    final result = await _network.send<WorldData>(
      path: '/world',
      method: RequestType.get,
      parserModel: WorldData.fromJson,
    );
    if (result == null) throw StateError('Dünya yüklenemedi');
    return cached = result;
  }

  void clear() => cached = null;
}

final class WorldData implements BaseModel<WorldData> {
  const WorldData({
    required this.level,
    required this.health,
    required this.worldProgress,
    required this.zones,
    required this.week,
  });

  factory WorldData.fromJson(Map<String, dynamic> json) {
    final zonesRaw = json['zones'];
    final weekRaw = json['week'];
    return WorldData(
      level: (json['level'] as num?)?.toInt() ?? 1,
      health: json['health'] as String? ?? 'thriving',
      worldProgress: (json['worldProgress'] as num?)?.toDouble() ?? 0,
      zones: {
        if (zonesRaw is List)
          for (final z in zonesRaw.whereType<Map<String, dynamic>>())
            z['zone'] as String? ?? '': WorldZone.fromJson(z),
      },
      week: weekRaw is List
          ? [
              for (final d in weekRaw.whereType<Map<String, dynamic>>())
                (
                  date: d['date'] as String? ?? '',
                  fastedMinutes: (d['fastedMinutes'] as num?)?.toInt() ?? 0,
                ),
            ]
          : const [],
    );
  }

  /// Kullanıcı seviyesi (XP).
  final int level;

  /// `thriving` | `wilting` | `drought`
  final String health;
  final double worldProgress;

  /// `forest` | `lake` | `summit` | `garden` → ilerleme.
  final Map<String, WorldZone> zones;

  /// Pzt → Paz oruç dakikaları (`yyyy-MM-dd`).
  final List<({String date, int fastedMinutes})> week;

  @override
  WorldData fromJson(Map<String, dynamic> json) => WorldData.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}

final class WorldZone {
  const WorldZone({
    required this.current,
    required this.level,
    this.nextThreshold,
    this.thresholds = const [],
  });

  factory WorldZone.fromJson(Map<String, dynamic> json) {
    final t = json['thresholds'];
    return WorldZone(
      current: (json['current'] as num?)?.toDouble() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 0,
      nextThreshold: (json['nextThreshold'] as num?)?.toDouble(),
      thresholds: t is List
          ? t.whereType<num>().map((e) => e.toDouble()).toList()
          : const [],
    );
  }

  final double current;

  /// 0–4 (sunucu eşiklerine göre).
  final int level;

  /// Sonraki seviyenin eşiği; son seviyedeyse null.
  final double? nextThreshold;
  final List<double> thresholds;

  /// Hedef: sonraki eşik, son seviyede en büyük eşik.
  double get goal =>
      nextThreshold ?? (thresholds.isEmpty ? current : thresholds.last);
}
