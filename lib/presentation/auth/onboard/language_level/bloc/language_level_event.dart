import 'package:equatable/equatable.dart';

sealed class LanguageLevelEvent extends Equatable {
  const LanguageLevelEvent();

  @override
  List<Object?> get props => [];
}

final class LanguageLevelSelected extends LanguageLevelEvent {
  const LanguageLevelSelected(this.level);

  final int level;

  @override
  List<Object?> get props => [level];
}

final class LanguageLevelSubmitted extends LanguageLevelEvent {
  const LanguageLevelSubmitted();
}
