import 'package:fastingapp/presentation/hunger_tracker/hunger_result_type.dart';
import 'package:fastingapp/presentation/hunger_tracker/hunger_symptom.dart';
import 'package:flutter/foundation.dart';

/// Sonuç / log ekranlarına taşınan oturum verisi.
@immutable
final class HungerSessionArgs {
  const HungerSessionArgs({
    required this.flow,
    required this.resultType,
    this.recommendations = const [],
    this.safetyFlag = false,
  });

  final HungerFlowArgs flow;
  final HungerResultType resultType;

  /// Sunucu önerileri (`/hunger-checkins/evaluate`, dile göre metin); boşsa
  /// ekran yerel metinleri gösterir.
  final List<String> recommendations;

  /// Ciddi belirti işareti: sonuç ekranında güvenlik uyarısı.
  final bool safetyFlag;
}
