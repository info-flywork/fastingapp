import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/core/utils/enum/request_type.dart';

/// `GET /v1/fasts/mochi-plan` — Mochi'nin bugünkü önerisi.
/// Aktif orucun süresi değildir.
final class MochiPlanRepository {
  const MochiPlanRepository(this._networkManager);

  final NetworkManager _networkManager;

  Future<MochiDailyPlan> getPlan() async {
    final result = await _networkManager.send<MochiDailyPlan>(
      path: '/fasts/mochi-plan',
      method: RequestType.get,
      parserModel: MochiDailyPlan.fromJson,
    );
    return result ?? MochiDailyPlan.fallback();
  }
}

final class MochiDailyPlan implements BaseModel<MochiDailyPlan> {
  const MochiDailyPlan({
    required this.fastHours,
    required this.eatHours,
    required this.startsAt,
    required this.endsAt,
    required this.reason,
    required this.settled,
    this.insight,
  });

  /// Sunucu yanıt vermezse: kayıtlı planın kopyası değil, sakin bir 14:10.
  factory MochiDailyPlan.fallback() {
    final now = DateTime.now();
    final starts = DateTime(now.year, now.month, now.day, 20);
    return MochiDailyPlan(
      fastHours: 14,
      eatHours: 10,
      startsAt: starts,
      endsAt: starts.add(const Duration(hours: 14)),
      reason: 'gentle_start',
      settled: true,
    );
  }

  factory MochiDailyPlan.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'] as Map<String, dynamic>? ?? const {};
    DateTime at(Object? value) {
      if (value is String) {
        return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
      }
      return DateTime.now();
    }

    final fast = ((plan['fastHours'] as num?)?.toInt() ?? 14).clamp(12, 20);
    final eat = ((plan['eatHours'] as num?)?.toInt() ?? (24 - fast)).clamp(
      4,
      12,
    );
    return MochiDailyPlan(
      fastHours: fast,
      eatHours: eat,
      startsAt: at(plan['startsAt']),
      endsAt: at(plan['endsAt']),
      insight: plan['insight'] as String?,
      reason: plan['reason'] as String? ?? 'steady',
      settled: plan['settled'] as bool? ?? true,
    );
  }

  final int fastHours;
  final int eatHours;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? insight;
  final String reason;

  /// false: açıklama hâlâ arka planda hazırlanıyor.
  final bool settled;

  @override
  MochiDailyPlan fromJson(Map<String, dynamic> json) =>
      MochiDailyPlan.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {
    'fastHours': fastHours,
    'eatHours': eatHours,
    'reason': reason,
    'settled': settled,
    'insight': insight,
  };
}
