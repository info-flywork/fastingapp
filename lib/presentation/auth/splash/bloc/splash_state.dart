import 'package:equatable/equatable.dart';

sealed class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

final class SplashInitial extends SplashState {
  const SplashInitial();
}

/// Hedef rotaya yönlendirme sinyali. Navigasyon view katmanında yapılır.
final class SplashNavigateTo extends SplashState {
  const SplashNavigateTo(this.destination);

  final String destination;

  @override
  List<Object?> get props => [destination];
}
