import 'dart:async';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/home_widgets/fasting_widget_sync.dart';
import 'package:fastingapp/core/router/app_router.dart';
import 'package:fastingapp/core/router/deep_link_gate.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/presentation/home_widgets/water_home_widget_view.dart';
import 'package:fastingapp/presentation/home_widgets/water_large_widget_view.dart';
import 'package:fastingapp/presentation/home_widgets/water_medium_widget_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:home_widget/home_widget.dart';

/// Ana ekran widget'ına yazılan tek bir su kaydı.
@immutable
final class WaterWidgetSip {
  const WaterWidgetSip({required this.ml, required this.at});

  final int ml;
  final DateTime at;
}

/// Su miktarını ana ekran widget'larına yazar.
abstract final class WaterWidgetSync {
  static const groupId = 'group.com.flywork.mochifast';
  static const imageKey = 'water_widget_image';
  static const mediumImageKey = 'water_widget_medium_image';
  static const largeImageKey = 'water_widget_large_image';
  static const currentKey = 'water_current_ml';
  static const goalKey = 'water_goal_ml';
  static const addKey = 'water_add_ml';
  static const timelineKey = 'water_timeline';
  static const weekKey = 'water_week';

  /// [currentKey]/[timelineKey]'in ait olduğu yerel gün (`yyyy-MM-dd`);
  /// gün dönünce eski toplam bugünün değeri sanılmaz.
  static const dateKey = 'water_date';
  static const defaultCurrentMl = 0;
  static const defaultGoalMl = 2500;
  static const defaultAddMl = 300;

  static Future<
    ({int currentMl, int goalMl, int addMl, List<WaterWidgetSip> sips})?
  >
  read() async {
    try {
      await HomeWidget.setAppGroupId(groupId);
      final current = await _readInt(currentKey);
      final goal = await _readInt(goalKey);
      if (current == null && goal == null) return null;
      final add = await _readInt(addKey);
      final rawTimeline = await HomeWidget.getWidgetData<dynamic>(timelineKey);
      final savedDay = await HomeWidget.getWidgetData<dynamic>(dateKey);
      final isToday = savedDay == _dayKey(DateTime.now());
      return (
        currentMl: isToday ? (current ?? defaultCurrentMl) : defaultCurrentMl,
        goalMl: goal ?? defaultGoalMl,
        addMl: add ?? defaultAddMl,
        sips: isToday ? _decodeSips(rawTimeline) : const <WaterWidgetSip>[],
      );
    } on Object {
      return null;
    }
  }

  /// Kullanıcının su birimi (`ml` | `oz`). Değerler hep ml saklanır,
  /// görselde birime çevrilir (önceden oz seçilse de widget ml yazıyordu).
  static String _unit = 'ml';
  static String _ozLabel = 'oz';

  static const _mlPerOz = 29.5735295625;

  static int _shown(int ml) => _unit == 'oz' ? (ml / _mlPerOz).round() : ml;

  /// Birim değişince widget yeniden çizilir. [ozLabel] çevrili "oz".
  static Future<void> setUnit(String unit, {String? ozLabel}) async {
    if (ozLabel != null) _ozLabel = ozLabel;
    if (unit == _unit) return;
    _unit = unit;
    final republish = _republish;
    if (republish != null) await republish();
  }

