import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/core/utils/enum/request_type.dart';
import 'package:fastingapp/presentation/hunger_tracker/hunger_result_type.dart';
import 'package:fastingapp/presentation/hunger_tracker/hunger_symptom.dart';
import 'package:uuid/uuid.dart';

/// Açlık check-in (`/v1/hunger-checkins/*`).
final class HungerRepository {
  const HungerRepository(this._network);

  final NetworkManager _network;
  static const _uuid = Uuid();

  Future<HungerEvaluation> evaluate(HungerFlowArgs flow) async {
    final result = await _network.send<HungerEvaluation>(
      path: '/hunger-checkins/evaluate',
      method: RequestType.post,
      data: _answersBody(flow),
      parserModel: HungerEvaluation.fromJson,
    );
    if (result == null) throw StateError('Açlık değerlendirmesi başarısız');
    return result;
  }

  Future<HungerEvaluation> saveCheckin({
    required HungerFlowArgs flow,
    required String mode,
    String? notes,
  }) async {
    final result = await _network.send<HungerEvaluation>(
      path: '/hunger-checkins',
      method: RequestType.post,
      data: {
        ..._answersBody(flow),
        'id': _uuid.v7(),
        'mode': mode,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
      parserModel: HungerEvaluation.fromJson,
    );
    if (result == null) throw StateError('Check-in kaydedilemedi');
    return result;
  }

  Future<List<HungerCheckinItem>> listCheckins({
    String type = 'all',
    int limit = 50,
  }) async {
    final page = await _network.send<_HungerCheckinPage>(
      path: '/hunger-checkins',
      method: RequestType.get,
      queryParameters: {'type': type, 'limit': limit},
      parserModel: _HungerCheckinPage.fromJson,
    );
    return page?.items ?? const [];
  }

  Future<HungerCheckinSummary> getSummary({DateTime? date}) async {
    final result = await _network.send<HungerCheckinSummary>(
      path: '/hunger-checkins/summary',
      method: RequestType.get,
      queryParameters: {if (date != null) 'date': _ymd(date)},
      parserModel: HungerCheckinSummary.fromJson,
    );
    return result ?? const HungerCheckinSummary();
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static Map<String, dynamic> _answersBody(HungerFlowArgs flow) {
    // Yalnızca 3. sorudaki gerçek cevap: belirtiler `symptoms` ile ayrıca
    // gider, onlardan türetmek puanı iki kez sayıyordu.
    final notices = flow.bodyNotices;
    return {
      'symptoms': flow.symptoms.map((s) => s.name).toList(),
      if (flow.q1 != null) 'q1': flow.q1,
      if (flow.q2 != null) 'q2': flow.q2,
      'bodyNotices': notices.map((b) => b.apiValue).toList(),
      if (flow.q4 != null) 'q4': flow.q4,
    };
  }
}

final class HungerEvaluation implements BaseModel<HungerEvaluation> {
  const HungerEvaluation({
    this.resultType,
    this.physicalScore = 0,
    this.emotionalScore = 0,
    this.safetyFlag = false,
    this.activeFastId,
    this.recommendations = const [],
  });

  factory HungerEvaluation.fromJson(Map<String, dynamic> json) {
    final recRaw = json['recommendations'];
    return HungerEvaluation(
      resultType: json['resultType'] as String?,
      physicalScore: (json['physicalScore'] as num?)?.toInt() ?? 0,
      emotionalScore: (json['emotionalScore'] as num?)?.toInt() ?? 0,
      safetyFlag: json['safetyFlag'] as bool? ?? false,
      activeFastId: json['activeFastId'] as String?,
      recommendations: recRaw is List
          ? recRaw
                .whereType<Map<String, dynamic>>()
                .map(
                  (m) => HungerRecommendation(
                    code: m['code'] as String? ?? '',
                    title: m['title'] as String? ?? '',
                  ),
                )
                .toList()
          : const [],
    );
  }

  final String? resultType;
  final int physicalScore;
  final int emotionalScore;
  final bool safetyFlag;
  final String? activeFastId;
  final List<HungerRecommendation> recommendations;

  HungerResultType get resultTypeEnum => resultType == 'emotional'
      ? HungerResultType.emotional
      : HungerResultType.physical;

  @override
  HungerEvaluation fromJson(Map<String, dynamic> json) =>
      HungerEvaluation.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {'resultType': resultType};
}

final class HungerRecommendation {
  const HungerRecommendation({required this.code, required this.title});

  final String code;
  final String title;
}

final class HungerCheckinItem {
  const HungerCheckinItem({
    required this.id,
    required this.loggedAt,
    required this.resultType,
  });

  factory HungerCheckinItem.fromJson(Map<String, dynamic> json) =>
      HungerCheckinItem(
        id: json['id'] as String? ?? '',
        loggedAt:
            DateTime.tryParse(json['loggedAt'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
        resultType: json['resultType'] as String? ?? 'physical',
      );

  final String id;
  final DateTime loggedAt;
  final String resultType;

  HungerResultType get typeEnum => resultType == 'emotional'
      ? HungerResultType.emotional
      : HungerResultType.physical;
}

final class HungerCheckinSummary implements BaseModel<HungerCheckinSummary> {
  const HungerCheckinSummary({
    this.todayTotal = 0,
    this.todayPhysical = 0,
    this.todayEmotional = 0,
    this.week = const [],
  });

  factory HungerCheckinSummary.fromJson(Map<String, dynamic> json) {
    final today = json['today'];
    final todayMap = today is Map<String, dynamic> ? today : null;
    final week = json['week'];
    return HungerCheckinSummary(
      todayTotal: (todayMap?['total'] as num?)?.toInt() ?? 0,
      todayPhysical: (todayMap?['physical'] as num?)?.toInt() ?? 0,
      todayEmotional: (todayMap?['emotional'] as num?)?.toInt() ?? 0,
      week: week is List
          ? [
              for (final d in week.whereType<Map<String, dynamic>>())
                HungerWeekDay(
                  date: d['date'] as String? ?? '',
                  physical: (d['physical'] as num?)?.toInt() ?? 0,
                  emotional: (d['emotional'] as num?)?.toInt() ?? 0,
                  fastedMinutes: (d['fastedMinutes'] as num?)?.toInt() ?? 0,
                ),
            ]
          : const [],
    );
  }

  final int todayTotal;
  final int todayPhysical;
  final int todayEmotional;

  /// Son 7 gün (`yyyy-MM-dd`, açlık kayıtları + oruç süresi).
  final List<HungerWeekDay> week;

  @override
  HungerCheckinSummary fromJson(Map<String, dynamic> json) =>
      HungerCheckinSummary.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}

final class HungerWeekDay {
  const HungerWeekDay({
    required this.date,
    this.physical = 0,
    this.emotional = 0,
    this.fastedMinutes = 0,
  });

  final String date;
  final int physical;
  final int emotional;
  final int fastedMinutes;
}

final class _HungerCheckinPage implements BaseModel<_HungerCheckinPage> {
  const _HungerCheckinPage(this.items);

  factory _HungerCheckinPage.fromJson(Map<String, dynamic> json) =>
      _HungerCheckinPage([
        for (final item in json['items'] as List<dynamic>? ?? const [])
          HungerCheckinItem.fromJson(item as Map<String, dynamic>),
      ]);

  final List<HungerCheckinItem> items;

  @override
  _HungerCheckinPage fromJson(Map<String, dynamic> json) =>
      _HungerCheckinPage.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}
