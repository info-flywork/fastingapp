import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/core/sync/data_sync.dart';
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

  /// Çıkış / hesap değişimi: kullanıcıya özel önbellekler.
  void clearSession() {
    invalidateWaterDay();
    _weightUnit = null;
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
    // Su hedefi / bardak değişti: önbellekteki gün eski hedefle açılmasın.
    if (fields.containsKey('waterGoalMl') ||
        fields.containsKey('glassSizeMl')) {
      invalidateWaterDay();
    }
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

  /// Su ekranı tercihleri: birim (`/user/me.units.water`), hatırlatma
  /// (`/user/settings.notifications.water`), özel bardaklar (`/user/goals`).
  Future<({String unit, bool notifications, List<int> customGlassSizes})>
  getWaterPrefs() async {
    final results = await Future.wait([
      _network.send<_RawMap>(
        path: '/user/me',
        method: RequestType.get,
        parserModel: _RawMap.new,
      ),
      getSettings(),
      _network.send<_RawMap>(
        path: '/user/goals',
        method: RequestType.get,
        parserModel: _RawMap.new,
      ),
    ]);
    final me = (results[0] as _RawMap?)?.json ?? const {};
    final settings = results[1] as UserTrackerSettings;
    final goals = (results[2] as _RawMap?)?.json ?? const {};
    final units = me['units'];
    final sizes = goals['customGlassSizes'];
    return (
      unit: (units is Map ? units['water'] as String? : null) ?? 'ml',
      notifications: settings.waterNotifications,
      customGlassSizes: sizes is List
          ? sizes.whereType<num>().map((e) => e.toInt()).toList()
          : <int>[],
    );
  }

  /// Kilo birimi (`kg` | `lb`, `GET /user/me` → `units.weight`); oturum
  /// içinde önbellekte. Önceden seçilen birim yok sayılıyor, hep kg açılıyordu.
  String? _weightUnit;

  Future<String> weightUnit() async {
    final cached = _weightUnit;
    if (cached != null) return cached;
    final me = await _network.send<_RawMap>(
      path: '/user/me',
      method: RequestType.get,
      parserModel: _RawMap.new,
    );
    final units = me?.json['units'];
    return _weightUnit =
        (units is Map ? units['weight'] as String? : null) ?? 'kg';
  }

  /// `GET /water/week` → `yyyy-MM-dd` → toplam ml (Pzt–Paz).
  Future<Map<String, int>> getWaterWeek() async {
    final result = await _network.send<_RawMap>(
      path: '/water/week',
      method: RequestType.get,
      parserModel: _RawMap.new,
    );
    final days = result?.json['days'];
    return {
      if (days is List)
        for (final d in days.whereType<Map<String, dynamic>>())
          if (d['isFuture'] != true && d['date'] is String)
            d['date'] as String: (d['totalMl'] as num?)?.toInt() ?? 0,
    };
  }

  /// `PATCH /user/me` — kilo birimi (`kg` | `lb`).
  Future<void> updateWeightUnit(String unit) async {
    final previous = _weightUnit;
    _weightUnit = unit;
    try {
      await _network.send<NoContent>(
        path: '/user/me',
        method: RequestType.patch,
        data: {
          'units': {'weight': unit},
        },
        parserModel: NoContent.fromJson,
      );
    } on Object {
      // Kaydedilmediyse uygulama da eski birimde kalsın.
      _weightUnit = previous;
      rethrow;
    }
    // Ana sayfa / oruç kartları birimi özetten okur.
    DataSync.afterWrite(profile: true);
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
    DataSync.afterWrite();
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

  /// `GET /weights` — son kayıtlar (yeniden eskiye).
  Future<List<WeightEntry>> listWeights({int limit = 30}) async {
    final result = await _network.send<_RawMap>(
      path: '/weights',
      method: RequestType.get,
      queryParameters: {'limit': limit},
      parserModel: _RawMap.new,
    );
    final items = result?.json['items'];
    return [
      if (items is List)
        for (final e in items.whereType<Map<String, dynamic>>())
          WeightEntry.fromJson(e),
    ];
  }

  /// `PATCH /weights/:id` (yanlış girilen değeri düzelt).
  Future<void> updateWeight(String id, double weightKg) async {
    await _network.send<_WeightEntryEnvelope>(
      path: '/weights/$id',
      method: RequestType.patch,
      data: {'weightKg': weightKg},
      parserModel: _WeightEntryEnvelope.fromJson,
    );
  }

  /// `DELETE /weights/:id`.
  Future<void> deleteWeight(String id) async {
    await _network.send<NoContent>(
      path: '/weights/$id',
      method: RequestType.delete,
      parserModel: NoContent.fromJson,
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

  /// `POST /steps/sync` — `source`: `appleHealth` | `googleFit`.
  Future<({int updated, int skipped})> syncSteps({
    required String source,
    required List<({String date, int steps})> days,
  }) async {
    if (days.isEmpty) return (updated: 0, skipped: 0);
    final result = await _network.send<_StepsSyncResult>(
      path: '/steps/sync',
      method: RequestType.post,
      data: {
        'source': source,
        'days': [
          for (final d in days) {'date': d.date, 'steps': d.steps},
        ],
      },
      parserModel: _StepsSyncResult.fromJson,
    );
    return (updated: result?.updated ?? 0, skipped: result?.skipped ?? 0);
  }

  // ── Uyku ──

  /// `POST /sleep` (elle uyku kaydı; süre ve gün sunucuda hesaplanır).
  Future<void> createSleep({
    required DateTime sleepStart,
    required DateTime sleepEnd,
  }) async {
    await _network.send<SleepSummary>(
      path: '/sleep',
      method: RequestType.post,
      data: {
        'id': _uuid.v7(),
        'sleepStart': sleepStart.toUtc().toIso8601String(),
        'sleepEnd': sleepEnd.toUtc().toIso8601String(),
      },
      // Yanıt (kayıt) kullanılmıyor; ekran özeti yeniden okur.
      parserModel: (_) => SleepSummary.empty(sleepEnd),
    );
  }

  /// `PATCH /sleep/:id` (elle girilmiş kaydın saatleri).
  Future<void> updateSleep(
    String id, {
    required DateTime sleepStart,
    required DateTime sleepEnd,
  }) async {
    await _network.send<NoContent>(
      path: '/sleep/$id',
      method: RequestType.patch,
      data: {
        'sleepStart': sleepStart.toUtc().toIso8601String(),
        'sleepEnd': sleepEnd.toUtc().toIso8601String(),
      },
      parserModel: NoContent.fromJson,
    );
  }

  /// `DELETE /sleep/:id`.
  Future<void> deleteSleep(String id) async {
    await _network.send<NoContent>(
      path: '/sleep/$id',
      method: RequestType.delete,
      parserModel: NoContent.fromJson,
    );
  }

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
    this.source,
  });

  factory StepsDay.fromJson(Map<String, dynamic> json) => StepsDay(
    date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    steps: (json['steps'] as num?)?.toInt() ?? 0,
    distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
    kcal: (json['kcal'] as num?)?.toInt() ?? 0,
    durationMin: (json['durationMin'] as num?)?.toInt() ?? 0,
    isFuture: json['isFuture'] as bool? ?? false,
    source: json['source'] as String?,
  );

  final DateTime date;
  final int steps;
  final double distanceKm;
  final int kcal;
  final int durationMin;
  final bool isFuture;

  /// `manual` | `appleHealth` | `googleFit`; kayıt yoksa null.
  final String? source;

  /// Sağlık uygulamasından gelen gün: elle değiştirilemez (sunucu 409).
  bool get isHealthSynced => source != null && source != 'manual';
}

final class SleepSummary implements BaseModel<SleepSummary> {
  const SleepSummary({
    required this.date,
    this.lastNightMinutes,
    this.lastNightId,
    this.lastNightStart,
    this.lastNightEnd,
    this.lastNightSource,
    this.goalMin = 450,
    this.progress = 0,
    this.bedtime,
    this.wakeTime,
    this.weekMinutes = const [],
    this.weekDates = const [],
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
      lastNightId: lastMap?['id'] as String?,
      lastNightStart: DateTime.tryParse(
        lastMap?['sleepStart'] as String? ?? '',
      )?.toLocal(),
      lastNightEnd: DateTime.tryParse(
        lastMap?['sleepEnd'] as String? ?? '',
      )?.toLocal(),
      lastNightSource: lastMap?['source'] as String?,
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
      weekDates: weekRaw is List
          ? weekRaw
                .whereType<Map<String, dynamic>>()
                .map((d) => DateTime.tryParse(d['date'] as String? ?? ''))
                .toList()
          : const [],
    );
  }

  final DateTime date;
  final int? lastNightMinutes;

  /// Gecenin ana (en uzun) kaydı: gerçek yatış / kalkış.
  final String? lastNightId;
  final DateTime? lastNightStart;
  final DateTime? lastNightEnd;

  /// `manual` | `appleHealth` | `googleFit`.
  final String? lastNightSource;

  /// Elle girilmiş: düzenlenebilir / silinebilir.
  bool get lastNightEditable =>
      lastNightId != null && (lastNightSource ?? 'manual') == 'manual';

  final int goalMin;
  final double progress;
  final String? bedtime;
  final String? wakeTime;
  final List<int> weekMinutes;

  /// [weekMinutes] ile aynı sırada günler (son 7 gün, bugün en sonda).
  final List<DateTime?> weekDates;

  bool get hasLastNight => lastNightMinutes != null && lastNightMinutes! > 0;

  @override
  SleepSummary fromJson(Map<String, dynamic> json) =>
      SleepSummary.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {'date': date.toIso8601String()};
}

/// Ham `data` nesnesi (yalnızca birkaç alan okunan yanıtlar için).
/// `/weights` kaydı.
final class WeightEntry {
  const WeightEntry({
    required this.id,
    required this.weightKg,
    required this.recordedAt,
    this.source,
  });

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
    id: json['id'] as String? ?? '',
    weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
    recordedAt:
        DateTime.tryParse(json['recordedAt'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
    source: json['source'] as String?,
  );

  final String id;
  final double weightKg;
  final DateTime recordedAt;

  /// `manual` | `onboarding` | sağlık…
  final String? source;
}

final class _RawMap implements BaseModel<_RawMap> {
  const _RawMap(this.json);

  final Map<String, dynamic> json;

  @override
  _RawMap fromJson(Map<String, dynamic> json) => _RawMap(json);

  @override
  Map<String, dynamic> toJson() => json;
}

final class _StepsSyncResult implements BaseModel<_StepsSyncResult> {
  const _StepsSyncResult({this.updated = 0, this.skipped = 0});

  factory _StepsSyncResult.fromJson(Map<String, dynamic> json) =>
      _StepsSyncResult(
        updated: (json['updated'] as num?)?.toInt() ?? 0,
        skipped: (json['skipped'] as num?)?.toInt() ?? 0,
      );

  final int updated;
  final int skipped;

  @override
  _StepsSyncResult fromJson(Map<String, dynamic> json) =>
      _StepsSyncResult.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {'updated': updated, 'skipped': skipped};
}