  static Future<void> publish({
    required String goalLabel,
    required String unitLabel,
    required String timelineLabel,
    required String addTemplate,
    required String localeName,
    required String largeTitle,
    required String largeSubtitle,
    required String intakeLabel,
    required String percentTemplate,
    required String weeklyLabel,
    required String historyLabel,
    required String reminderLabel,
    required String addWaterLabel,
    required String weekdays,
    int? currentMl,
    int? goalMl,
    int? addMl,
    List<WaterWidgetSip>? sips,
    bool render = true,
  }) async {
    // Etiketler saklanır: uygulama kökü özet geldikçe [updateToday] ile
    // aynı dilde yeniden çizebilir.
    _republish = ({int? currentMl, int? goalMl}) => publish(
      goalLabel: goalLabel,
      unitLabel: unitLabel,
      timelineLabel: timelineLabel,
      addTemplate: addTemplate,
      localeName: localeName,
      largeTitle: largeTitle,
      largeSubtitle: largeSubtitle,
      intakeLabel: intakeLabel,
      percentTemplate: percentTemplate,
      weeklyLabel: weeklyLabel,
      historyLabel: historyLabel,
      reminderLabel: reminderLabel,
      addWaterLabel: addWaterLabel,
      weekdays: weekdays,
      currentMl: currentMl,
      goalMl: goalMl,
    );
    // Yalnızca etiketleri hatırla (açılışta resim üretme; widget zaten çizili).
    if (!render) return;
    try {
      await HomeWidget.setAppGroupId(groupId);
      final saved = await read();
      final current = currentMl ?? saved?.currentMl ?? defaultCurrentMl;
      final goal = goalMl ?? saved?.goalMl ?? defaultGoalMl;
      final add = addMl ?? saved?.addMl ?? defaultAddMl;
      final timeline = sips ?? saved?.sips ?? const <WaterWidgetSip>[];
      await HomeWidget.saveWidgetData<int>(currentKey, current);
      await HomeWidget.saveWidgetData<String>(dateKey, _dayKey(DateTime.now()));
      await HomeWidget.saveWidgetData<int>(goalKey, goal);
      await HomeWidget.saveWidgetData<int>(addKey, add);
      await HomeWidget.saveWidgetData<String>(
        timelineKey,
        _encodeSips(timeline),
      );
      final rawWeek = await HomeWidget.getWidgetData<dynamic>(weekKey);
      final week = _mergeWeek(_decodeWeek(rawWeek), current);
      await HomeWidget.saveWidgetData<String>(weekKey, _encodeWeek(week));
      final shown = [
        for (final sip in timeline)
          (ml: _shown(sip.ml), timeLabel: _formatTime(sip.at, localeName)),
      ];
      final addLabel = addTemplate
          .replaceFirst('{}', '${_shown(add)}')
          .replaceAll(unitLabel, _unit == 'oz' ? _ozLabel : unitLabel);
      final unitText = _unit == 'oz' ? _ozLabel : unitLabel;
      await HomeWidget.renderFlutterWidget(
        WaterHomeWidgetView(
          currentMl: _shown(current),
          goalMl: _shown(goal),
          goalLabel: goalLabel,
          unitLabel: unitText,
        ),
        key: imageKey,
        logicalSize: WaterHomeWidgetView.logicalSize,
        pixelRatio: 2,
      );
      await HomeWidget.renderFlutterWidget(
        WaterMediumWidgetView(
          currentMl: _shown(current),
          goalMl: _shown(goal),
          goalLabel: goalLabel,
          unitLabel: unitText,
          timelineLabel: timelineLabel,
          addLabel: addLabel,
          sips: shown,
        ),
        key: mediumImageKey,
        logicalSize: WaterMediumWidgetView.logicalSize,
        pixelRatio: 2,
      );
      await _renderLarge(
        current: current,
        goal: goal,
        unitLabel: unitText,
        largeTitle: largeTitle,
        largeSubtitle: largeSubtitle,
        intakeLabel: intakeLabel,
        percentTemplate: percentTemplate,
        weeklyLabel: weeklyLabel,
        historyLabel: historyLabel,
        reminderLabel: reminderLabel,
        addWaterLabel: addWaterLabel,
        weekdays: weekdays,
      );
      await HomeWidget.updateWidget(
        androidName: 'WaterWidgetProvider',
        iOSName: 'WaterWidget',
      );
      await HomeWidget.updateWidget(
        androidName: 'WaterWidgetMediumProvider',
        iOSName: 'WaterWidget',
      );
      await HomeWidget.updateWidget(
        androidName: 'WaterWidgetLargeProvider',
        iOSName: 'WaterWidget',
      );
    } on Object {
      // Widget imzası hazır değilse uygulama akışı sürer.
    }
  }

