part of 'about_you_bloc.dart';

sealed class AboutYouEvent extends Equatable {
  const AboutYouEvent();

  @override
  List<Object?> get props => [];
}

final class AboutYouGenderSelected extends AboutYouEvent {
  const AboutYouGenderSelected(this.gender);

  final OnboardingGender gender;

  @override
  List<Object?> get props => [gender];
}
