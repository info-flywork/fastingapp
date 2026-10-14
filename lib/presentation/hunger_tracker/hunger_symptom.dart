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
    // Halsizlik bedensel bir belirti (önceden "hiçbir şey" sayılıp
    // duygusal puan veriyordu); baş ağrısı / uykusuzluk karşılıksız.
    HungerSymptom.weakness => HungerBodyNotice.lowEnergy,
    HungerSymptom.headache => null,
    HungerSymptom.sleeplessness => null,
  };
}

/// Hızlı kontrol akışında ekranlar arası taşınan seçimler.
@immutable
final class HungerFlowArgs {
  const HungerFlowArgs({
    this.symptoms = const {},
    this.q1,
    this.q2,
    this.bodyNotices = const {},
    this.q4,
    this.mode = 'quick',
  });

  final Set<HungerSymptom> symptoms;

  /// `quick` | `full` (sunucu `mode`; önceden hep `quick` gidiyordu).
  final String mode;
  final String? q1;
  final String? q2;
  final Set<HungerBodyNotice> bodyNotices;
  final String? q4;

  Set<HungerBodyNotice> toBodyNotices() {
    if (bodyNotices.isNotEmpty) return bodyNotices;
    return {
      for (final s in symptoms)
        if (s.toBodyNotice() case final notice?) notice,
    };
  }

  HungerFlowArgs copyWith({
    Set<HungerSymptom>? symptoms,
    String? q1,
    String? q2,
    Set<HungerBodyNotice>? bodyNotices,
    String? q4,
    String? mode,
  }) {
    return HungerFlowArgs(
      mode: mode ?? this.mode,
      symptoms: symptoms ?? this.symptoms,
      q1: q1 ?? this.q1,
      q2: q2 ?? this.q2,
      bodyNotices: bodyNotices ?? this.bodyNotices,
      q4: q4 ?? this.q4,
    );
  }
}

extension HungerBodyNoticeApi on HungerBodyNotice {
  String get apiValue => switch (this) {
    HungerBodyNotice.stomachGrowling => 'stomachGrowling',
    HungerBodyNotice.lowEnergy => 'lowEnergy',
    HungerBodyNotice.dizziness => 'dizziness',
    HungerBodyNotice.nausea => 'nausea',
    HungerBodyNotice.fatigue => 'fatigue',
    HungerBodyNotice.nothingPhysical => 'nothingPhysical',
  };
}
