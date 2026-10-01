import 'dart:async';

import 'package:fastingapp/generated/assets.gen.dart';
import 'package:fastingapp/presentation/home_widgets/fasting_detail_widget_view.dart';
import 'package:fastingapp/presentation/home_widgets/fasting_home_widget_view.dart';
import 'package:fastingapp/presentation/home_widgets/fasting_medium_widget_view.dart';
import 'package:flutter/painting.dart';
import 'package:home_widget/home_widget.dart';

/// Oruç widget görselini ve kalan süreyi yazar.
abstract final class FastingWidgetSync {
  static const imageKey = 'fasting_widget_image';
  static const mediumImageKey = 'fasting_widget_medium_image';
  static const detailImageKey = 'fasting_widget_detail_image';
  static const activeKey = 'fasting_active';
  static const startKey = 'fasting_start_ms';
  static const endKey = 'fasting_end_ms';
  static const planKey = 'fasting_plan_label';

  static String? _statusFasting;
  static String? _statusEating;
  static String? _leftLabel;
  static String? _headlineFasting;
  static String? _headlineEating;
  static String? _planLabel;
  static String? _startCaption;
  static String? _endCaption;
  static String? _goalCaption;
  static String? _hoursTemplate;
  static String? _praise;
  static String _localeName = 'en';
  static Timer? _ticker;

  static Future<void> publish({
    required bool isFasting,
    required String statusLabel,
    required String leftLabel,
    DateTime? start,
    DateTime? end,
    String? statusFasting,
    String? statusEating,
    String? headlineFasting,
    String? headlineEating,
    String? planLabel,
  }) async {
    _statusFasting = statusFasting ?? _statusFasting ?? statusLabel;
    _statusEating = statusEating ?? _statusEating;
    _leftLabel = leftLabel;
    _headlineFasting = headlineFasting ?? _headlineFasting;
    _headlineEating = headlineEating ?? _headlineEating;
    _planLabel = planLabel ?? _planLabel;
    try {
      await HomeWidget.setAppGroupId('group.com.flywork.fastingapp');
      await HomeWidget.saveWidgetData<int>(activeKey, isFasting ? 1 : 0);
      await HomeWidget.saveWidgetData<int>(
        startKey,
        start?.millisecondsSinceEpoch ?? 0,
      );
      await HomeWidget.saveWidgetData<int>(
        endKey,
        end?.millisecondsSinceEpoch ?? 0,
      );
      await HomeWidget.saveWidgetData<String>(planKey, _planLabel ?? '16:8');
      await _render(
        isFasting: isFasting,
        start: start,
        end: end,
        statusLabel: statusLabel,
        leftLabel: leftLabel,
      );
      _ensureTicker();
    } on Object {
      // Widget imzası hazır değilse uygulama akışı sürer.
    }
  }

  static void rememberLabels({
    required String fasting,
    required String eating,
    required String left,
    required String headlineFasting,
    required String headlineEating,
    required String startCaption,
    required String endCaption,
    required String goalCaption,
    required String hoursTemplate,
    required String praise,
    required String localeName,
  }) {
    _statusFasting = fasting;
    _statusEating = eating;
    _leftLabel = left;
    _headlineFasting = headlineFasting;
    _headlineEating = headlineEating;
    _startCaption = startCaption;
    _endCaption = endCaption;
    _goalCaption = goalCaption;
    _hoursTemplate = hoursTemplate;
    _praise = praise;
    _localeName = localeName;
    _ensureTicker();
  }

  static Future<void> refresh() async {
    final fasting = _statusFasting;
    final eating = _statusEating;
    final left = _leftLabel;
    if (fasting == null || eating == null || left == null) return;
    try {
      await HomeWidget.setAppGroupId('group.com.flywork.fastingapp');
      final active = await _readInt(activeKey);
      final startMs = await _readInt(startKey);
      final endMs = await _readInt(endKey);
      final plan = await _readString(planKey);
      if (plan != null && plan.isNotEmpty) _planLabel = plan;
      final isFasting = active == 1;
      await _render(
        isFasting: isFasting,
        start: _date(startMs),
        end: _date(endMs),
        statusLabel: isFasting ? fasting : eating,
        leftLabel: left,
      );
    } on Object {
      // Zamanlayıcı hatası ekranı bozmasın.
    }
  }

