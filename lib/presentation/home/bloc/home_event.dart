import 'package:equatable/equatable.dart';

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
final class HomeWeightOptimistic extends HomeEvent {
  const HomeWeightOptimistic(this.weightKg);

  final double weightKg;

  @override
  List<Object?> get props => [weightKg];
}

/// Su / adım kartı, detay ekranıyla aynı anda güncellensin diye.
/// Sunucu yanıtı gelene kadar bu değer korunur.
final class HomeMetricsOptimistic extends HomeEvent {
  const HomeMetricsOptimistic({this.waterMl, this.steps});

  final int? waterMl;
  final int? steps;

  @override
  List<Object?> get props => [waterMl, steps];
}

final class HomePremiumTapped extends HomeEvent {
  const HomePremiumTapped();
}