  static Future<void> Function({int? currentMl, int? goalMl})? _republish;
  static int? _lastTodayMl;
  static int? _lastGoalMl;

  /// Bugünün toplamı (ör. `/user/summary.today.water`) değiştiyse widget'ı
  /// yeniden çizer. Etiketler henüz yoksa (ilk açılış) bir şey yapmaz.
  static Future<void> updateToday({required int currentMl, int? goalMl}) async {
    final republish = _republish;
    if (republish == null) return;
    if (currentMl == _lastTodayMl && goalMl == _lastGoalMl) return;
    _lastTodayMl = currentMl;
    _lastGoalMl = goalMl;
    await republish(currentMl: currentMl, goalMl: goalMl);
  }

  /// Çıkış / hesap değişimi: önceki kullanıcının su verisi (bugün, son
  /// kayıtlar, hafta) silinir; etiketler biliniyorsa 0 ile yeniden çizilir.
  static Future<void> clear() async {
    _lastTodayMl = null;
    _lastGoalMl = null;
    try {
      await HomeWidget.setAppGroupId(groupId);
      for (final key in [currentKey, timelineKey, weekKey, dateKey]) {
        await HomeWidget.saveWidgetData<String>(key, null);
      }
    } on Object {
      return;
    }
    final republish = _republish;
    if (republish != null) await republish(currentMl: 0);
  }

  static Future<void> _renderLarge({
    required int current,
    required int goal,
    required String unitLabel,
    required String largeTitle,
    required String largeSubtitle,
    required String intakeLabel,
    required String percentTemplate,
    required String weeklyLabel,
    required String historyLabel,
    required String reminderLabel,
    required String addWaterLabel,
    required String weekdays,
  }) async {
    final rawWeek = await HomeWidget.getWidgetData<dynamic>(weekKey);
    final week = _decodeWeek(rawWeek);
    final percent = goal <= 0
        ? 0
        : ((current / goal) * 100).round().clamp(0, 100);
    final labels = weekdays.split(',');
    ui.Picture? bell;
    try {
      final info = await vg.loadPicture(
        SvgAssetLoader(Assets.icons.solarBellLineDuotone.path),
        null,
      );
      bell = info.picture;
    } on Object {
      bell = null;
    }
    try {
      await HomeWidget.renderFlutterWidget(
        WaterLargeWidgetView(
          currentMl: _shown(current),
          goalMl: _shown(goal),
          unitLabel: unitLabel,
          title: largeTitle,
          subtitle: largeSubtitle,
          intakeLabel: intakeLabel,
          percentLabel: percentTemplate.replaceFirst('{}', '$percent'),
          weeklyLabel: weeklyLabel,
          historyLabel: historyLabel,
          reminderLabel: reminderLabel,
          addWaterLabel: addWaterLabel,
          weekdayLabels: labels,
          weekProgress: _weekProgress(week, goal),
          todayIndex: DateTime.now().weekday - 1,
          bell: bell,
        ),
        key: largeImageKey,
        logicalSize: WaterLargeWidgetView.logicalSize,
        pixelRatio: 2,
      );
    } finally {
      bell?.dispose();
    }
  }

  static Future<int?> _readInt(String key) async {
    final raw = await HomeWidget.getWidgetData<dynamic>(key);
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return null;
  }

  static String _encodeSips(List<WaterWidgetSip> sips) {
    return sips
        .map((sip) => '${sip.ml}@${sip.at.millisecondsSinceEpoch}')
        .join(',');
  }

  static List<WaterWidgetSip> _decodeSips(dynamic raw) {
    if (raw is! String || raw.isEmpty) return const [];
    final sips = <WaterWidgetSip>[];
    for (final part in raw.split(',')) {
      final bits = part.split('@');
      if (bits.length != 2) continue;
      final ml = int.tryParse(bits[0]);
      final at = int.tryParse(bits[1]);
      if (ml == null || at == null) continue;
      sips.add(
        WaterWidgetSip(ml: ml, at: DateTime.fromMillisecondsSinceEpoch(at)),
      );
    }
    return sips;
  }

