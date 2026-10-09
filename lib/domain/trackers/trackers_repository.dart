import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/core/utils/enum/request_type.dart';
import 'package:fastingapp/data/model/auth/no_content.dart';
import 'package:uuid/uuid.dart';

/// Su, kilo, adım, uyku (`/v1/water`, `/weights`, `/steps`, `/sleep`).
/// Bellek içi su günü cache: tekrar açılışta boş flash yok.
final class TrackersRepository {
  TrackersRepository(this._network);

  final NetworkManager _network;
  static const _uuid = Uuid();

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // ── Su ──

  WaterDay? _waterDayCache;
  String? _waterDayCacheKey;

  /// Bellekteki gün özeti; tekrar açılışta boş flash olmasın.
  WaterDay? cachedWaterDay({DateTime? date}) {
    final key = _ymd(date ?? DateTime.now());
    if (_waterDayCacheKey != key) return null;
    return _waterDayCache;
  }

  void _storeWaterDay(WaterDay day, {DateTime? date}) {
    _waterDayCache = day;
    _waterDayCacheKey = _ymd(date ?? day.date);
  }

  void invalidateWaterDay() {
    _waterDayCache = null;
    _waterDayCacheKey = null;
  }

  /// `PATCH /user/goals` — su (`waterGoalMl` 500–6000, `glassSizeMl`
  /// 50–2000, `customGlassSizes`), adım (`stepsGoal`), uyku (`sleepGoalMin`,
  /// `bedtime`, `wakeTime`), beslenme (`kcalGoal`, `proteinGoalG`…).
  Future<void> updateGoals(Map<String, dynamic> fields) async {
    await _network.send<NoContent>(
      path: '/user/goals',
      method: RequestType.patch,
      data: fields,
      parserModel: NoContent.fromJson,
    );
  }

  Future<UserTrackerSettings> getSettings() async {
    final result = await _network.send<UserTrackerSettings>(
      path: '/user/settings',
      method: RequestType.get,
      parserModel: UserTrackerSettings.fromJson,
    );
    return result ?? const UserTrackerSettings();
  }

  /// `PATCH /user/settings` — kısmi (ör. `notifications.water`).
  Future<void> updateSettings(Map<String, dynamic> fields) async {
    await _network.send<NoContent>(
      path: '/user/settings',
      method: RequestType.patch,
      data: fields,
      parserModel: NoContent.fromJson,
    );
  }

  /// `PATCH /user/me` — su birimi (`ml` | `oz`).
  Future<void> updateWaterUnit(String unit) async {
    await _network.send<NoContent>(
      path: '/user/me',
      method: RequestType.patch,
      data: {
        'units': {'water': unit},
      },
      parserModel: NoContent.fromJson,
    );
  }

  Future<WaterDay> getWaterDay({DateTime? date, bool force = true}) async {
    final key = _ymd(date ?? DateTime.now());
    if (!force && _waterDayCache != null && _waterDayCacheKey == key) {
      return _waterDayCache!;
    }
    final result = await _network.send<WaterDay>(
      path: '/water/day',
      method: RequestType.get,
      queryParameters: {if (date != null) 'date': _ymd(date)},
      parserModel: WaterDay.fromJson,
    );
    final day = result ?? WaterDay.empty(date ?? DateTime.now());
    _storeWaterDay(day, date: date);
    return day;
  }

  Future<WaterDay> addWater({
    required int amountMl,
    String? id,
    DateTime? loggedAt,
    String source = 'app',
  }) async {
    final result = await _network.send<WaterDay>(
      path: '/water',
      method: RequestType.post,
      data: {
        'id': id ?? _uuid.v7(),
        'amountMl': amountMl,
        if (loggedAt != null) 'loggedAt': loggedAt.toUtc().toIso8601String(),
        'source': source,
      },
      parserModel: WaterDay.fromJson,
    );
    if (result == null) throw StateError('Su kaydı başarısız');
    _storeWaterDay(result);
    return result;
  }

  String newWaterEntryId() => _uuid.v7();

  Future<WaterDay> deleteWaterEntry(String id) async {
    final result = await _network.send<WaterDay>(
      path: '/water/$id',
      method: RequestType.delete,
      parserModel: WaterDay.fromJson,
    );
    if (result == null) throw StateError('Su kaydı silinemedi');
    _storeWaterDay(result);
    return result;
  }

