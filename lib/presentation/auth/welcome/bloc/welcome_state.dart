import 'package:equatable/equatable.dart';

sealed class WelcomeState extends Equatable {
  const WelcomeState();

  @override
  List<Object?> get props => [];
}

final class WelcomeInitial extends WelcomeState {
  const WelcomeInitial();
}

final class WelcomeLoading extends WelcomeState {
  const WelcomeLoading();
}

/// Giriş başarılı; view [navigateTo] rotasına yönlendirir.
final class WelcomeSuccess extends WelcomeState {
  const WelcomeSuccess({required this.navigateTo});

  final String navigateTo;

  @override
  List<Object?> get props => [navigateTo];
}

final class WelcomeError extends WelcomeState {
  const WelcomeError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
