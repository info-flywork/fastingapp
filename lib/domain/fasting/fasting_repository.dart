import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/core/utils/enum/request_type.dart';
import 'package:fastingapp/data/model/auth/no_content.dart';
import 'package:uuid/uuid.dart';

/// Oruç çekirdeği (`/v1/fasts/*`, `/v1/plans/current`, `/v1/catalog/stages`).
final class FastingRepository {
  const FastingRepository(this._network);

  final NetworkManager _network;
  static const _uuid = Uuid();

  Future<ActiveFastingSnapshot> getActive() async {
    final result = await _network.send<ActiveFastingSnapshot>(
      path: '/fasts/active',
      method: RequestType.get,
      parserModel: ActiveFastingSnapshot.fromJson,
    );
    return result ?? const ActiveFastingSnapshot();
  }

  Future<CurrentPlanEnvelope> getCurrentPlan() async {
    final result = await _network.send<CurrentPlanEnvelope>(
      path: '/plans/current',
      method: RequestType.get,
      parserModel: CurrentPlanEnvelope.fromJson,
    );
    return result ?? const CurrentPlanEnvelope();
  }

  /// `PUT /plans/current` — bir sonraki oruçtan geçerli. [timing]:
  /// `skipBreakfast` | `skipDinner` | `earlyWindow` | `lateWindow` | `custom`;
  /// [eatStart]/[eatEnd] "HH:mm" (yemek penceresi). Premium plan premium
  /// değilken `402 PREMIUM_REQUIRED`.
  Future<CurrentPlanEnvelope> setCurrentPlan({
    required String planCode,
    String? timing,
    String? eatStart,
    String? eatEnd,
  }) async {
    final result = await _network.send<CurrentPlanEnvelope>(
      path: '/plans/current',
      method: RequestType.put,
      data: {
        'planCode': planCode,
        'timing': ?timing,
        if (eatStart != null) 'eatWindow': {'start': eatStart, 'end': ?eatEnd},
      },
      parserModel: CurrentPlanEnvelope.fromJson,
    );
    return result ?? const CurrentPlanEnvelope();
  }

  Future<ActiveFast> startFast({
    DateTime? startedAt,
    int? targetMinutes,
  }) async {
    final body = <String, dynamic>{
      'id': _uuid.v7(),
      if (startedAt != null) 'startedAt': startedAt.toUtc().toIso8601String(),
      if (targetMinutes != null) 'targetMinutes': targetMinutes,
    };
    final result = await _network.send<_FastEnvelope>(
      path: '/fasts',
      method: RequestType.post,
      data: body,
      parserModel: _FastEnvelope.fromJson,
    );
    final fast = result?.fast;
    if (fast == null) {
      throw StateError('Oruç başlatılamadı');
    }
    return fast;
  }

  /// `POST /fasts/:id/cancel` — istatistiğe girmez; 10 dk içindeyse silinir.
  Future<void> cancelFast(String id) async {
    await _network.send<NoContent>(
      path: '/fasts/$id/cancel',
      method: RequestType.post,
      // Content-Type: application/json iken boş gövde Fastify'da
      // "İstek gövdesi okunamadı" verir; diğer POST'lar gibi {}.
      data: const <String, dynamic>{},
      parserModel: NoContent.fromJson,
    );
  }

  Future<FinishFastResult> finishFast(
    String id, {
    DateTime? endedAt,
    DateTime? startedAt,
    String? feeling,
    String? notes,
    double? weightKg,
  }) async {
    final body = <String, dynamic>{
      if (endedAt != null) 'endedAt': endedAt.toUtc().toIso8601String(),
      if (startedAt != null) 'startedAt': startedAt.toUtc().toIso8601String(),
      if (feeling != null) 'feeling': feeling,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (weightKg != null) 'weightKg': weightKg,
    };
    final result = await _network.send<FinishFastResult>(
      path: '/fasts/$id/finish',
      method: RequestType.post,
      data: body,
      parserModel: FinishFastResult.fromJson,
    );
    if (result == null) throw StateError('Oruç bitirilemedi');
    return result;
  }

  Future<List<FastingStageItem>> getBodyStages() async {
    final result = await _network.send<_StagesEnvelope>(
      path: '/catalog/stages',
      method: RequestType.get,
      queryParameters: const {'type': 'body'},
      parserModel: _StagesEnvelope.fromJson,
    );
    return result?.items ?? const [];
  }
}

final class _FastEnvelope implements BaseModel<_FastEnvelope> {
  const _FastEnvelope({this.fast});

