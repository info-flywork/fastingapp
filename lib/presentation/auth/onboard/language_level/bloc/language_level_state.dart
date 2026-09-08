import 'package:equatable/equatable.dart';

sealed class LanguageLevelState extends Equatable {
  const LanguageLevelState();

  @override
  List<Object?> get props => [];
}

final class LanguageLevelInitial extends LanguageLevelState {
  const LanguageLevelInitial({this.selectedLevel});

  final int? selectedLevel;

  @override
  List<Object?> get props => [selectedLevel];
}

final class LanguageLevelSubmitting extends LanguageLevelState {
  const LanguageLevelSubmitting();
}

final class LanguageLevelCompleted extends LanguageLevelState {
  const LanguageLevelCompleted();
}

final class LanguageLevelFailure extends LanguageLevelState {
  const LanguageLevelFailure({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
