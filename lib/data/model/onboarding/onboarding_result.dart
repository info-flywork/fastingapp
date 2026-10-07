import 'package:equatable/equatable.dart';
import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/data/model/user/user.dart';

/// `POST /user/onboarding` yanıtı: kullanıcı, kurulan plan ve kilo projeksiyonu.
final class OnboardingResult extends Equatable
    implements BaseModel<OnboardingResult> {
  const OnboardingResult({
    required this.user,
    required this.planCode,
    required this.projection,
  });

  factory OnboardingResult.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'] as Map<String, dynamic>? ?? const {};
    final projection = json['projection'] as Map<String, dynamic>? ?? const {};
    return OnboardingResult(
      user: User.fromJson(json['user'] as Map<String, dynamic>? ?? const {}),
      planCode: plan['planCode'] as String?,
      projection: WeightProjection.fromJson(projection),
    );
  }

  final User user;
  final String? planCode;
  final WeightProjection projection;

  @override
  OnboardingResult fromJson(Map<String, dynamic> json) =>
      OnboardingResult.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {'planCode': planCode};

  @override
  List<Object?> get props => [user, planCode, projection];
}

/// Sunucunun hesapladığı hedefe ulaşma projeksiyonu.
final class WeightProjection extends Equatable {
  const WeightProjection({
    this.currentWeightKg,
    this.goalWeightKg,
    this.weeklyLossKg,
    this.targetDate,
  });

  factory WeightProjection.fromJson(Map<String, dynamic> json) =>
      WeightProjection(
        currentWeightKg: (json['currentWeightKg'] as num?)?.toDouble(),
        goalWeightKg: (json['goalWeightKg'] as num?)?.toDouble(),
        weeklyLossKg: (json['weeklyLossKg'] as num?)?.toDouble(),
        targetDate: DateTime.tryParse(json['targetDate'] as String? ?? ''),
      );

  final double? currentWeightKg;
  final double? goalWeightKg;
  final double? weeklyLossKg;
  final DateTime? targetDate;

  @override
  List<Object?> get props => [
    currentWeightKg,
    goalWeightKg,
    weeklyLossKg,
    targetDate,
  ];
}
