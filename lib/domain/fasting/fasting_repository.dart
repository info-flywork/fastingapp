import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/core/utils/enum/request_type.dart';
import 'package:fastingapp/data/model/auth/no_content.dart';
import 'package:fastingapp/domain/fasting/weekly_schedule.dart';
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
  /// değilken `402 PREMIUM_REQUIRED`. Uzun planlar [safetyAcknowledged] ister
  /// (bkz. `planRequiresSafetyAck`).
  Future<CurrentPlanEnvelope> setCurrentPlan({
    required String planCode,
    String? timing,
    String? eatStart,
    String? eatEnd,
    List<WeeklyDay>? weeklySchedule,
    bool safetyAcknowledged = false,
  }) async {
    final result = await _network.send<CurrentPlanEnvelope>(
      path: '/plans/current',
      method: RequestType.put,
      data: {
        'planCode': planCode,
        'timing': ?timing,
        if (eatStart != null) 'eatWindow': {'start': eatStart, 'end': ?eatEnd},
        if (weeklySchedule != null)
          'weeklySchedule': [for (final d in weeklySchedule) d.toJson()],
        if (safetyAcknowledged) 'safetyAcknowledged': true,
      },
      parserModel: CurrentPlanEnvelope.fromJson,
    );
    return result ?? const CurrentPlanEnvelope();
  }

  /// Haftalık planda azaltılmış / oruç gününü işaretle
  /// (`PUT /plans/days/:date {status: done | skipped}`).
  Future<void> checkinPlanDay(DateTime date, {required bool done}) async {
    final ymd =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    await _network.send<_EmptyData>(
      path: '/plans/days/$ymd',
      method: RequestType.put,
      data: {'status': done ? 'done' : 'skipped'},
      parserModel: (_) => const _EmptyData(),
    );
  }

  /// Zorlanma olayı (`POST /fasts/:id/struggles`, oruç yoksa `/struggles`).
  /// Forecast'taki "en zor saat" bu kayıtlardan hesaplanır.
  Future<void> logStruggle({
    required String reason,
    String? fastId,
    String? tip,
  }) async {
    await _network.send<_EmptyData>(
      path: fastId == null || fastId.isEmpty
          ? '/struggles'
          : '/fasts/$fastId/struggles',
      method: RequestType.post,
      data: {'reason': reason, 'tip': ?tip},
      parserModel: (_) => const _EmptyData(),
    );
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

  /// `PATCH /fasts/:id` — geçmiş orucun saatleri (son 30 gün).
  Future<void> updateFast(
    String id, {
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    await _network.send<NoContent>(
      path: '/fasts/$id',
      method: RequestType.patch,
      data: {
        'startedAt': startedAt.toUtc().toIso8601String(),
        'endedAt': endedAt.toUtc().toIso8601String(),
      },
      parserModel: NoContent.fromJson,
    );
  }

  /// `DELETE /fasts/:id` (yumuşak silme).
  Future<void> deleteFast(String id) async {
    await _network.send<NoContent>(
      path: '/fasts/$id',
      method: RequestType.delete,
      parserModel: NoContent.fromJson,
    );
  }

  /// `POST /fasts/manual` — uygulamasız yapılmış geçmiş oruç (son 30 gün);
  /// hedef süre sunucuda plandan.
  Future<void> addPastFast({
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    await _network.send<NoContent>(
      path: '/fasts/manual',
      method: RequestType.post,
      data: {
        'startedAt': startedAt.toUtc().toIso8601String(),
        'endedAt': endedAt.toUtc().toIso8601String(),
      },
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

  /// Günün ipucu (`GET /fasts/daily-tip`) — AI yok; katalog + yerel gün.
  Future<DailyTip?> getDailyTip() async {
    final result = await _network.send<_DailyTipEnvelope>(
      path: '/fasts/daily-tip',
      method: RequestType.get,
      parserModel: _DailyTipEnvelope.fromJson,
    );
    return result?.tip;
  }

  /// Oruç geçmişi (`GET /fasts?cursor=&limit=&status=`).
  Future<FastHistoryPage> listHistory({
    String? cursor,
    int limit = 20,
    String? status,
  }) async {
    final page = await _network.send<_FastHistoryPagePayload>(
      path: '/fasts',
      method: RequestType.get,
      queryParameters: {
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        if (status != null && status.isNotEmpty) 'status': status,
      },
      parserModel: _FastHistoryPagePayload.fromJson,
    );
    return page?.toPage() ?? const FastHistoryPage();
  }

  /// Oruç istatistikleri (`GET /fasts/stats?range=`).
  Future<FastStats> getStats({String range = 'month'}) async {
    final result = await _network.send<_FastStatsPayload>(
      path: '/fasts/stats',
      method: RequestType.get,
      queryParameters: {'range': range},
      parserModel: _FastStatsPayload.fromJson,
    );
    return result?.stats ?? const FastStats();
  }
}

/// `GET /fasts` bir sayfası.
final class FastHistoryPage {
  const FastHistoryPage({
    this.items = const [],
    this.nextCursor,
    this.hasMore = false,
  });

  final List<FastHistoryItem> items;
  final String? nextCursor;
  final bool hasMore;
}

/// Geçmiş oruç satırı.
final class FastHistoryItem {
  const FastHistoryItem({
    required this.id,
    required this.status,
    required this.startedAt,
    required this.targetMinutes,
    this.endedAt,
    this.durationMinutes,
    this.goalReached = false,
    this.planCode,
    this.feeling,
  });

  factory FastHistoryItem.fromJson(Map<String, dynamic> json) {
    DateTime? at(Object? v) =>
        v is String ? DateTime.tryParse(v)?.toLocal() : null;
    return FastHistoryItem(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      planCode: json['planCode'] as String?,
      targetMinutes: (json['targetMinutes'] as num?)?.toInt() ?? 0,
      startedAt: at(json['startedAt']) ?? DateTime.now(),
      endedAt: at(json['endedAt']),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      goalReached: json['goalReached'] as bool? ?? false,
      feeling: json['feeling'] as String?,
    );
  }

  final String id;
  final String status;
  final String? planCode;
  final int targetMinutes;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? durationMinutes;
  final bool goalReached;
  final String? feeling;
}

/// `GET /fasts/stats` özeti.
final class FastStats {
  const FastStats({
    this.fasts = 0,
    this.completedFasts = 0,
    this.completionRate = 0,
    this.totalFastedMinutes = 0,
    this.longestFastMinutes = 0,
    this.avgFastMinutes = 0,
  });

  final int fasts;
  final int completedFasts;
  final double completionRate;
  final int totalFastedMinutes;
  final int longestFastMinutes;
  final int avgFastMinutes;
}

final class _FastHistoryPagePayload
    implements BaseModel<_FastHistoryPagePayload> {
  const _FastHistoryPagePayload({
    this.items = const [],
    this.nextCursor,
    this.hasMore = false,
  });

  factory _FastHistoryPagePayload.fromJson(Map<String, dynamic> json) {
    final page = json['pageInfo'] as Map<String, dynamic>? ?? const {};
    return _FastHistoryPagePayload(
      items: [
        for (final item in json['items'] as List<dynamic>? ?? const [])
          if (item is Map<String, dynamic>) FastHistoryItem.fromJson(item),
      ],
      nextCursor: page['nextCursor'] as String?,
      hasMore: page['hasMore'] as bool? ?? false,
    );
  }

  final List<FastHistoryItem> items;
  final String? nextCursor;
  final bool hasMore;

  FastHistoryPage toPage() =>
      FastHistoryPage(items: items, nextCursor: nextCursor, hasMore: hasMore);

  @override
  _FastHistoryPagePayload fromJson(Map<String, dynamic> json) =>
      _FastHistoryPagePayload.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}

final class _FastStatsPayload implements BaseModel<_FastStatsPayload> {
  const _FastStatsPayload(this.stats);

  factory _FastStatsPayload.fromJson(Map<String, dynamic> json) {
    final t = json['totals'] as Map<String, dynamic>? ?? const {};
    return _FastStatsPayload(
      FastStats(
        fasts: (t['fasts'] as num?)?.toInt() ?? 0,
        completedFasts: (t['completedFasts'] as num?)?.toInt() ?? 0,
        completionRate: (t['completionRate'] as num?)?.toDouble() ?? 0,
        totalFastedMinutes: (t['totalFastedMinutes'] as num?)?.toInt() ?? 0,
        longestFastMinutes: (t['longestFastMinutes'] as num?)?.toInt() ?? 0,
        avgFastMinutes: (t['avgFastMinutes'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  final FastStats stats;

  @override
  _FastStatsPayload fromJson(Map<String, dynamic> json) =>
      _FastStatsPayload.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}

/// `GET /fasts/daily-tip` yanıtındaki ipucu.
final class DailyTip {
  const DailyTip({
    required this.code,
    required this.phase,
    required this.date,
    required this.text,
  });

  factory DailyTip.fromJson(Map<String, dynamic> json) => DailyTip(
    code: json['code'] as String? ?? '',
    phase: json['phase'] as String? ?? '',
    date: json['date'] as String? ?? '',
    text: json['text'] as String? ?? '',
  );

  final String code;
  final String phase;
  final String date;
  final String text;
}

final class _DailyTipEnvelope implements BaseModel<_DailyTipEnvelope> {
  const _DailyTipEnvelope({this.tip});

  factory _DailyTipEnvelope.fromJson(Map<String, dynamic> json) {
    final raw = json['tip'];
    return _DailyTipEnvelope(
      tip: raw is Map<String, dynamic> ? DailyTip.fromJson(raw) : null,
    );
  }

  final DailyTip? tip;

  @override
  _DailyTipEnvelope fromJson(Map<String, dynamic> json) =>
      _DailyTipEnvelope.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
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
    this.weeklySchedule = const [],
  });

  factory UserFastingPlan.fromJson(Map<String, dynamic> json) {
    final eatRaw = json['eatWindow'];
    final weeklyRaw = json['weeklySchedule'];
    return UserFastingPlan(
      weeklySchedule: weeklyRaw is List
          ? [
              for (final d in weeklyRaw.whereType<Map<String, dynamic>>())
                WeeklyDay.fromJson(d),
            ]
          : const [],
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

  /// Haftalık planlarda 7 gün (Pazartesi → Pazar); günlük planlarda boş.
  final List<WeeklyDay> weeklySchedule;

  bool get isWeekly => weeklySchedule.isNotEmpty;

  /// Ekranın gösterdiği her şey (kod, zamanlama, pencere, süre, haftalık
  /// günler): durum karşılaştırmasında yalnızca kod kullanılıyordu, aynı
  /// planın saati / günleri değişince ekran ve widget güncellenmiyordu.
  String get signature => [
    planCode,
    timing,
    eatWindow?.start,
    eatWindow?.end,
    fastMinutes,
    for (final d in weeklySchedule) '${d.dow}${d.type.name}${d.fastMinutes}',
  ].join('|');

  /// [date]'in (yerel gün) program günü; günlük planda null.
  WeeklyDay? dayFor(DateTime date) {
    for (final d in weeklySchedule) {
      if (d.dow == date.weekday) return d;
    }
    return null;
  }

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
  const FinishFastResult({
    this.isFirstFast = false,
    this.streak = 0,
    this.streakIncreased = false,
    this.xpGained = 0,
    this.levelUpTo,
    this.worldLevelUps = 0,
    this.challengesCompleted = 0,
  });

  factory FinishFastResult.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> map(Object? v) =>
        v is Map<String, dynamic> ? v : const <String, dynamic>{};
    final streak = map(json['streak']);
    final levelUp = json['levelUp'];
    final world = map(json['world']);
    final levelUps = world['levelUps'];
    final challenges = json['challenges'];
    return FinishFastResult(
      isFirstFast: json['isFirstFast'] as bool? ?? false,
      streak: (streak['current'] as num?)?.toInt() ?? 0,
      streakIncreased: streak['increased'] as bool? ?? false,
      xpGained: (json['xpGained'] as num?)?.toInt() ?? 0,
      levelUpTo: levelUp is Map<String, dynamic>
          ? (levelUp['to'] as num?)?.toInt()
          : null,
      worldLevelUps: levelUps is List ? levelUps.length : 0,
      challengesCompleted: challenges is List
          ? challenges
                .whereType<Map<String, dynamic>>()
                .where((c) => c['status'] == 'completed')
                .length
          : 0,
    );
  }

  final bool isFirstFast;

  /// Bitirme sonrası seri ve artıp artmadığı.
  final int streak;
  final bool streakIncreased;
  final int xpGained;

  /// Seviye atladıysa yeni seviye.
  final int? levelUpTo;

  /// Mochi adasında büyüyen bölge sayısı.
  final int worldLevelUps;
  final int challengesCompleted;

  /// Gösterilecek bir kazanım var mı (önceden yanıtta gelip yok sayılıyordu).
  bool get hasRewards =>
      streakIncreased ||
      xpGained > 0 ||
      levelUpTo != null ||
      worldLevelUps > 0 ||
      challengesCompleted > 0;

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
    this.dayType = 'fast',
    this.isRequiredDay = true,
    this.checkin,
    this.progress,
  });

  factory SummaryWeekDay.fromJson(Map<String, dynamic> json) => SummaryWeekDay(
    date: json['date'] as String? ?? '',
    fastedMinutes: (json['fastedMinutes'] as num?)?.toInt() ?? 0,
    isToday: json['isToday'] as bool? ?? false,
    isFuture: json['isFuture'] as bool? ?? false,
    dayType: json['dayType'] as String? ?? 'fast',
    isRequiredDay: json['isRequiredDay'] as bool? ?? true,
    checkin: json['checkin'] as String?,
    progress: (json['progress'] as num?)?.toDouble(),
  );

  final String date;
  final int fastedMinutes;
  final bool isToday;
  final bool isFuture;

  /// `fast` | `reduced` | `normal` (haftalık planlarda serbest gün `normal`).
  final String dayType;

  /// Planın bu gün bir şey istediği (oruç / azaltılmış gün); haftalık
  /// sayaç paydası bu günlerden.
  final bool isRequiredDay;

  /// Azaltılmış / oruç günü işareti: `done` | `skipped` | null.
  final String? checkin;

  /// Sunucunun gün ilerlemesi (0–1); yoksa null.
  final double? progress;

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
    // Geçen ve kalan aynı "şimdi"den: ana sayfa geri sayımı ile oruç
    // ileri sayımı senkron kalır.
    final now = DateTime.now().add(clockOffset);
    var elapsed = now.difference(fast.startedAt);
    if (elapsed.isNegative) {
      elapsed =
          Duration(minutes: fast.elapsedMinutes) +
          DateTime.now().difference(fetchedAt);
    }
    final target = Duration(minutes: fast.targetMinutes);
    final progress = target.inSeconds <= 0
        ? 0.0
        : (elapsed.inSeconds / target.inSeconds).clamp(0.0, 1.0);
    final remaining = fast.plannedEndAt.difference(now);
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
    final now = DateTime.now().add(clockOffset);
    var elapsed = now.difference(window.startedAt);
    if (elapsed.isNegative) {
      elapsed =
          Duration(minutes: window.elapsedMinutes) +
          DateTime.now().difference(fetchedAt);
    }
    final remaining = window.endsAt.difference(now);
    return FastingLiveMetrics(
      elapsed: elapsed.isNegative ? Duration.zero : elapsed,
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

final class _EmptyData implements BaseModel<_EmptyData> {
  const _EmptyData();

  @override
  _EmptyData fromJson(Map<String, dynamic> json) => const _EmptyData();

  @override
  Map<String, dynamic> toJson() => const {};
}
