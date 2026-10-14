import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/core/utils/enum/request_type.dart';

/// Beslenme gün/hafta (`/v1/nutrition/*`, backend doküman 04 §11).
/// Bellek içi cache: tekrar açılışta spinner yok, sessiz yenileme.
final class NutritionRepository {
  NutritionRepository(this._network);

  final NetworkManager _network;

  NutritionDay? _dayCache;
  String? _dayCacheKey;
  final Map<String, NutritionWeek> _weekCache = {};

  /// Bir yazma oldu: cache gösterilmeye devam eder (iskelet yok) ama
  /// `force: false` istekler de ağa gider.
  bool _dayStale = false;
  bool _weekStale = false;

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _dayKey(DateTime? date) {
    final d = date ?? DateTime.now();
    return _ymd(DateTime(d.year, d.month, d.day));
  }

  /// Cache'teki gün özeti; yoksa null.
  NutritionDay? cachedDay({DateTime? date}) {
    final key = _dayKey(date);
    if (_dayCacheKey != key) return null;
    return _dayCache;
  }

  NutritionWeek? cachedWeek({String metric = 'protein', DateTime? date}) =>
      _weekCache['$metric:${_dayKey(date)}'];

  /// Yazma sonrası: veriyi silmez, bayat işaretler (ekranlar eski değeri
  /// gösterip sessizce tazeler).
  void invalidate() => _dayStale = _weekStale = true;

  /// Çıkış / hesap değişimi: önbellek tamamen boşalır.
  void clear() {
    _dayCache = null;
    _dayCacheKey = null;
    _weekCache.clear();
    _dayStale = _weekStale = false;
  }

  Future<NutritionDay> getDay({DateTime? date, bool force = false}) async {
    final key = _dayKey(date);
    if (!force && !_dayStale && _dayCache != null && _dayCacheKey == key) {
      return _dayCache!;
    }
    final result = await _network.send<NutritionDay>(
      path: '/nutrition/day',
      method: RequestType.get,
      queryParameters: {if (date != null) 'date': _ymd(date)},
      parserModel: NutritionDay.fromJson,
    );
    final day = result ?? NutritionDay.empty();
    _dayCache = day;
    _dayCacheKey = key;
    _dayStale = false;
    return day;
  }

  Future<NutritionWeek> getWeek({
    String metric = 'protein',
    DateTime? date,
    bool force = false,
  }) async {
    final key = '$metric:${_dayKey(date)}';
    if (!force && !_weekStale) {
      final hit = _weekCache[key];
      if (hit != null) return hit;
    }
    final result = await _network.send<NutritionWeek>(
      path: '/nutrition/week',
      method: RequestType.get,
      queryParameters: {'metric': metric, if (date != null) 'date': _ymd(date)},
      parserModel: NutritionWeek.fromJson,
    );
    final week = result ?? NutritionWeek.empty(metric: metric);
    if (_weekStale) _weekCache.clear();
    _weekStale = false;
    _weekCache[key] = week;
    return week;
  }
}

final class NutritionDay implements BaseModel<NutritionDay> {
  const NutritionDay({
    required this.date,
    required this.kcal,
    required this.meals,
    required this.macros,
    this.kcalGoal,
    this.progress,
    this.overKcal,
    this.burnedKcal = 0,
  });

  factory NutritionDay.empty() => NutritionDay(
    date: DateTime.now(),
    kcal: 0,
    meals: const [],
    macros: NutritionMacros.empty(),
  );

  factory NutritionDay.fromJson(Map<String, dynamic> json) {
    final macrosRaw = json['macros'];
    final mealsRaw = json['meals'];
    return NutritionDay(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      kcal: (json['kcal'] as num?)?.toInt() ?? 0,
      kcalGoal: (json['kcalGoal'] as num?)?.toInt(),
      progress: (json['progress'] as num?)?.toDouble(),
      overKcal: (json['overKcal'] as num?)?.toInt(),
      burnedKcal: (json['burnedKcal'] as num?)?.toInt() ?? 0,
      macros: macrosRaw is Map<String, dynamic>
          ? NutritionMacros.fromJson(macrosRaw)
          : NutritionMacros.empty(),
      meals: mealsRaw is List
          ? mealsRaw
                .whereType<Map<String, dynamic>>()
                .map(NutritionMeal.fromJson)
                .toList()
          : const [],
    );
  }

  final DateTime date;
  final int kcal;
  final int? kcalGoal;
  final double? progress;
  final int? overKcal;
  final int burnedKcal;
  final NutritionMacros macros;
  final List<NutritionMeal> meals;

