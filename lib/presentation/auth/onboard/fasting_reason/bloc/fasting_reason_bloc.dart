import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'fasting_reason_event.dart';
part 'fasting_reason_state.dart';

enum OnboardingFastingReason {
  specialDate,
  trip,
  healthLongevity,
  confidence,
}

/// Seçime göre bugünden itibaren eklenecek gün sayısı.
extension OnboardingFastingReasonDays on OnboardingFastingReason {
  int get targetDaysAhead => switch (this) {
        OnboardingFastingReason.specialDate => 45,
        OnboardingFastingReason.trip => 90,
        OnboardingFastingReason.healthLongevity => 180,
        OnboardingFastingReason.confidence => 120,
      };

  DateTime targetDateFrom(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return today.add(Duration(days: targetDaysAhead));
  }
}

final class FastingReasonBloc
    extends Bloc<FastingReasonEvent, FastingReasonState> {
  FastingReasonBloc() : super(const FastingReasonState()) {
    on<FastingReasonSelected>(_onSelected);
  }

  void _onSelected(
    FastingReasonSelected event,
    Emitter<FastingReasonState> emit,
  ) {
    emit(
      state.copyWith(
        selected: event.reason,
        targetDate: event.reason.targetDateFrom(DateTime.now()),
      ),
    );
  }
}