  // ── Kilo ──

  Future<WeightSummary> getWeightSummary() async {
    final result = await _network.send<WeightSummary>(
      path: '/weights/summary',
      method: RequestType.get,
      parserModel: WeightSummary.fromJson,
    );
    return result ?? const WeightSummary();
  }

  Future<WeightChart> getWeightChart(String range) async {
    final result = await _network.send<WeightChart>(
      path: '/weights/chart',
      method: RequestType.get,
      queryParameters: {'range': range},
      parserModel: WeightChart.fromJson,
    );
    return result ?? WeightChart.empty(range: range);
  }

  /// Kilo kaydı oluşturur. Özet için ayrı [getWeightSummary] çağırın —
  /// UI'yı bloklamamak için burada ikinci istek yok.
  Future<void> createWeight({
    required double weightKg,
    DateTime? recordedAt,
  }) async {
    await _network.send<_WeightEntryEnvelope>(
      path: '/weights',
      method: RequestType.post,
      data: {
        'id': _uuid.v7(),
        'weightKg': weightKg,
        if (recordedAt != null)
          'recordedAt': recordedAt.toUtc().toIso8601String(),
      },
      parserModel: _WeightEntryEnvelope.fromJson,
    );
  }

  Future<WeightSummary> setWeightGoal(double goalWeightKg) async {
    final result = await _network.send<WeightSummary>(
      path: '/weights/goal',
      method: RequestType.patch,
      data: {'goalWeightKg': goalWeightKg},
      parserModel: WeightSummary.fromJson,
    );
    if (result == null) throw StateError('Hedef güncellenemedi');
    return result;
  }

  // ── Adım ──

  Future<StepsRange> getSteps({String range = 'week', DateTime? date}) async {
    final result = await _network.send<StepsRange>(
      path: '/steps',
      method: RequestType.get,
      queryParameters: {'range': range, if (date != null) 'date': _ymd(date)},
      parserModel: StepsRange.fromJson,
    );
    return result ?? StepsRange.empty(range: range);
  }

  Future<StepsRange> putSteps({
    required DateTime date,
    required int steps,
  }) async {
    final result = await _network.send<StepsRange>(
      path: '/steps/${_ymd(date)}',
      method: RequestType.put,
      data: {'steps': steps, 'source': 'manual'},
      parserModel: StepsRange.fromJson,
    );
    if (result == null) throw StateError('Adım kaydı başarısız');
    return result;
  }

  // ── Uyku ──

  Future<SleepSummary> getSleepSummary({DateTime? date}) async {
    final result = await _network.send<SleepSummary>(
      path: '/sleep/summary',
      method: RequestType.get,
      queryParameters: {if (date != null) 'date': _ymd(date)},
      parserModel: SleepSummary.fromJson,
    );
    return result ?? SleepSummary.empty(date ?? DateTime.now());
  }
}

/// `GET/PATCH /user/settings` — su hatırlatıcı için gereken alanlar.
final class UserTrackerSettings implements BaseModel<UserTrackerSettings> {
  const UserTrackerSettings({
    this.waterNotifications = false,
    this.waterReminderIntervalMin = 120,
  });

  factory UserTrackerSettings.fromJson(Map<String, dynamic> json) {
    final notifications = json['notifications'];
    final map = notifications is Map<String, dynamic> ? notifications : null;
    return UserTrackerSettings(
      waterNotifications: map?['water'] as bool? ?? false,
      waterReminderIntervalMin:
          (json['waterReminderIntervalMin'] as num?)?.toInt() ?? 120,
    );
  }

  final bool waterNotifications;
  final int waterReminderIntervalMin;

  @override
  UserTrackerSettings fromJson(Map<String, dynamic> json) =>
      UserTrackerSettings.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {
    'waterReminderIntervalMin': waterReminderIntervalMin,
  };
}

final class WaterDay implements BaseModel<WaterDay> {
  const WaterDay({
    required this.date,
    required this.totalMl,
    required this.goalMl,
    required this.entries,
    this.progress,
    this.goalReached = false,
    this.glassSizeMl = 300,
  });