  factory _FastEnvelope.fromJson(Map<String, dynamic> json) {
    final raw = json['fast'];
    return _FastEnvelope(
      fast: raw is Map<String, dynamic> ? ActiveFast.fromJson(raw) : null,
    );
  }

  final ActiveFast? fast;

  @override
  _FastEnvelope fromJson(Map<String, dynamic> json) =>
      _FastEnvelope.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}

final class _StagesEnvelope implements BaseModel<_StagesEnvelope> {
  const _StagesEnvelope({this.items = const []});

  factory _StagesEnvelope.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return _StagesEnvelope(
      items: raw is List
          ? raw
                .whereType<Map<String, dynamic>>()
                .map(FastingStageItem.fromJson)
                .toList()
          : const [],
    );
  }

  final List<FastingStageItem> items;

  @override
  _StagesEnvelope fromJson(Map<String, dynamic> json) =>
      _StagesEnvelope.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}

/// `GET /fasts/active` yanıtı.
final class ActiveFastingSnapshot implements BaseModel<ActiveFastingSnapshot> {
  const ActiveFastingSnapshot({this.fast, this.eatingWindow});

  factory ActiveFastingSnapshot.fromJson(Map<String, dynamic> json) {
    final fastRaw = json['fast'];
    final eatRaw = json['eatingWindow'];
    return ActiveFastingSnapshot(
      fast: fastRaw is Map<String, dynamic>
          ? ActiveFast.fromJson(fastRaw)
          : null,
      eatingWindow: eatRaw is Map<String, dynamic>
          ? EatingWindow.fromJson(eatRaw)
          : null,
    );
  }

  final ActiveFast? fast;
  final EatingWindow? eatingWindow;

  DateTime? get serverTime => fast?.serverTime ?? eatingWindow?.serverTime;

  @override
  ActiveFastingSnapshot fromJson(Map<String, dynamic> json) =>
      ActiveFastingSnapshot.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}

final class ActiveFast implements BaseModel<ActiveFast> {
  const ActiveFast({
    required this.id,
    required this.startedAt,
    required this.plannedEndAt,
    required this.targetMinutes,
    this.planCode,
    this.elapsedMinutes = 0,
    this.progress = 0,
    this.stage,
    this.serverTime,
  });

  factory ActiveFast.fromJson(Map<String, dynamic> json) {
    DateTime? at(Object? v) =>
        v is String ? DateTime.tryParse(v)?.toLocal() : null;
    final stageRaw = json['stage'];
    return ActiveFast(
      id: json['id'] as String? ?? '',
      planCode: json['planCode'] as String?,
      targetMinutes: (json['targetMinutes'] as num?)?.toInt() ?? 0,
      startedAt: at(json['startedAt']) ?? DateTime.now(),
      plannedEndAt: at(json['plannedEndAt']) ?? DateTime.now(),
      elapsedMinutes: (json['elapsedMinutes'] as num?)?.toInt() ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      stage: stageRaw is Map<String, dynamic>
          ? FastStage.fromJson(stageRaw)
          : null,
      serverTime: at(json['serverTime']),
    );
  }

  final String id;
  final String? planCode;
  final int targetMinutes;
  final DateTime startedAt;
  final DateTime plannedEndAt;
  final int elapsedMinutes;
  final double progress;
  final FastStage? stage;
  final DateTime? serverTime;

  @override
  ActiveFast fromJson(Map<String, dynamic> json) => ActiveFast.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}

final class FastStage {
  const FastStage({
    this.position,
    this.title,
    this.rangeLabel,
    this.imageKey,
    this.nextStageAt,
  });

  factory FastStage.fromJson(Map<String, dynamic> json) {
    DateTime? at(Object? v) =>
        v is String ? DateTime.tryParse(v)?.toLocal() : null;
    return FastStage(
      position: (json['position'] as num?)?.toInt(),
      title: json['title'] as String?,
      rangeLabel: json['rangeLabel'] as String?,
      imageKey: json['imageKey'] as String?,
      nextStageAt: at(json['nextStageAt']),
    );
  }

  final int? position;
  final String? title;
  final String? rangeLabel;
  final String? imageKey;
  final DateTime? nextStageAt;
}

final class EatingWindow implements BaseModel<EatingWindow> {
  const EatingWindow({
    required this.startedAt,
    required this.endsAt,
    this.eatMinutes = 0,
    this.elapsedMinutes = 0,
    this.stage,
    this.suggestedNextStartAt,
    this.serverTime,
  });

