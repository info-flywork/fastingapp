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

/// Planın göstereceği vücut aşamaları.
///
/// Bir aşama yalnızca başlangıç saati hedefe sığıyorsa girer (`start ≤ T`).
/// 12 saatlik planda ketoz, 16 saatlikte otofaji yoktur. Yayda birbirine
/// [minGap]'ten yakın işaretler seyreltilir; orucun başı ve bu planda
/// ulaşılan son aşama her zaman kalır.
List<int> bodyPlanStageIndices(double targetHours, {double minGap = 0.11}) {
  final target = targetHours > 0 ? targetHours : 16.0;
  final eligible = <int>[
    for (var i = 0; i < kBodyStageHours.length; i++)
      if (kBodyStageHours[i] <= target) i,
  ];
  if (eligible.isEmpty) return const [0];

  final out = <int>[];
  for (final i in eligible) {
    final t = kBodyStageHours[i] / target;
    if (out.isNotEmpty && t - (kBodyStageHours[out.last] / target) < minGap) {
      // Başlangıç korunur; değilse yakın olan öncekinin yerini sonraki alır.
      if (out.length == 1) continue;
      out.removeLast();
    }
    out.add(i);
  }
  return out;
}

/// Plandaki mevcut aşama. Hedef dolunca listenin son aşamasıdır: süre
/// hedefin ötesine geçse de daha uzun planların aşamalarına atlanmaz.
int bodyPlanStageIndex({
  required double targetHours,
  required double elapsedHours,
  double minGap = 0.11,
}) {
  final indices = bodyPlanStageIndices(targetHours, minGap: minGap);
  final target = targetHours > 0 ? targetHours : 16.0;
  if (elapsedHours >= target) return indices.last;
  var current = indices.first;
  for (final i in indices) {
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

/// At nalındaki vücut aşamaları: yalnızca bu plana sığanlar, konumu
/// `başlangıç saati / hedef saat`. Hedef dolunca mevcut aşama listenin sonu.
List<ArcStage> bodyArcStages({
  required double targetHours,
  required double elapsedHours,
  required bool active,
  double minGap = 0.11,
}) {
  final target = targetHours > 0 ? targetHours : 16.0;
  final indices = bodyPlanStageIndices(target, minGap: minGap);
  final current = active
      ? bodyPlanStageIndex(
          targetHours: target,
          elapsedHours: elapsedHours,
          minGap: minGap,
        )
      : -1;
  return [
    for (final i in indices)
      ArcStage(
        index: i,
        t: kBodyStageHours[i] / target,
        idle: _bodyIdle[i],
        reached: _bodyReached[i],
        titleKey: 'body_status.title_${i + 1}',
        bodyKey: 'body_status.body_${i + 1}',
        isReached:
            active && (i == current || kBodyStageHours[i] <= elapsedHours),
        isCurrent: i == current,
      ),
  ];
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

/// Öğün sekmesi: oruç + yeme tek yayda.
///
/// İşaretler **yayın** (0–1) üzerinde plana göre yerleştirilir — gerçek 24s
/// oranına birebir değil (16:8'de sağa yığılmasın diye):
/// - orucunu boz → yayın ilk yarısında (plan uzadıkça sağa, ≤ ~%40)
/// - besle (öğün) → yayın ~%60'ı
/// - sonraki oruç (kum saati) → yayın sonu
///
/// İlerleme işarete göre ölçeklenir (oruç bitince boz noktasına varır).
/// Kart aşaması sunucu kuralı (`eatingStageIndex`).
@immutable
final class MealCycleArc {
  const MealCycleArc({required this.stages, required this.progress});

  final List<ArcStage> stages;

  /// Yay üzerindeki ilerleme (0–1).
  final double progress;
}

/// Öğün yayındaki işaretler için plan-duyarlı minimum aralık.
double mealArcMinGap(int fastMinutes, int eatMinutes) {
  final fast = fastMinutes > 0 ? fastMinutes : 960;
  final eat = eatMinutes > 0 ? eatMinutes : math.max(60, 1440 - fast);
  final cycle = fast + eat;
  return ((eat / cycle) * 0.25).clamp(0.08, 0.12).toDouble();
}

/// Orucunu boz: yayın sol yarısı, plana göre (uzun oruç → biraz daha sağda).
double mealArcBreakT(int fastMinutes, int eatMinutes) {
  final fast = fastMinutes > 0 ? fastMinutes : 960;
  final eat = eatMinutes > 0 ? eatMinutes : math.max(60, 1440 - fast);
  final fastShare = fast / (fast + eat);
  // 12:12 → ~0.20, 16:8 → ~0.22, 18:6 → ~0.23, 20:4 → ~0.24
  return (0.12 + 0.15 * fastShare).clamp(0.16, 0.26).toDouble();
}

/// Öğün (besle): yayda %60.
double mealArcNourishT(int fastMinutes, int eatMinutes) {
  final breakT = mealArcBreakT(fastMinutes, eatMinutes);
  // Bozdan sonra kalacak şekilde %60'a sabitle.
  return math.max(breakT + 0.08, 0.6);
}

MealCycleArc mealCycleArc({
  required int fastMinutes,
  required int eatMinutes,
  int? fastElapsedMinutes,
  int? eatElapsedMinutes,
  double? minGap,

  /// Oruç hedefi doldu: tüm işaretler renkli (yeme penceresi açılmasa da).
  bool forceAllReached = false,
}) {
  final fast = fastMinutes > 0 ? fastMinutes : 960;
  final eat = eatMinutes > 0 ? eatMinutes : math.max(60, 1440 - fast);
  final gap = minGap ?? mealArcMinGap(fast, eat);

  final eatingIdx = eatElapsedMinutes == null
      ? -1
      : eatingStageIndex(eatElapsedMinutes, eat);

  const nextT = 1.0;
  const eps = 1e-9;
  final breakT = mealArcBreakT(fast, eat);
  double? nourishT = mealArcNourishT(fast, eat);
  if (nourishT - breakT < gap - eps) {
    nourishT = breakT + gap;
  }
  // Sonraki oruçla çakışmasın; yine de mümkünse %60'a yakın tut.
  if (nextT - nourishT < gap - eps) {
    nourishT = nextT - gap;
  }
  if (nourishT - breakT < gap - eps) nourishT = null;
  final showNext = nextT - (nourishT ?? breakT) >= gap - eps;

  // İlerleme: oruç 0→breakT, yeme breakT→1 (işaretlerle hizalı).
  final double progress;
  if (eatElapsedMinutes != null) {
    final eatP = (eatElapsedMinutes / eat).clamp(0.0, 1.0);
    progress = breakT + (1.0 - breakT) * eatP;
  } else if (fastElapsedMinutes != null) {
    final fastP = (fastElapsedMinutes / fast).clamp(0.0, 1.0);
    progress = breakT * fastP;
  } else {
    progress = 0;
  }

  ArcStage marker(
    int index,
    double t, {
    required bool reached,
    bool current = false,
  }) {
    // index: 1 orucunu boz, 2 besle, 3 sonraki oruç (0 kullanılmıyor).
    // Kum saati (darkFast) yalnızca "sonraki oruç"; break'te salata ikonu.
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
      marker(
        1,
        breakT,
        reached: forceAllReached || eatingIdx >= 0,
        current: !forceAllReached && eatingIdx == 0,
      ),
      if (nourishT != null)
        marker(
          2,
          nourishT,
          reached: forceAllReached || eatingIdx >= 1,
          current: !forceAllReached && eatingIdx == 1,
        ),
      if (showNext)
        marker(
          3,
          nextT,
          reached: forceAllReached || eatingIdx >= 2,
          current: !forceAllReached && eatingIdx == 2,
        ),
    ],
  );
}