  factory WaterDay.empty(DateTime date) =>
      WaterDay(date: date, totalMl: 0, goalMl: 2500, entries: const []);

  factory WaterDay.fromJson(Map<String, dynamic> json) {
    final entriesRaw = json['entries'];
    return WaterDay(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      totalMl: (json['totalMl'] as num?)?.toInt() ?? 0,
      goalMl: (json['goalMl'] as num?)?.toInt() ?? 2500,
      progress: (json['progress'] as num?)?.toDouble(),
      goalReached: json['goalReached'] as bool? ?? false,
      glassSizeMl: (json['glassSizeMl'] as num?)?.toInt() ?? 300,
      entries: entriesRaw is List
          ? entriesRaw
                .whereType<Map<String, dynamic>>()
                .map(WaterEntry.fromJson)
                .toList()
          : const [],
    );
  }

  final DateTime date;
  final int totalMl;
  final int goalMl;
  final double? progress;
  final bool goalReached;
  final int glassSizeMl;
  final List<WaterEntry> entries;

  @override
  WaterDay fromJson(Map<String, dynamic> json) => WaterDay.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {'date': date.toIso8601String()};
}

final class WaterEntry {
  const WaterEntry({
    required this.id,
    required this.amountMl,
    required this.loggedAt,
  });

