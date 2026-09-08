part of 'about_you_bloc.dart';

final class AboutYouState extends Equatable {
  const AboutYouState({this.selected});

  final OnboardingGender? selected;

  AboutYouState copyWith({OnboardingGender? selected}) {
    return AboutYouState(selected: selected ?? this.selected);
  }

  @override
  List<Object?> get props => [selected];
}
