import 'package:equatable/equatable.dart';

sealed class WelcomeEvent extends Equatable {
  const WelcomeEvent();

  @override
  List<Object?> get props => [];
}

final class WelcomeGoogleTapped extends WelcomeEvent {
  const WelcomeGoogleTapped();
}

final class WelcomeGuestTapped extends WelcomeEvent {
  const WelcomeGuestTapped();
}
