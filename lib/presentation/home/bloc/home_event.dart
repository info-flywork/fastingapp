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

final class HomePremiumTapped extends HomeEvent {
  const HomePremiumTapped();
}