  bool get hasMeals => meals.isNotEmpty;
  bool get hasIntake => kcal > 0 || hasMeals;

  @override
  NutritionDay fromJson(Map<String, dynamic> json) =>
      NutritionDay.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'kcal': kcal,
  };
}

final class NutritionMacros {
  const NutritionMacros({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory NutritionMacros.empty() => const NutritionMacros(
    protein: NutritionMacro(g: 0),
    carbs: NutritionMacro(g: 0),
    fat: NutritionMacro(g: 0),
  );

  factory NutritionMacros.fromJson(Map<String, dynamic> json) =>
      NutritionMacros(
        protein: NutritionMacro.fromJson(
          json['protein'] as Map<String, dynamic>? ?? const {},
        ),
        carbs: NutritionMacro.fromJson(
          json['carbs'] as Map<String, dynamic>? ?? const {},
        ),
        fat: NutritionMacro.fromJson(
          json['fat'] as Map<String, dynamic>? ?? const {},
        ),
      );

  final NutritionMacro protein;
  final NutritionMacro carbs;
  final NutritionMacro fat;
}

final class NutritionMacro {
  const NutritionMacro({required this.g, this.goalG, this.progress});

  factory NutritionMacro.fromJson(Map<String, dynamic> json) => NutritionMacro(
    g: (json['g'] as num?)?.toDouble() ?? 0,
    goalG: (json['goalG'] as num?)?.toDouble(),
    progress: (json['progress'] as num?)?.toDouble(),
  );

  final double g;
  final double? goalG;
  final double? progress;

  double get progressOrZero => (progress ?? 0).clamp(0.0, 1.0);
}

final class NutritionMeal {
  const NutritionMeal({
    required this.id,
    required this.eatenAt,
    required this.title,
    required this.kcal,
    required this.proteinG,
    this.kind,
    this.slot,
    this.photoUrl,
  });

  factory NutritionMeal.fromJson(Map<String, dynamic> json) {
    final photo = json['photo'];
    final photoMap = photo is Map<String, dynamic> ? photo : null;
    return NutritionMeal(
      id: json['id'] as String? ?? '',
      eatenAt:
          DateTime.tryParse(json['eatenAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      title: json['title'] as String? ?? '',
      kcal: (json['kcal'] as num?)?.toInt() ?? 0,
      proteinG: (json['proteinG'] as num?)?.toDouble() ?? 0,
      kind: json['kind'] as String?,
      slot: json['slot'] as String?,
      photoUrl: photoMap?['url'] as String? ?? photoMap?['thumbUrl'] as String?,
    );
  }

  final String id;
  final DateTime eatenAt;
  final String title;
  final int kcal;
  final double proteinG;
  final String? kind;
  final String? slot;
  final String? photoUrl;
}

final class NutritionWeek implements BaseModel<NutritionWeek> {
  const NutritionWeek({
    required this.metric,
    required this.weekStart,
    required this.days,
    this.goal,
  });

  factory NutritionWeek.empty({String metric = 'protein'}) =>
      NutritionWeek(metric: metric, weekStart: DateTime.now(), days: const []);

  factory NutritionWeek.fromJson(Map<String, dynamic> json) {
    final daysRaw = json['days'];
    return NutritionWeek(
      metric: json['metric'] as String? ?? 'protein',
      weekStart:
          DateTime.tryParse(json['weekStart'] as String? ?? '') ??
          DateTime.now(),
      goal: (json['goal'] as num?)?.toDouble(),
      days: daysRaw is List
          ? daysRaw
                .whereType<Map<String, dynamic>>()
                .map(NutritionWeekDay.fromJson)
                .toList()
          : const [],
    );
  }

  final String metric;
  final DateTime weekStart;
  final double? goal;
  final List<NutritionWeekDay> days;

  @override
  NutritionWeek fromJson(Map<String, dynamic> json) =>
      NutritionWeek.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {
    'metric': metric,
    'weekStart': weekStart.toIso8601String(),
  };
}

final class NutritionWeekDay {
  const NutritionWeekDay({
    required this.date,
    required this.value,
    required this.isToday,
    required this.isFuture,
    this.progress,
  });

  factory NutritionWeekDay.fromJson(Map<String, dynamic> json) =>
      NutritionWeekDay(
        date:
            DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        value: (json['value'] as num?)?.toDouble() ?? 0,
        progress: (json['progress'] as num?)?.toDouble(),
        isToday: json['isToday'] as bool? ?? false,
        isFuture: json['isFuture'] as bool? ?? false,
      );

  final DateTime date;
  final double value;
  final double? progress;
  final bool isToday;
  final bool isFuture;
}