  factory EatingWindow.fromJson(Map<String, dynamic> json) {
    DateTime? at(Object? v) =>
        v is String ? DateTime.tryParse(v)?.toLocal() : null;
    final stageRaw = json['stage'];
    return EatingWindow(
      startedAt: at(json['startedAt']) ?? DateTime.now(),
      endsAt: at(json['endsAt']) ?? DateTime.now(),
      eatMinutes: (json['eatMinutes'] as num?)?.toInt() ?? 0,
      elapsedMinutes: (json['elapsedMinutes'] as num?)?.toInt() ?? 0,
      stage: stageRaw is Map<String, dynamic>
          ? FastStage.fromJson(stageRaw)
          : null,
      suggestedNextStartAt: at(json['suggestedNextStartAt']),
      serverTime: at(json['serverTime']),
    );
  }

  final DateTime startedAt;
  final DateTime endsAt;
  final int eatMinutes;
  final int elapsedMinutes;
  final FastStage? stage;
  final DateTime? suggestedNextStartAt;
  final DateTime? serverTime;

  @override
  EatingWindow fromJson(Map<String, dynamic> json) =>
      EatingWindow.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}

final class CurrentPlanEnvelope implements BaseModel<CurrentPlanEnvelope> {
  const CurrentPlanEnvelope({this.plan, this.pendingPlanCode});

  factory CurrentPlanEnvelope.fromJson(Map<String, dynamic> json) {
    final planRaw = json['plan'];
    return CurrentPlanEnvelope(
      plan: planRaw is Map<String, dynamic>
          ? UserFastingPlan.fromJson(planRaw)
          : null,
      pendingPlanCode: json['pendingPlanCode'] as String?,
    );
  }

  final UserFastingPlan? plan;
  final String? pendingPlanCode;

  @override
  CurrentPlanEnvelope fromJson(Map<String, dynamic> json) =>
      CurrentPlanEnvelope.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}

final class UserFastingPlan implements BaseModel<UserFastingPlan> {
  const UserFastingPlan({
    this.planCode,
    this.displayName,
    this.fastMinutes = 960,
    this.eatWindow,
    this.timing,
  });

  factory UserFastingPlan.fromJson(Map<String, dynamic> json) {
    final eatRaw = json['eatWindow'];
    return UserFastingPlan(
      planCode: json['planCode'] as String?,
      displayName: json['displayName'] as String?,
      timing: json['timing'] as String?,
      fastMinutes: (json['fastMinutes'] as num?)?.toInt() ?? 960,
      eatWindow: eatRaw is Map<String, dynamic>
          ? EatWindow.fromJson(eatRaw)
          : null,
    );
  }

  final String? planCode;
  final String? displayName;
  final int fastMinutes;
  final EatWindow? eatWindow;

  /// `skipBreakfast` | `skipDinner` | `earlyWindow` | `lateWindow` | `custom`.
  final String? timing;

  String get titleLabel => formatPlanLabel(planCode, displayName);

  int get fastHours => (fastMinutes / 60).round();

  int get eatHours {
    if (eatWindow == null) {
      return (1440 - fastMinutes) ~/ 60;
    }
    return eatWindow!.durationMinutes ~/ 60;
  }

  @override
  UserFastingPlan fromJson(Map<String, dynamic> json) =>
      UserFastingPlan.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}

final class EatWindow {
  const EatWindow({this.start, this.end});

  factory EatWindow.fromJson(Map<String, dynamic> json) =>
      EatWindow(start: json['start'] as String?, end: json['end'] as String?);

  final String? start;
  final String? end;

  int get durationMinutes {
    final s = _parseHm(start);
    final e = _parseHm(end);
    if (s == null || e == null) return 480;
    var diff = e - s;
    if (diff <= 0) diff += 24 * 60;
    return diff;
  }

  static int? _parseHm(String? hm) {
    if (hm == null) return null;
    final parts = hm.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }
}

final class FastingStageItem implements BaseModel<FastingStageItem> {
  const FastingStageItem({
    required this.position,
    this.title,
    this.body,
    this.rangeLabel,
    this.imageKey,
  });

  factory FastingStageItem.fromJson(Map<String, dynamic> json) =>
      FastingStageItem(
        position: (json['position'] as num?)?.toInt() ?? 0,
        title: json['title'] as String?,
        body: json['body'] as String?,
        rangeLabel: json['rangeLabel'] as String?,
        imageKey: json['imageKey'] as String?,
      );

  final int position;
  final String? title;
  final String? body;
  final String? rangeLabel;
  final String? imageKey;

  @override
  FastingStageItem fromJson(Map<String, dynamic> json) =>
      FastingStageItem.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}

final class FinishFastResult implements BaseModel<FinishFastResult> {
  const FinishFastResult({this.isFirstFast = false});

