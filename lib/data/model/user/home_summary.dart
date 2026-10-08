import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/data/model/user/user.dart';
import 'package:fastingapp/data/model/user/user_progress.dart';

/// `GET /user/summary` — ana sayfanın tek çağrısı (backend doküman 04 §2).
/// Şimdilik ana sayfanın kullandığı alanlar; diğerleri (aktif oruç, hafta,
/// son öğün, challenge) kartlar bağlandıkça eklenir.
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
  });

  factory HomeSummary.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> map(Object? v) =>
        v is Map<String, dynamic> ? v : const <String, dynamic>{};
    double? kg(Object? v) => (v as num?)?.toDouble();
    final today = map(json['today']);
    final water = map(today['water']);
    final steps = map(today['steps']);
    final weight = map(json['weight']);
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

  @override
  HomeSummary fromJson(Map<String, dynamic> json) => HomeSummary.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}
