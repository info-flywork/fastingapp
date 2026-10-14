part of 'meal_window_bloc.dart';

final class MealWindowState extends Equatable {
  const MealWindowState({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  MealWindowState copyWith({
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
  }) {
    return MealWindowState(
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
    );
  }

  /// Başlangıç = bitiş geçersiz (sunucu `mealWindow` ile en sonda
  /// reddediyordu).
  bool get isValid => startHour != endHour || startMinute != endMinute;

  @override
  List<Object?> get props => [startHour, startMinute, endHour, endMinute];
}
