import 'package:fastingapp/presentation/hunger_tracker/hunger_result_type.dart';
import 'package:fastingapp/presentation/hunger_tracker/hunger_symptom.dart';
import 'package:flutter/foundation.dart';

/// Sonuç / log ekranlarına taşınan oturum verisi.
@immutable
final class HungerSessionArgs {
  const HungerSessionArgs({
    required this.flow,
    required this.resultType,
  });

  final HungerFlowArgs flow;
  final HungerResultType resultType;
}
