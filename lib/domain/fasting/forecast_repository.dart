import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/core/utils/enum/request_type.dart';

/// `GET /v1/fasts/forecast` — bugünkü oruç tahmini (backend doküman 04 §6).
final class ForecastRepository {
  const ForecastRepository(this._networkManager);

  final NetworkManager _networkManager;

  Future<FastForecast> getForecast() async {
    final result = await _networkManager.send<FastForecast>(
      path: '/fasts/forecast',
      method: RequestType.get,
      parserModel: FastForecast.fromJson,
    );
    return result ?? const FastForecast(available: false);
  }
}

/// Veri azsa [available] false (kart gizlenir).
final class FastForecast implements BaseModel<FastForecast> {
  const FastForecast({
    required this.available,
    this.successChance,
    this.toughestAt,
    this.fastStartsAt,
    this.fastEndsAt,
  });

  factory FastForecast.fromJson(Map<String, dynamic> json) {
    final f = json['forecast'] as Map<String, dynamic>? ?? const {};
    final fast = f['fast'] as Map<String, dynamic>?;
    DateTime? at(Object? v) =>
        v is String ? DateTime.tryParse(v)?.toLocal() : null;
    return FastForecast(
      available: f['available'] as bool? ?? false,
      successChance: (f['successChance'] as num?)?.toDouble(),
      toughestAt: at(f['toughestAt']),
      fastStartsAt: at(fast?['startsAt']),
      fastEndsAt: at(fast?['endsAt']),
    );
  }

  final bool available;

  /// 0–1
  final double? successChance;
  final DateTime? toughestAt;
  final DateTime? fastStartsAt;
  final DateTime? fastEndsAt;

  @override
  FastForecast fromJson(Map<String, dynamic> json) =>
      FastForecast.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {'available': available};
}