  static Future<void> _render({
    required bool isFasting,
    required String statusLabel,
    required String leftLabel,
    DateTime? start,
    DateTime? end,
  }) async {
    final now = DateTime.now();
    final total = start == null || end == null
        ? Duration.zero
        : end.difference(start);
    final left = end == null ? Duration.zero : end.difference(now);
    final remaining = left.isNegative ? Duration.zero : left;
    final progress = !isFasting || total.inSeconds <= 0
        ? 0.0
        : (1 - remaining.inSeconds / total.inSeconds).clamp(0, 1).toDouble();
    final clock = _clock(remaining);
    final headline = isFasting
        ? (_headlineFasting ?? statusLabel)
        : (_headlineEating ?? statusLabel);
    await _warmAssets();
    await HomeWidget.renderFlutterWidget(
      FastingHomeWidgetView(
        timeLabel: clock,
        leftLabel: leftLabel,
        statusLabel: statusLabel,
        progress: progress,
      ),
      key: imageKey,
      logicalSize: FastingHomeWidgetView.logicalSize,
      pixelRatio: 2,
    );
    await HomeWidget.renderFlutterWidget(
      FastingMediumWidgetView(
        headline: headline,
        timeLabel: '$clock $leftLabel',
        planLabel: _planLabel ?? '16:8',
      ),
      key: mediumImageKey,
      logicalSize: FastingMediumWidgetView.logicalSize,
      pixelRatio: 2,
    );
    await HomeWidget.updateWidget(
      androidName: 'FastingWidgetProvider',
      iOSName: 'FastingWidget',
    );
    await HomeWidget.updateWidget(
      androidName: 'FastingWidgetMediumProvider',
      iOSName: 'FastingCardWidget',
    );
    final hours = _goalHours(start, end);
    final goalText = (_hoursTemplate ?? '{} hours').replaceAll('{}', '$hours');
    await HomeWidget.renderFlutterWidget(
      FastingDetailWidgetView(
        timeLabel: clock,
        leftLabel: leftLabel,
        progress: progress,
        startCaption: _startCaption ?? 'Start',
        endCaption: _endCaption ?? 'End',
        goalCaption: _goalCaption ?? 'Goal',
        startValue: _dayClock(start),
        endValue: _dayClock(end),
        goalValue: goalText,
        praise: _praise ?? "You're doing great!",
      ),
      key: detailImageKey,
      logicalSize: FastingDetailWidgetView.logicalSize,
      pixelRatio: 2,
    );
    await HomeWidget.updateWidget(
      androidName: 'FastingWidgetDetailProvider',
      iOSName: 'FastingDetailWidget',
    );
  }

  static int _goalHours(DateTime? start, DateTime? end) {
    if (start != null && end != null) {
      final hours = end.difference(start).inHours;
      if (hours > 0) return hours;
    }
    final plan = _planLabel;
    if (plan != null) {
      final head = plan.split(':').first.trim();
      final parsed = int.tryParse(head);
      if (parsed != null && parsed > 0) return parsed;
    }
    return 16;
  }

  static String _dayClock(DateTime? time) {
    if (time == null) return '—';
    final minute = time.minute.toString().padLeft(2, '0');
    if (!_localeName.startsWith('en')) {
      final hour = time.hour.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final suffix = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  static Future<void> _warmAssets() {
    const config = ImageConfiguration(devicePixelRatio: 2);
    return Future.wait([
      _warm(Assets.images.widget1.provider(), config),
      _warm(Assets.images.widget2.provider(), config),
      _warm(Assets.images.start.provider(), config),
      _warm(Assets.images.end.provider(), config),
      _warm(Assets.images.hours.provider(), config),
    ]);
  }

  static Future<void> _warm(ImageProvider provider, ImageConfiguration config) {
    final completer = Completer<void>();
    final stream = provider.resolve(config);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete();
      },
      onError: (Object error, StackTrace? stackTrace) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete();
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  static Future<String?> _readString(String key) async {
    final raw = await HomeWidget.getWidgetData<String>(key);
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  static void _ensureTicker() {
    _ticker ??= Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(refresh());
    });
  }

  static Future<int?> _readInt(String key) async {
    final raw = await HomeWidget.getWidgetData<dynamic>(key);
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return null;
  }

  static DateTime? _date(int? millis) {
    if (millis == null || millis <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  static String _clock(Duration duration) {
    final minutes = duration.inMinutes;
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '$hours:${mins.toString().padLeft(2, '0')}';
  }
}
