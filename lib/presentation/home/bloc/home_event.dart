import 'package:equatable/equatable.dart';
import 'package:fastingapp/domain/gamification/challenges_repository.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

final class HomeStarted extends HomeEvent {
  const HomeStarted();
}

/// Oturum kapanınca önbelleklenmiş home state'i sıfırlar.
final class HomeCleared extends HomeEvent {
  const HomeCleared();
}

final class HomeRefreshRequested extends HomeEvent {
  const HomeRefreshRequested();
}

/// Kilo kaydı sonrası özet gelene kadar kartı anında güncelle.
/// Su / adım kartı, detay ekranıyla aynı anda güncellensin diye.
/// Sunucu yanıtı gelene kadar bu değer korunur.
final class HomeMetricsOptimistic extends HomeEvent {
  const HomeMetricsOptimistic({
    this.waterMl,
    this.waterGoalMl,
    this.steps,
    this.stepsGoal,
    this.weightKg,
    this.weightGoalKg,
    this.hungerPhysical,
    this.hungerEmotional,
  });

  final int? waterMl;
  final int? waterGoalMl;
  final int? steps;
  final int? stepsGoal;
  final double? weightKg;
  final double? weightGoalKg;
  final int? hungerPhysical;
  final int? hungerEmotional;

  @override
  List<Object?> get props => [
    waterMl,
    waterGoalMl,
    steps,
    stepsGoal,
    weightKg,
    weightGoalKg,
    hungerPhysical,
    hungerEmotional,
  ];
}

final class HomePremiumTapped extends HomeEvent {
  const HomePremiumTapped();
}

/// Katıl yanıtındaki challenge: kart sunucu özetini beklemeden güncellenir.
final class HomeChallengeUpdated extends HomeEvent {
  const HomeChallengeUpdated(this.challenge);

  final Challenge challenge;

  @override
  List<Object?> get props => [challenge.code, challenge.my?.status];
}
