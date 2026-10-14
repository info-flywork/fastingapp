import 'package:fastingapp/presentation/plans/plans_catalog.dart';
import 'package:flutter/foundation.dart';

/// Plan detay sayfası nav argümanları.
@immutable
final class PlanDetailArgs {
  const PlanDetailArgs({
    required this.plan,
    this.pageTitleKey = 'plans.detail_beginner_title',
  });

  final PlansCardData plan;
  final String pageTitleKey;

  /// Varsayılan yeme penceresi başlangıcı (backend `TIMING_EAT_START`):
  /// kahvaltı atla 12:00, akşam yemeği atla 08:00; zamanlamasız ileri
  /// planlar sunucu varsayılanı kahvaltı atla → 12:00.
  int get eatStartHour {
    return switch (plan.tone) {
      PlansChipTone.breakfast => 12,
      PlansChipTone.dinner => 8,
      PlansChipTone.advanced => 12,
    };
  }

  /// Planın oruç saati (`16-8` → 16, `OMAD` → 23).
  int get fastHours {
    if (plan.planCode == 'omad') return 23;
    final fast = int.tryParse(plan.title.split('-').first);
    return fast ?? 16;
  }

  /// Yeme penceresi süresi (saat) = 24 − oruç. Hazır planda sunucu pencere
  /// süresinin plana eşit olmasını ister.
  int get eatHours => 24 - fastHours;

  int get eatEndHour => (eatStartHour + eatHours) % 24;

  /// Gauge yeşil oranı (16-8 → 8).
  int get ratioEatHours => eatHours;
}

/// Plan detayında "Planı başlat" sonucu. [eatStart]/[eatEnd] ("HH:mm")
/// yalnızca kullanıcı yemek penceresini değiştirdiyse dolu (zamanlama
/// `custom` olarak kaydedilir).
@immutable
final class PlanSelection {
  const PlanSelection({required this.plan, this.eatStart, this.eatEnd});

  final PlansCardData plan;
  final String? eatStart;
  final String? eatEnd;

  bool get hasCustomWindow => eatStart != null && eatEnd != null;
}
