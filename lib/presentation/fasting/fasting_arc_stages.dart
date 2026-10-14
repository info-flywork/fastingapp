import 'dart:math' as math;

import 'package:fastingapp/core/remote_images/app_image.dart';
import 'package:fastingapp/generated/app_images.g.dart';
import 'package:flutter/foundation.dart';

/// At nalı üzerindeki bir aşama işareti. [t] yay üzerindeki konum (0–1).
@immutable
final class ArcStage {
  const ArcStage({
    required this.index,
    required this.t,
    required this.idle,
    required this.reached,
    required this.titleKey,
    required this.bodyKey,
    required this.isReached,
    required this.isCurrent,
  });

  /// Aşama sırası (vücut: 0–8, yeme: 0–2).
  final int index;
  final double t;
  final AppImageAsset idle;
  final AppImageAsset reached;
  final String titleKey;
  final String bodyKey;

  /// İlerleme bu aşamaya ulaştı (renkli görsel).
  final bool isReached;

  /// Şu an içinde bulunulan aşama (üstteki kart bunu gösterir).
  final bool isCurrent;

  AppImageAsset get image => isReached ? reached : idle;
}

/// Vücut aşamalarının başlangıç saatleri (backend `seeds/content.json` →
/// `stages[type=body].startHour`; sunucu `bodyStage` ile aynı kural).
const kBodyStageHours = <double>[0, 2, 5, 8, 12, 16, 18, 24, 48];

const _bodyIdle = <AppImageAsset>[
  AppImages.a1,
  AppImages.a2,
  AppImages.a3,
  AppImages.a4,
  AppImages.a5,
  AppImages.a6,
  AppImages.a7,
  AppImages.a8,
  AppImages.a9,
];

const _bodyReached = <AppImageAsset>[
  AppImages.a1Light,
  AppImages.a2Light,
  AppImages.a3Light,
  AppImages.a4Light,
  AppImages.a5Light,
  AppImages.a6Light,
  AppImages.a7Light,
  AppImages.a8Light,
  AppImages.a9Light,
];

/// Geçen süreye göre vücut aşaması: başlangıcı ≤ geçen süre olan son aşama.
int bodyStageIndex(double elapsedHours) {
  var current = 0;
  for (var i = 0; i < kBodyStageHours.length; i++) {
    if (kBodyStageHours[i] <= elapsedHours) current = i;
  }
  return current;
}

/// Vücut aşaması için üstteki kartın metin/görseli (oruç sürerken).
ArcStage bodyStage(int index, {required bool reached}) => ArcStage(
  index: index,
  t: 0,
  idle: _bodyIdle[index],
  reached: _bodyReached[index],
  titleKey: 'body_status.title_${index + 1}',
  bodyKey: 'body_status.body_${index + 1}',
  isReached: reached,
  isCurrent: reached,
);

/// At nalındaki vücut aşamaları: hedef süreye kadar başlayan aşamalar,
/// konumu `başlangıç saati / hedef saat`. Birbirine çok yakın işaretler
/// üst üste binmesin diye seyreltilir (ilerideki aşama kalır, başlangıç her
/// zaman kalır).
List<ArcStage> bodyArcStages({
  required double targetHours,
  required double elapsedHours,
  required bool active,
  double minGap = 0.11,
}) {
  final target = targetHours > 0 ? targetHours : 16;
  final current = bodyStageIndex(elapsedHours);
  final out = <ArcStage>[];
  for (var i = 0; i < kBodyStageHours.length; i++) {
    final hours = kBodyStageHours[i];
    if (hours > target) break;
    final stage = ArcStage(
      index: i,
      t: hours / target,
      idle: _bodyIdle[i],
      reached: _bodyReached[i],
      titleKey: 'body_status.title_${i + 1}',
      bodyKey: 'body_status.body_${i + 1}',
      isReached: active && hours <= elapsedHours,
      isCurrent: active && i == current,
    );
    if (out.isNotEmpty && stage.t - out.last.t < minGap) {
      // Başlangıç işareti korunur; değilse yakın olan öncekinin yerini alır.
      if (out.length == 1) continue;
      out.removeLast();
    }
    out.add(stage);
  }
  return out;
}

/// Yeme penceresi aşamaları (backend `eatingStage`): ilk %20 (en az 30 dk)
/// orucu boz, son 60 dk sonraki oruca hazırlan, arası beslen.
int eatingStageIndex(int elapsedMinutes, int eatMinutes) {
  if (eatMinutes <= 0) return 0;
  final breakUntil = math.max((eatMinutes * 0.2).round(), 30);
  if (elapsedMinutes < breakUntil) return 0;
  if (elapsedMinutes >= eatMinutes - 60) return 2;
  return 1;
}