  static String _dayKey(DateTime day) {
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '${day.year}-$month-$date';
  }

  static Map<String, int> _decodeWeek(dynamic raw) {
    if (raw is! String || raw.isEmpty) return {};
    final week = <String, int>{};
    for (final part in raw.split(',')) {
      final bits = part.split('|');
      if (bits.length != 2) continue;
      final ml = int.tryParse(bits[1]);
      if (ml == null) continue;
      week[bits[0]] = ml;
    }
    return week;
  }

  /// Sunucu haftası (`/water/week`): uygulamanın açılmadığı günler de
  /// dolsun (önceden yalnızca uygulamanın gördüğü günler vardı).
  static Future<void> saveServerWeek(Map<String, int> days) async {
    if (days.isEmpty) return;
    try {
      await HomeWidget.setAppGroupId(groupId);
      final raw = await HomeWidget.getWidgetData<dynamic>(weekKey);
      final week = {..._decodeWeek(raw), ...days};
      await HomeWidget.saveWidgetData<String>(weekKey, _encodeWeek(week));
    } on Object {
      return;
    }
    final republish = _republish;
    if (republish != null) await republish();
  }

  static Map<String, int> _mergeWeek(Map<String, int> saved, int currentMl) {
    final week = Map<String, int>.of(saved);
    week[_dayKey(DateTime.now())] = currentMl;
    return week;
  }

  static String _encodeWeek(Map<String, int> week) {
    final cutoff = DateTime.now().subtract(const Duration(days: 21));
    final kept = week.entries.where((entry) {
      final day = DateTime.tryParse(entry.key);
      return day != null && !day.isBefore(cutoff);
    });
    return kept.map((entry) => '${entry.key}|${entry.value}').join(',');
  }

  static List<double> _weekProgress(Map<String, int> week, int goal) {
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return [
      for (var i = 0; i < 7; i++)
        goal <= 0
            ? 0.0
            : ((week[_dayKey(monday.add(Duration(days: i)))] ?? 0) / goal)
                  .clamp(0.0, 1.0),
    ];
  }

