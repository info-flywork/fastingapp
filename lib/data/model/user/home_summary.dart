import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/data/model/user/user.dart';
import 'package:fastingapp/data/model/user/user_progress.dart';
import 'package:fastingapp/domain/fasting/fasting_repository.dart';
import 'package:fastingapp/domain/gamification/challenges_repository.dart';

/// `GET /user/summary` — ana sayfanın tek çağrısı (backend doküman 04 §2).
final class HomeSummary implements BaseModel<HomeSummary> {
  const HomeSummary({
    required this.user,
    required this.progress,
    this.waterMl = 0,
    this.waterGoalMl,
    this.steps = 0,
    this.stepsGoal,
    this.weightCurrentKg,
    this.weightStartKg,
    this.weightGoalKg,
    this.activeFast,
    this.eatingWindow,
    this.plan,
    this.week = const [],
    this.lastMeal,
    this.hungerPhysical = 0,
    this.hungerEmotional = 0,
    this.serverTime,
    this.featuredChallenge,
    this.waterUnit = 'ml',
    this.weightUnit = 'kg',
  });

  factory HomeSummary.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> map(Object? v) =>
        v is Map<String, dynamic> ? v : const <String, dynamic>{};
    double? kg(Object? v) => (v as num?)?.toDouble();
    DateTime? at(Object? v) =>
        v is String ? DateTime.tryParse(v)?.toLocal() : null;
    final today = map(json['today']);
    final water = map(today['water']);
    final steps = map(today['steps']);
    final weight = map(json['weight']);
    final fastRaw = json['activeFast'];
    final eatRaw = json['eatingWindow'];
    final planRaw = json['plan'];
    final weekRaw = json['week'];
    final mealRaw = today['lastMeal'];
    final hungerRaw = today['hunger'];
    final challengeRaw = json['featuredChallenge'];
    final units = map(map(json['user'])['units']);
    final hunger = hungerRaw is Map<String, dynamic> ? hungerRaw : null;
    return HomeSummary(
      user: User.fromJson(map(json['user'])),
      progress: UserProgress.fromJson(map(json['progress'])),
      waterMl: (water['ml'] as num?)?.toInt() ?? 0,
      waterGoalMl: (water['goalMl'] as num?)?.toInt(),
      steps: (steps['count'] as num?)?.toInt() ?? 0,
      stepsGoal: (steps['goal'] as num?)?.toInt(),
      weightCurrentKg: kg(weight['currentKg']),
      weightStartKg: kg(weight['startKg']),
      weightGoalKg: kg(weight['goalKg']),
      activeFast: fastRaw is Map<String, dynamic>
          ? ActiveFast.fromJson(fastRaw)
          : null,
      eatingWindow: eatRaw is Map<String, dynamic>
          ? EatingWindow.fromJson(eatRaw)
          : null,
      plan: planRaw is Map<String, dynamic>
          ? UserFastingPlan.fromJson(planRaw)
          : null,
      week: weekRaw is List
          ? weekRaw
                .whereType<Map<String, dynamic>>()
                .map(SummaryWeekDay.fromJson)
                .toList()
          : const [],
      lastMeal: mealRaw is Map<String, dynamic>
          ? SummaryLastMeal.fromJson(mealRaw)
          : null,
      hungerPhysical: (hunger?['physical'] as num?)?.toInt() ?? 0,
      hungerEmotional: (hunger?['emotional'] as num?)?.toInt() ?? 0,
      serverTime: at(json['serverTime']),
      featuredChallenge: challengeRaw is Map<String, dynamic>
          ? Challenge.fromJson(challengeRaw)
          : null,
      waterUnit: units['water'] as String? ?? 'ml',
      weightUnit: units['weight'] as String? ?? 'kg',
    );
  }

  final User user;
  final UserProgress progress;

  final int waterMl;
  final int? waterGoalMl;
  final int steps;
  final int? stepsGoal;
  final double? weightCurrentKg;
  final double? weightStartKg;
  final double? weightGoalKg;
  final ActiveFast? activeFast;
  final EatingWindow? eatingWindow;
  final UserFastingPlan? plan;
  final List<SummaryWeekDay> week;
  final SummaryLastMeal? lastMeal;
  final int hungerPhysical;
  final int hungerEmotional;
  final DateTime? serverTime;

  /// Ana sayfa / oruç sekmesi challenge kartı; yoksa kart gizlenir.
  final Challenge? featuredChallenge;

  /// Kullanıcının birim tercihleri (`user.units`): `ml` | `oz`, `kg` | `lb`.
  /// Önceden yalnızca su / kilo dialogunda uygulanıyordu.
  final String waterUnit;
  final String weightUnit;

  HomeSummary copyWith({
    User? user,
    UserProgress? progress,
    int? waterMl,
    int? waterGoalMl,
    int? steps,
    int? stepsGoal,
    double? weightCurrentKg,
    double? weightStartKg,
    double? weightGoalKg,
    ActiveFast? activeFast,
    EatingWindow? eatingWindow,
    UserFastingPlan? plan,
    List<SummaryWeekDay>? week,
    SummaryLastMeal? lastMeal,
    int? hungerPhysical,
    int? hungerEmotional,
    DateTime? serverTime,
    Challenge? featuredChallenge,
    bool clearActiveFast = false,
    bool clearEatingWindow = false,
    bool clearLastMeal = false,
    bool clearFeaturedChallenge = false,
  }) {
    return HomeSummary(
      user: user ?? this.user,
      progress: progress ?? this.progress,
      waterMl: waterMl ?? this.waterMl,
      waterGoalMl: waterGoalMl ?? this.waterGoalMl,
      steps: steps ?? this.steps,
      stepsGoal: stepsGoal ?? this.stepsGoal,
      weightCurrentKg: weightCurrentKg ?? this.weightCurrentKg,
      weightStartKg: weightStartKg ?? this.weightStartKg,
      weightGoalKg: weightGoalKg ?? this.weightGoalKg,
      activeFast: clearActiveFast ? null : (activeFast ?? this.activeFast),
      eatingWindow: clearEatingWindow
          ? null
          : (eatingWindow ?? this.eatingWindow),
      plan: plan ?? this.plan,
      week: week ?? this.week,
      lastMeal: clearLastMeal ? null : (lastMeal ?? this.lastMeal),
      hungerPhysical: hungerPhysical ?? this.hungerPhysical,
      hungerEmotional: hungerEmotional ?? this.hungerEmotional,
      serverTime: serverTime ?? this.serverTime,
      featuredChallenge: clearFeaturedChallenge
          ? null
          : (featuredChallenge ?? this.featuredChallenge),
      waterUnit: waterUnit,
      weightUnit: weightUnit,
    );
  }

  @override
  HomeSummary fromJson(Map<String, dynamic> json) => HomeSummary.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}
