import 'package:flutter/foundation.dart';
import 'package:fastingapp/presentation/plans/plans_catalog.dart';

/// Plan detay sayfası nav argümanları.
@immutable
final class PlanDetailArgs {
  const PlanDetailArgs({
    required this.plan,
    this.pageTitleKey = 'plans.detail_beginner_title',
  });

  final PlansCardData plan;
  final String pageTitleKey;

  /// Figma: kahvaltı atla → 12:00–18:00.
  int get eatStartHour {
    return switch (plan.tone) {
      PlansChipTone.breakfast => 12,
      PlansChipTone.dinner => 12,
      PlansChipTone.advanced => 14,
    };
  }

  /// Yemek penceresi süresi (saat). Zamanlar ve barlar buna göre.
  int get eatHours {
    // Figma: 12:00–18:00 → 6 saat (title 16-8 olsa bile görsel bu).
    if (plan.tone == PlansChipTone.breakfast ||
        plan.tone == PlansChipTone.dinner) {
      return 6;
    }
    final parts = plan.title.split('-');
    if (parts.length == 2) {
      final eat = int.tryParse(parts[1]);
      if (eat != null) return eat;
    }
    return 6;
  }

  int get eatEndHour => (eatStartHour + eatHours) % 24;

  /// Gauge oranı için title'daki oruç saati (16-8 → 16).
  int get fastHours {
    final parts = plan.title.split('-');
    if (parts.length == 2) {
      final fast = int.tryParse(parts[0]);
      if (fast != null) return fast;
    }
    return 16;
  }

  /// Gauge yeşil oranı için title'daki yemek saati (16-8 → 8).
  int get ratioEatHours {
    final parts = plan.title.split('-');
    if (parts.length == 2) {
      final eat = int.tryParse(parts[1]);
      if (eat != null) return eat;
    }
    return 8;
  }
}
