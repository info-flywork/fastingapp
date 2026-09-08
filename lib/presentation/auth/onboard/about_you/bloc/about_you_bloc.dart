import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'about_you_event.dart';
part 'about_you_state.dart';

enum OnboardingGender {
  woman,
  man,
  nonBinary,
  preferNotToSay,
}

final class AboutYouBloc extends Bloc<AboutYouEvent, AboutYouState> {
  AboutYouBloc() : super(const AboutYouState()) {
    on<AboutYouGenderSelected>(_onSelected);
  }

  void _onSelected(AboutYouGenderSelected event, Emitter<AboutYouState> emit) {
    emit(state.copyWith(selected: event.gender));
  }
}
