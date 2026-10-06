import 'package:flutter/foundation.dart';

/// Açlık takibi / hızlı kontrol ortak belirti seçimleri.
enum HungerSymptom {
  sleeplessness,
  headache,
  dizziness,
  nausea,
  fatigue,
  weakness,
}

/// Üçüncü soru — bedende fark edilenler.
enum HungerBodyNotice {
  stomachGrowling,
  lowEnergy,
  dizziness,
  nausea,
  fatigue,
  nothingPhysical,
}

extension HungerSymptomBodyNoticeX on HungerSymptom {
  HungerBodyNotice? toBodyNotice() => switch (this) {
        HungerSymptom.dizziness => HungerBodyNotice.dizziness,
        HungerSymptom.nausea => HungerBodyNotice.nausea,
        HungerSymptom.fatigue => HungerBodyNotice.fatigue,
        HungerSymptom.headache => HungerBodyNotice.lowEnergy,
        HungerSymptom.weakness => HungerBodyNotice.nothingPhysical,
        HungerSymptom.sleeplessness => null,
      };
}

/// Hızlı kontrol akışında ekranlar arası taşınan seçimler.
@immutable
final class HungerFlowArgs {
  const HungerFlowArgs({this.symptoms = const {}});

  final Set<HungerSymptom> symptoms;

  Set<HungerBodyNotice> toBodyNotices() {
    return {
      for (final s in symptoms)
        if (s.toBodyNotice() case final notice?) notice,
    };
  }
}