const _eatingKeys = ['break', 'nourish', 'next'];

const _eatingIdle = <AppImageAsset>[
  AppImages.breakYourFast,
  AppImages.darkNorusih,
  AppImages.darkFast,
];

const _eatingReached = <AppImageAsset>[
  AppImages.breakYourFast,
  AppImages.keepNoruish,
  AppImages.nextFast,
];

ArcStage eatingStage(int index, {required bool reached}) => ArcStage(
  index: index,
  t: 0,
  idle: _eatingIdle[index],
  reached: _eatingReached[index],
  titleKey: 'eating_window.${_eatingKeys[index]}_title',
  bodyKey: 'eating_window.${_eatingKeys[index]}_body',
  isReached: reached,
  isCurrent: reached,
);

/// Öğün sekmesi: 24 saatlik döngü (oruç + yeme penceresi) tek yayda.
/// Başta işaret yok (ilerleme oradan başlar); orucun bittiği noktada
/// "orucunu boz", pencere içinde "besle" (sunucu kuralı: ilk %20 / en az
/// 30 dk sonrası), yayın bittiği uçta kum saati ("sonraki oruca hazırlan",
/// son 60 dk içinde renklenir). Yakın işaretler kaydırılır; sığmıyorsa önce
/// "besle", sonra kum saati düşer ("orucunu boz" hep kalır).
@immutable
final class MealCycleArc {
  const MealCycleArc({required this.stages, required this.progress});

  final List<ArcStage> stages;

  /// Döngüdeki ilerleme (0–1).
  final double progress;
}

MealCycleArc mealCycleArc({
  required int fastMinutes,
  required int eatMinutes,
  int? fastElapsedMinutes,
  int? eatElapsedMinutes,
  double minGap = 0.11,
}) {
  final fast = fastMinutes > 0 ? fastMinutes : 960;
  final eat = eatMinutes > 0 ? eatMinutes : math.max(60, 1440 - fast);
  final cycle = fast + eat;
  final breakUntil = math.max((eat * 0.2).round(), 30);

  final double progress;
  if (eatElapsedMinutes != null) {
    progress = ((fast + eatElapsedMinutes) / cycle).clamp(0.0, 1.0);
  } else if (fastElapsedMinutes != null) {
    progress = (fastElapsedMinutes / cycle).clamp(0.0, fast / cycle);
  } else {
    progress = 0;
  }
  final eatingIdx = eatElapsedMinutes == null
      ? -1
      : eatingStageIndex(eatElapsedMinutes, eat);

  final breakT = fast / cycle;
  const nextT = 1.0;
  // Kayan nokta payı: tam minGap aralık geçerli.
  const eps = 1e-9;
  double? nourishT = math.max((fast + breakUntil) / cycle, breakT + minGap);
  if (nextT - nourishT < minGap - eps) nourishT = nextT - minGap;
  if (nourishT - breakT < minGap - eps) nourishT = null;
  final showNext = nextT - (nourishT ?? breakT) >= minGap - eps;

  ArcStage marker(
    int index,
    double t, {
    required bool reached,
    bool current = false,
  }) {
    // index: 1 orucunu boz, 2 besle, 3 sonraki oruç (0 kullanılmıyor).
    const idle = [
      AppImages.darkFast,
      AppImages.breakYourFast,
      AppImages.darkNorusih,
      AppImages.darkFast,
    ];
    const lit = [
      AppImages.nextFast,
      AppImages.breakYourFast,
      AppImages.keepNoruish,
      AppImages.nextFast,
    ];
    const keys = ['next', 'break', 'nourish', 'next'];
    return ArcStage(
      index: index,
      t: t,
      idle: idle[index],
      reached: lit[index],
      titleKey: 'eating_window.${keys[index]}_title',
      bodyKey: 'eating_window.${keys[index]}_body',
      isReached: reached,
      isCurrent: current,
    );
  }

  return MealCycleArc(
    progress: progress,
    stages: [
      marker(1, breakT, reached: eatingIdx >= 0, current: eatingIdx == 0),
      if (nourishT != null)
        marker(2, nourishT, reached: eatingIdx >= 1, current: eatingIdx == 1),
      if (showNext)
        marker(3, nextT, reached: eatingIdx >= 2, current: eatingIdx == 2),
    ],
  );
}
