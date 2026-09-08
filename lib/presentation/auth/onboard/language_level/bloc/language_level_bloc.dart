import 'package:fastingapp/domain/user/user_repository.dart';
import 'package:fastingapp/presentation/auth/onboard/language_level/bloc/language_level_event.dart';
import 'package:fastingapp/presentation/auth/onboard/language_level/bloc/language_level_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Onboarding — seviye seçimi. (Doküman 4)
final class LanguageLevelBloc
    extends Bloc<LanguageLevelEvent, LanguageLevelState> {
  LanguageLevelBloc(this._userRepository)
    : super(const LanguageLevelInitial()) {
    on<LanguageLevelSelected>(_onSelected);
    on<LanguageLevelSubmitted>(_onSubmitted);
  }

  final UserRepository _userRepository;

  int? _selectedLevel;

  void _onSelected(
    LanguageLevelSelected event,
    Emitter<LanguageLevelState> emit,
  ) {
    _selectedLevel = event.level;
    emit(LanguageLevelInitial(selectedLevel: event.level));
  }

  Future<void> _onSubmitted(
    LanguageLevelSubmitted event,
    Emitter<LanguageLevelState> emit,
  ) async {
    final level = _selectedLevel;
    if (level == null) return;

    emit(const LanguageLevelSubmitting());
    try {
      await _userRepository.saveAnsweredQuestions(level: level);
      emit(const LanguageLevelCompleted());
    } on Exception catch (e) {
      emit(LanguageLevelFailure(message: e.toString()));
    }
  }
}
