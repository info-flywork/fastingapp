import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/home_widgets/fasting_widget_sync.dart';
import 'package:fastingapp/presentation/fasting/bloc/fasting_session_state.dart';
import 'package:flutter/widgets.dart';

/// Oruç durumunu ana ekran widget'ına yazar (etiketler o anki dilde).
/// Uygulama kökü (`AppSyncScope`) cubit her değiştiğinde çağırır; oruç
/// ekranı da kendi yerel geçişlerinde (öğün seçimi vb.) çağırabilir.
void publishFastingWidget(BuildContext context, FastingSessionState session) {
  final planTitle = session.planTitle;
  final total = Duration(
    minutes:
        session.plan?.fastMinutes ??
        session.fast?.targetMinutes ??
        _planHoursOf(planTitle) * 60,
  );
  final fasting = session.isFasting;
  final eat = fasting ? null : session.eatingWindow;
  final fastStart = session.fast?.startedAt;
  final fastEnd = session.fast?.plannedEndAt ?? fastStart?.add(total);
  // Yeme penceresinde geri sayım pencerenin sonuna.
  final start = fasting ? fastStart : eat?.startedAt;
  final end = fasting ? fastEnd : eat?.endsAt;
  // Plan widget'ı: sürmekte olan ya da sıradaki oruç (önceden sabit 20:00).
  final nextStart = fasting
      ? fastStart
      : eat?.suggestedNextStartAt ??
            eat?.endsAt ??
            _todayAt(session.plan?.eatWindow?.end);
  final nextEnd = fasting ? fastEnd : nextStart?.add(total);
  FastingWidgetSync.rememberLabels(
    fasting: 'fasting_page.widget_fasting'.tr(context: context),
    eating: 'fasting_page.widget_eating'.tr(context: context),
    left: 'fasting_page.widget_left'.tr(context: context),
    headlineFasting: 'fasting_page.widget_you_fasting'.tr(context: context),
    headlineEating: 'fasting_page.widget_you_eating'.tr(context: context),
    startCaption: 'fasting_page.widget_start'.tr(context: context),
    endCaption: 'fasting_page.widget_end'.tr(context: context),
    goalCaption: 'fasting_page.widget_goal'.tr(context: context),
    hoursTemplate: 'fasting_page.widget_hours'.tr(context: context),
    praise: 'fasting_page.widget_great'.tr(context: context),
    localeName: context.locale.languageCode,
    todaysPlanTitle: 'fasting_page.widget_todays_plan'.tr(context: context),
    startFastingCta: 'fasting_page.widget_start_fasting'.tr(context: context),
    todayLabel: 'fasting_page.widget_today'.tr(context: context),
    cheerLabel: 'fasting_page.widget_lets_do_this'.tr(context: context),
    thisWeekTitle: 'fasting_page.widget_this_week'.tr(context: context),
    weekCheer: 'fasting_page.widget_keep_going'.tr(context: context),
    weekdays: 'water_page.weekdays'.tr(context: context),
  );
  unawaited(
    FastingWidgetSync.publish(
      isFasting: fasting,
      start: start,
      end: end,
      statusLabel: fasting
          ? 'fasting_page.widget_fasting'.tr(context: context)
          : 'fasting_page.widget_eating'.tr(context: context),
      leftLabel: 'fasting_page.widget_left'.tr(context: context),
      statusFasting: 'fasting_page.widget_fasting'.tr(context: context),
      statusEating: 'fasting_page.widget_eating'.tr(context: context),
      headlineFasting: 'fasting_page.widget_you_fasting'.tr(context: context),
      headlineEating: 'fasting_page.widget_you_eating'.tr(context: context),
      planLabel: planTitle.replaceAll('-', ':'),
      planStart: nextStart,
      planEnd: nextEnd,
    ),
  );
}

int _planHoursOf(String title) {
  final head = title.split('-').first.trim();
  return int.tryParse(head) ?? 16;
}

/// Bugünün `HH:mm` saati (plan penceresinin bitişi = oruç başlangıcı).
DateTime? _todayAt(String? hm) {
  final parts = hm?.split(':');
  if (parts == null || parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, h, m);
}
