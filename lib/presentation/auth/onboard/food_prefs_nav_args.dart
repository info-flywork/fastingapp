import 'package:flutter/foundation.dart';
import 'package:fastingapp/presentation/auth/onboard/food_loves/bloc/food_loves_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/food_skips/bloc/food_skips_bloc.dart';

/// Food loves → skips → noted arası aktarılan tercihler.
@immutable
final class FoodPrefsNavArgs {
  const FoodPrefsNavArgs({
    this.loves = const {},
    this.skips = const {},
  });

  final Set<OnboardingFoodLove> loves;
  final Set<OnboardingFoodSkip> skips;

  FoodPrefsNavArgs copyWith({
    Set<OnboardingFoodLove>? loves,
    Set<OnboardingFoodSkip>? skips,
  }) {
    return FoodPrefsNavArgs(
      loves: loves ?? this.loves,
      skips: skips ?? this.skips,
    );
  }
}
