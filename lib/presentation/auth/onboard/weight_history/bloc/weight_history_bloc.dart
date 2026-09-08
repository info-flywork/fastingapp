import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'weight_history_event.dart';
part 'weight_history_state.dart';

enum OnboardingWeightHistory {
  manyTimes,
  onceOrTwice,
  firstTime,
}

final class WeightHistoryBloc
    extends Bloc<WeightHistoryEvent, WeightHistoryState> {
  WeightHistoryBloc() : super(const WeightHistoryState()) {
    on<WeightHistorySelected>(_onSelected);
  }

  void _onSelected(
    WeightHistorySelected event,
    Emitter<WeightHistoryState> emit,
  ) {
    emit(state.copyWith(selected: event.history));
  }
}