  factory WaterEntry.fromJson(Map<String, dynamic> json) => WaterEntry(
    id: json['id'] as String? ?? '',
    amountMl: (json['amountMl'] as num?)?.toInt() ?? 0,
    loggedAt:
        DateTime.tryParse(json['loggedAt'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
  );

  final String id;
  final int amountMl;
  final DateTime loggedAt;
}

final class WeightSummary implements BaseModel<WeightSummary> {
  const WeightSummary({
    this.currentKg,
    this.startKg,
    this.goalKg,
    this.progress,
    this.changeKg,
    this.bmi,
    this.bmiCategory,
    this.bmiBand,
    this.heightCm,
    this.targetDate,
  });

  factory WeightSummary.fromJson(Map<String, dynamic> json) => WeightSummary(
    currentKg: (json['currentKg'] as num?)?.toDouble(),
    startKg: (json['startKg'] as num?)?.toDouble(),
    goalKg: (json['goalKg'] as num?)?.toDouble(),
    progress: (json['progress'] as num?)?.toDouble(),
    changeKg: (json['changeKg'] as num?)?.toDouble(),
    bmi: (json['bmi'] as num?)?.toDouble(),
    bmiCategory: json['bmiCategory'] as String?,
    bmiBand: json['bmiBand'] as String?,
    heightCm: (json['heightCm'] as num?)?.toDouble(),
    targetDate: json['targetDate'] as String?,
  );

  final double? currentKg;
  final double? startKg;
  final double? goalKg;
  final double? progress;
  final double? changeKg;
  final double? bmi;
  final String? bmiCategory;
  final String? bmiBand;
  final double? heightCm;
  final String? targetDate;

  bool get hasData => currentKg != null;

  @override
  WeightSummary fromJson(Map<String, dynamic> json) =>
      WeightSummary.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}

final class WeightChart implements BaseModel<WeightChart> {
  const WeightChart({
    required this.range,
    required this.buckets,
    this.goalKg,
    this.yMin,
    this.yMax,
  });

  factory WeightChart.empty({String range = 'day'}) =>
      WeightChart(range: range, buckets: const []);

  factory WeightChart.fromJson(Map<String, dynamic> json) {
    final axis = json['yAxis'];
    final axisMap = axis is Map<String, dynamic> ? axis : null;
    final bucketsRaw = json['buckets'];
    return WeightChart(
      range: json['range'] as String? ?? 'day',
      goalKg: (json['goalKg'] as num?)?.toDouble(),
      yMin: (axisMap?['min'] as num?)?.toDouble(),
      yMax: (axisMap?['max'] as num?)?.toDouble(),
      buckets: bucketsRaw is List
          ? bucketsRaw
                .whereType<Map<String, dynamic>>()
                .map(WeightChartBucket.fromJson)
                .toList()
          : const [],
    );
  }

  final String range;
  final double? goalKg;
  final double? yMin;
  final double? yMax;
  final List<WeightChartBucket> buckets;

  @override
  WeightChart fromJson(Map<String, dynamic> json) => WeightChart.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {'range': range};
}

final class WeightChartBucket {
  const WeightChartBucket({required this.label, this.weightKg});

  factory WeightChartBucket.fromJson(Map<String, dynamic> json) =>
      WeightChartBucket(
        label: json['label'] as String? ?? '',
        weightKg: (json['weightKg'] as num?)?.toDouble(),
      );

  final String label;
  final double? weightKg;
}

final class _WeightEntryEnvelope implements BaseModel<_WeightEntryEnvelope> {
  const _WeightEntryEnvelope();

  factory _WeightEntryEnvelope.fromJson(Map<String, dynamic> json) =>
      const _WeightEntryEnvelope();

  @override
  _WeightEntryEnvelope fromJson(Map<String, dynamic> json) =>
      _WeightEntryEnvelope.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}

final class StepsRange implements BaseModel<StepsRange> {
  const StepsRange({required this.range, required this.days, this.goal = 8000});

  factory StepsRange.empty({String range = 'week'}) =>
      StepsRange(range: range, days: const []);

  factory StepsRange.fromJson(Map<String, dynamic> json) {
    final daysRaw = json['days'];
    return StepsRange(
      range: json['range'] as String? ?? 'week',
      goal: (json['goal'] as num?)?.toInt() ?? 8000,
      days: daysRaw is List
          ? daysRaw
                .whereType<Map<String, dynamic>>()
                .map(StepsDay.fromJson)
                .toList()
          : const [],
    );
  }

  final String range;
  final int goal;
  final List<StepsDay> days;

  @override
  StepsRange fromJson(Map<String, dynamic> json) => StepsRange.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {'range': range};
}

final class StepsDay {
  const StepsDay({
    required this.date,
    required this.steps,
    this.distanceKm = 0,
    this.kcal = 0,
    this.durationMin = 0,
    this.isFuture = false,
  });

  factory StepsDay.fromJson(Map<String, dynamic> json) => StepsDay(
    date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    steps: (json['steps'] as num?)?.toInt() ?? 0,
    distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
    kcal: (json['kcal'] as num?)?.toInt() ?? 0,
    durationMin: (json['durationMin'] as num?)?.toInt() ?? 0,
    isFuture: json['isFuture'] as bool? ?? false,
  );

  final DateTime date;
  final int steps;
  final double distanceKm;
  final int kcal;
  final int durationMin;
  final bool isFuture;
}

final class SleepSummary implements BaseModel<SleepSummary> {
  const SleepSummary({
    required this.date,
    this.lastNightMinutes,
    this.goalMin = 450,
    this.progress = 0,
    this.bedtime,
    this.wakeTime,
    this.weekMinutes = const [],
  });

  factory SleepSummary.empty(DateTime date) => SleepSummary(date: date);

  factory SleepSummary.fromJson(Map<String, dynamic> json) {
    final last = json['lastNight'];
    final lastMap = last is Map<String, dynamic> ? last : null;
    final schedule = json['schedule'];
    final scheduleMap = schedule is Map<String, dynamic> ? schedule : null;
    final weekRaw = json['week'];
    return SleepSummary(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      lastNightMinutes: (lastMap?['totalMinutes'] as num?)?.toInt(),
      goalMin: (json['goalMin'] as num?)?.toInt() ?? 450,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      bedtime: scheduleMap?['bedtime'] as String?,
      wakeTime: scheduleMap?['wakeTime'] as String?,
      weekMinutes: weekRaw is List
          ? weekRaw
                .whereType<Map<String, dynamic>>()
                .map((d) => (d['minutes'] as num?)?.toInt() ?? 0)
                .toList()
          : const [],
    );
  }

  final DateTime date;
  final int? lastNightMinutes;
  final int goalMin;
  final double progress;
  final String? bedtime;
  final String? wakeTime;
  final List<int> weekMinutes;

  bool get hasLastNight => lastNightMinutes != null && lastNightMinutes! > 0;

  @override
  SleepSummary fromJson(Map<String, dynamic> json) =>
      SleepSummary.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {'date': date.toIso8601String()};
}