  factory FinishFastResult.fromJson(Map<String, dynamic> json) =>
      FinishFastResult(isFirstFast: json['isFirstFast'] as bool? ?? false);

  final bool isFirstFast;

  @override
  FinishFastResult fromJson(Map<String, dynamic> json) =>
      FinishFastResult.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}

/// Hafta şeridi günü (`GET /user/summary` → `week[]`).
final class SummaryWeekDay implements BaseModel<SummaryWeekDay> {
  const SummaryWeekDay({
    required this.date,
    this.fastedMinutes = 0,
    this.isToday = false,
    this.isFuture = false,
  });

  factory SummaryWeekDay.fromJson(Map<String, dynamic> json) => SummaryWeekDay(
    date: json['date'] as String? ?? '',
    fastedMinutes: (json['fastedMinutes'] as num?)?.toInt() ?? 0,
    isToday: json['isToday'] as bool? ?? false,
    isFuture: json['isFuture'] as bool? ?? false,
  );

  final String date;
  final int fastedMinutes;
  final bool isToday;
  final bool isFuture;

  int get fastedHours => fastedMinutes ~/ 60;

  @override
  SummaryWeekDay fromJson(Map<String, dynamic> json) =>
      SummaryWeekDay.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}

final class SummaryLastMeal implements BaseModel<SummaryLastMeal> {
  const SummaryLastMeal({required this.eatenAt, this.title, this.kcal});

  factory SummaryLastMeal.fromJson(Map<String, dynamic> json) {
    DateTime? at(Object? v) =>
        v is String ? DateTime.tryParse(v)?.toLocal() : null;
    return SummaryLastMeal(
      eatenAt: at(json['eatenAt']) ?? DateTime.now(),
      title: json['title'] as String?,
      kcal: (json['kcal'] as num?)?.toInt(),
    );
  }

  final DateTime eatenAt;
  final String? title;
  final int? kcal;

  @override
  SummaryLastMeal fromJson(Map<String, dynamic> json) =>
      SummaryLastMeal.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}

String formatPlanLabel(String? planCode, String? displayName) {
  if (displayName != null && displayName.isNotEmpty) return displayName;
  if (planCode == null || planCode.isEmpty) return '16-8';
  return planCode.replaceAll('_', '-');
}

/// Sunucu saati ile yerel saat farkı (geri sayım düzeltmesi).
Duration clockOffsetFromServer(DateTime? serverTime, DateTime fetchedAtLocal) {
  if (serverTime == null) return Duration.zero;
  return serverTime.difference(fetchedAtLocal);
}

/// Aktif oruç için canlı süre / ilerleme.
final class FastingLiveMetrics {
  const FastingLiveMetrics({
    required this.elapsed,
    required this.progress,
    required this.remainingToPlannedEnd,
  });

  factory FastingLiveMetrics.active({
    required ActiveFast fast,
    required DateTime fetchedAt,
    required Duration clockOffset,
  }) {
    final drift = DateTime.now().difference(fetchedAt);
    final elapsed = Duration(minutes: fast.elapsedMinutes) + drift;
    final target = Duration(minutes: fast.targetMinutes);
    final progress = target.inSeconds <= 0
        ? 0.0
        : (elapsed.inSeconds / target.inSeconds).clamp(0.0, 1.0);
    final end = fast.plannedEndAt.add(clockOffset);
    final remaining = end.difference(DateTime.now());
    return FastingLiveMetrics(
      elapsed: elapsed.isNegative ? Duration.zero : elapsed,
      progress: progress,
      remainingToPlannedEnd: remaining.isNegative ? Duration.zero : remaining,
    );
  }

  factory FastingLiveMetrics.eating({
    required EatingWindow window,
    required DateTime fetchedAt,
    required Duration clockOffset,
  }) {
    final drift = DateTime.now().difference(fetchedAt);
    final elapsed = Duration(minutes: window.elapsedMinutes) + drift;
    final ends = window.endsAt.add(clockOffset);
    final remaining = ends.difference(DateTime.now());
    return FastingLiveMetrics(
      elapsed: elapsed,
      progress: window.eatMinutes <= 0
          ? 0
          : (elapsed.inMinutes / window.eatMinutes).clamp(0.0, 1.0),
      remainingToPlannedEnd: remaining.isNegative ? Duration.zero : remaining,
    );
  }

  final Duration elapsed;
  final double progress;
  final Duration remainingToPlannedEnd;
}

String formatElapsedHms(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  return '${h.toString().padLeft(2, '0')}:'
      '${m.toString().padLeft(2, '0')}:'
      '${s.toString().padLeft(2, '0')}';
}