  static String _formatTime(DateTime at, String localeName) {
    final local = at.toLocal();
    final minute = local.minute.toString().padLeft(2, '0');
    if (localeName.startsWith('en')) {
      final suffix = local.hour >= 12 ? 'pm' : 'am';
      final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
      return '$hour:$minute $suffix';
    }
    final hour = local.hour.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Widget dokunuşunda su sayfasını açar.
final class WaterWidgetTapHandler extends StatefulWidget {
  const WaterWidgetTapHandler({required this.child, super.key});

  final Widget child;

  @override
  State<WaterWidgetTapHandler> createState() => _WaterWidgetTapHandlerState();
}

class _WaterWidgetTapHandlerState extends State<WaterWidgetTapHandler> {
  static final _waterUri = Uri.parse('fastingapp://water?homeWidget');

  StreamSubscription<Uri?>? _clicks;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_openInitial());
    });
    _clicks = HomeWidget.widgetClicked.listen(
      (uri) => unawaited(_openWater(uri)),
    );
  }

  @override
  void dispose() {
    unawaited(_clicks?.cancel());
    super.dispose();
  }

  Future<void> _openInitial() async {
    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (!mounted) return;
    await _openWater(uri);
  }

  Future<void> _openWater(Uri? uri) async {
    if (uri == null) return;
    if (!await DeepLinkGate.ready() || !mounted) return;
    if (uri.host == 'fasting') {
      if (appRouter.state.uri.path == RoutePaths.fasting.path) return;
      appRouter.go(RoutePaths.fasting.path);
      return;
    }
    if (uri.host != _waterUri.host) return;
    final path = appRouter.state.uri.path;
    if (path == RoutePaths.water.path ||
        path.startsWith('${RoutePaths.water.path}/')) {
      return;
    }
    appRouter.push(RoutePaths.water.path);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Çeviriler yüklendikten sonra su widget görsellerini basar.
final class WaterWidgetLocaleSync extends StatefulWidget {
  const WaterWidgetLocaleSync({required this.child, super.key});

  final Widget child;

  @override
  State<WaterWidgetLocaleSync> createState() => _WaterWidgetLocaleSyncState();
}

class _WaterWidgetLocaleSyncState extends State<WaterWidgetLocaleSync> {
  static const _goalKey = 'water_reminder.daily_goal';
  static const _unitKey = 'water_reminder.unit_ml';
  static const _timelineKey = 'water_page.timeline';
  static const _addKey = 'water_page.widget_add';
  static const _titleKey = 'water_page.widget_title';
  static const _subtitleKey = 'water_page.widget_subtitle';
  static const _intakeKey = 'water_page.current_intake';
  static const _percentKey = 'water_page.percent_reached';
  static const _weeklyKey = 'water_page.weekly';
  static const _historyKey = 'water_page.view_history';
  static const _reminderKey = 'water_page.next_reminder';
  static const _addWaterKey = 'water_page.add_water';
  static const _weekdaysKey = 'water_page.weekdays';

  Locale? _syncedLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = context.locale;
    if (_syncedLocale == locale) return;
    final goal = _goalKey.tr(context: context);
    final unit = _unitKey.tr(context: context);
    unawaited(
      WaterWidgetSync.setUnit(
        WaterWidgetSync._unit,
        ozLabel: 'water_reminder.unit_oz'.tr(context: context),
      ),
    );
    final timeline = _timelineKey.tr(context: context);
    final add = _addKey.tr(context: context);
    final title = _titleKey.tr(context: context);
    final subtitle = _subtitleKey.tr(context: context);
    final intake = _intakeKey.tr(context: context);
    final percent = _percentKey.tr(context: context);
    final weekly = _weeklyKey.tr(context: context);
    final history = _historyKey.tr(context: context);
    final reminder = _reminderKey.tr(context: context);
    final addWater = _addWaterKey.tr(context: context);
    final weekdays = _weekdaysKey.tr(context: context);
    if (goal == _goalKey ||
        unit == _unitKey ||
        timeline == _timelineKey ||
        add == _addKey ||
        title == _titleKey) {
      return;
    }
    // İlk açılışta widget'lar zaten çizili: yalnızca etiketler hatırlanır
    // (açılışta 9 resim üretmek ilk kareleri takıltıyordu). Dil sonradan
    // değişirse yeniden çizilir.
    final render = _syncedLocale != null;
    _syncedLocale = locale;
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
      localeName: locale.languageCode,
      todaysPlanTitle: 'fasting_page.widget_todays_plan'.tr(context: context),
      startFastingCta: 'fasting_page.widget_start_fasting'.tr(context: context),
      todayLabel: 'fasting_page.widget_today'.tr(context: context),
      cheerLabel: 'fasting_page.widget_lets_do_this'.tr(context: context),
      thisWeekTitle: 'fasting_page.widget_this_week'.tr(context: context),
      weekCheer: 'fasting_page.widget_keep_going'.tr(context: context),
      weekdays: 'water_page.weekdays'.tr(context: context),
    );
    if (render) unawaited(FastingWidgetSync.refresh());
    unawaited(
      WaterWidgetSync.publish(
        render: render,
        goalLabel: goal,
        unitLabel: unit,
        timelineLabel: timeline,
        addTemplate: add,
        localeName: locale.languageCode,
        largeTitle: title,
        largeSubtitle: subtitle,
        intakeLabel: intake,
        percentTemplate: percent,
        weeklyLabel: weekly,
        historyLabel: history,
        reminderLabel: reminder,
        addWaterLabel: addWater,
        weekdays: weekdays,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
