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
    this.riskStartsAt,
    this.riskEndsAt,
    this.curve = const [],
    this.days = const {},
    this.fastStartsAt,
    this.fastEndsAt,
  });

  factory FastForecast.fromJson(Map<String, dynamic> json) {
    final f = json['forecast'] as Map<String, dynamic>? ?? const {};
    final fast = f['fast'] as Map<String, dynamic>?;
    final rawCurve = f['curve'];
    final rawDays = f['days'];
    DateTime? at(Object? v) =>
        v is String ? DateTime.tryParse(v)?.toLocal() : null;
    return FastForecast(
      available: f['available'] as bool? ?? false,
      successChance: (f['successChance'] as num?)?.toDouble(),
      toughestAt: at(f['toughestAt']),
      riskStartsAt: at(f['riskStartsAt']),
      riskEndsAt: at(f['riskEndsAt']),
      curve: _curveOf(rawCurve),
      days: {
        if (rawDays is Map<String, dynamic>)
          for (final e in rawDays.entries)
            if (e.value is Map<String, dynamic>)
              e.key: ForecastSlice.fromJson(e.value as Map<String, dynamic>),
      },
      fastStartsAt: at(fast?['startsAt']),
      fastEndsAt: at(fast?['endsAt']),
    );
  }

  final bool available;

  /// 0–1
  final double? successChance;
  final DateTime? toughestAt;
  final DateTime? riskStartsAt;
  final DateTime? riskEndsAt;

  /// Orucun başından bitişine zorluk, 0–1. Boş ya da düzse kayıt yok.
  final List<double> curve;

  /// `easy` | `moderate` | `hard` — o tür günlerin kendi eğrisi.
  final Map<String, ForecastSlice> days;
  final DateTime? fastStartsAt;
  final DateTime? fastEndsAt;

  @override
  FastForecast fromJson(Map<String, dynamic> json) =>
      FastForecast.fromJson(json);

  ForecastSlice get overall => ForecastSlice(
    toughestAt: toughestAt,
    riskStartsAt: riskStartsAt,
    riskEndsAt: riskEndsAt,
    curve: curve,
  );

  /// Seçilen günün kaydı varsa o eğri. Bugünün sınıfı boşsa genel eğri.
  ForecastSlice sliceFor(String day, {required bool isToday}) {
    final slice = days[day];
    if (slice != null && slice.hasSignal) return slice;
    if (isToday) return overall;
    return slice ?? const ForecastSlice();
  }

  static List<double> _curveOf(Object? raw) => raw is List
      ? [for (final v in raw) if (v is num) v.toDouble()]
      : const [];

  @override
  Map<String, dynamic> toJson() => {'available': available};
}

/// Bir gün sınıfının eğrisi ve tepe saatleri.
final class ForecastSlice {
  const ForecastSlice({
    this.toughestAt,
    this.riskStartsAt,
    this.riskEndsAt,
    this.curve = const [],
  });

  factory ForecastSlice.fromJson(Map<String, dynamic> json) {
    DateTime? at(Object? v) =>
        v is String ? DateTime.tryParse(v)?.toLocal() : null;
    return ForecastSlice(
      toughestAt: at(json['toughestAt']),
      riskStartsAt: at(json['riskStartsAt']),
      riskEndsAt: at(json['riskEndsAt']),
      curve: FastForecast._curveOf(json['curve']),
    );
  }

  final DateTime? toughestAt;
  final DateTime? riskStartsAt;
  final DateTime? riskEndsAt;
  final List<double> curve;

  bool get hasSignal => curve.any((v) => v > 0);
}
