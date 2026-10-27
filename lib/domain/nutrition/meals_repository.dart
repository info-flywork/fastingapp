import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/core/base/model/base_response.dart';
import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/core/utils/enum/request_type.dart';
import 'package:uuid/uuid.dart';

/// Fotoğraf analizi ve öğün kaydı (`/v1/meals/*`).
final class MealsRepository {
  MealsRepository(this._network, this._dio);

  final NetworkManager _network;
  final Dio _dio;
  static const _uuid = Uuid();

  /// 202 + poll. Rıza UI'da (`AiConsent.ensure`); burada sessiz grant yok.
  Future<PhotoAnalysisResult> analyzePhoto(String filePath) async {
    try {
      final file = File(filePath);
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: 'meal.jpg'),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        '/meals/photo-analyses',
        data: form,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      final body = response.data;
      if (body == null) throw StateError('Analiz yanıtı boş');
      final parsed = BaseResponse<_PhotoAnalysisQueued>.fromJson(
        body,
        _PhotoAnalysisQueued.fromJson,
      );
      final queued = parsed.data;
      if (queued == null) throw StateError('Analiz kuyruğa alınamadı');
      return pollAnalysis(queued.analysisId, queued.pollAfterMs);
    } on DioException catch (e) {
      throw NetworkException.fromDio(e);
    }
  }

  /// Sunucu tek analizi 45 sn'ye kadar ve 3 kez dener (+ geri çekilme);
  /// istemci ondan önce vazgeçerse hak boşa gider. Süre dolarsa
  /// [PhotoAnalysisPending] (aynı analiz sonra tekrar yoklanabilir).
  static const _pollDeadline = Duration(seconds: 150);

  Future<PhotoAnalysisResult> pollAnalysis(
    String analysisId,
    int pollAfterMs,
  ) async {
    final deadline = DateTime.now().add(_pollDeadline);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(Duration(milliseconds: pollAfterMs));
      final _PhotoAnalysisEnvelope? envelope;
      try {
        envelope = await _network.send<_PhotoAnalysisEnvelope>(
          path: '/meals/photo-analyses/$analysisId',
          method: RequestType.get,
          parserModel: _PhotoAnalysisEnvelope.fromJson,
        );
      } on NetworkException catch (e) {
        // Geçici ağ hatası yoklamayı bitirmez; analiz sunucuda sürüyor.
        if (e.statusCode != null && e.statusCode! < 500) rethrow;
        pollAfterMs = 3000;
        continue;
      }
      final analysis = envelope?.analysis;
      if (analysis == null) continue;
      switch (analysis.status) {
        case 'succeeded':
        case 'notFood':
        case 'failed':
          return analysis;
        default:
          pollAfterMs = 1500;
      }
    }
    throw PhotoAnalysisPending(analysisId);
  }

  /// Analizden öğün; `suggestEndFast` aktif oruçta "orucu bitir?" içindir.
  Future<MealWriteResult> createMealFromAnalysis({
    required String analysisId,
    String? title,
    int? kcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
  }) async {
    final result = await _network.send<MealWriteResult>(
      path: '/meals',
      method: RequestType.post,
      data: {
        'id': _uuid.v7(),
        'source': 'aiPhoto',
        'analysisId': analysisId,
        if (title != null) 'title': title,
        if (kcal != null) 'kcal': kcal,
        if (proteinG != null) 'proteinG': proteinG,
        if (carbsG != null) 'carbsG': carbsG,
        if (fatG != null) 'fatG': fatG,
      },
      parserModel: MealWriteResult.fromJson,
    );
    final written = result ?? const MealWriteResult();
    _afterWrite(added: written.meal);
    return written;
  }

  /// Son görülen günler (bellekte): ekran tekrar açılınca iskelet yerine
  /// hemen gösterilir, ağ yanıtıyla sessizce yenilenir.
  final Map<String, List<MealRecord>> _dayCache = {};

  /// Her öğün yazmasında artar (bkz. [_afterWrite]).
  int writeSeq = 0;

  List<MealRecord>? cachedDay(DateTime date) => _dayCache[_ymd(date)];

  /// Çıkış / hesap değişimi.
  void clearCache() => _dayCache.clear();

  Future<List<MealRecord>> listForDay(DateTime date) async {
    final seqAtStart = writeSeq;
    final page = await _network.send<_MealsPage>(
      path: '/meals',
      method: RequestType.get,
      queryParameters: {'date': _ymd(date)},
      parserModel: _MealsPage.fromJson,
    );
    final items = page?.items ?? const <MealRecord>[];
    // İstek sürerken yazma olduysa cevap eskidir: önbellekteki (yazmayla
    // güncellenmiş) liste döner.
    if (seqAtStart != writeSeq) return _dayCache[_ymd(date)] ?? items;
    if (_dayCache.length > 14) _dayCache.clear();
    _dayCache[_ymd(date)] = items;
    return items;
  }

  Future<MealRecord?> getById(String id) async {
    final envelope = await _network.send<_MealEnvelope>(
      path: '/meals/$id',
      method: RequestType.get,
      parserModel: _MealEnvelope.fromJson,
    );
    return envelope?.meal;
  }

  Future<MealWriteResult> createManual({
    required DateTime eatenAt,
    String? kind,
    String? dietType,
    String? feeling,
    String? notes,
  }) async {
    final result = await _network.send<MealWriteResult>(
      path: '/meals',
      method: RequestType.post,
      data: {
        'id': _uuid.v7(),
        'source': 'manual',
        'eatenAt': eatenAt.toUtc().toIso8601String(),
        if (kind != null) 'kind': kind,
        if (dietType != null) 'dietType': dietType,
        if (feeling != null) 'feeling': feeling,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
      parserModel: MealWriteResult.fromJson,
    );
    if (result == null) throw StateError('Öğün kaydedilemedi');
    _afterWrite(added: result.meal);
    return result;
  }

  /// Hızlı kalori: yalnızca kcal (`source: quickKcal`).
  Future<MealWriteResult> createQuickKcal({
    required int kcal,
    DateTime? eatenAt,
  }) async {
    final result = await _network.send<MealWriteResult>(
      path: '/meals',
      method: RequestType.post,
      data: {
        'id': _uuid.v7(),
        'source': 'quickKcal',
        'eatenAt': (eatenAt ?? DateTime.now()).toUtc().toIso8601String(),
        'kcal': kcal,
      },
      parserModel: MealWriteResult.fromJson,
    );
    if (result == null) throw StateError('Kalori kaydedilemedi');
    _afterWrite(added: result.meal);
    return result;
  }

  Future<MealRecord> updateMeal(
    String id, {
    DateTime? eatenAt,
    String? kind,
    String? dietType,
    String? feeling,
    String? notes,
    bool clearNotes = false,
  }) async {
    final envelope = await _network.send<_MealEnvelope>(
      path: '/meals/$id',
      method: RequestType.patch,
      data: {
        if (eatenAt != null) 'eatenAt': eatenAt.toUtc().toIso8601String(),
        if (kind != null) 'kind': kind,
        if (dietType != null) 'dietType': dietType,
        if (feeling != null) 'feeling': feeling,
        if (clearNotes) 'notes': null else if (notes != null) 'notes': notes,
      },
      parserModel: _MealEnvelope.fromJson,
    );
    final meal = envelope?.meal;
    if (meal == null) throw StateError('Öğün güncellenemedi');
    // Saat değişince öğün başka güne de geçebilir: eski yerinden çıkıp
    // yeni gününe girer.
    _afterWrite(removedId: id, added: meal);
    return meal;
  }

  Future<void> deleteMeal(String id) async {
    await _network.send<_MealDeleteEnvelope>(
      path: '/meals/$id',
      method: RequestType.delete,
      parserModel: _MealDeleteEnvelope.fromJson,
    );
    _afterWrite(removedId: id);
  }

  /// Yazma sonrası önbellek silinmez, yerinde güncellenir: liste ekrana
  /// döndüğünde iskelet / boş liste görünmez. [writeSeq] artar; yazmadan önce
  /// başlamış bir liste isteğinin (eski) cevabı önbelleğe yazılmaz.
  void _afterWrite({String? removedId, MealRecord? added}) {
    writeSeq++;
    if (removedId != null) {
      for (final key in _dayCache.keys.toList()) {
        _dayCache[key] = [
          for (final m in _dayCache[key]!)
            if (m.id != removedId) m,
        ];
      }
    }
    if (added == null) return;
    final key = _ymd(added.eatenAt);
    final list = _dayCache[key];
    // O gün hiç görülmediyse ekran açılınca sunucudan okunur.
    if (list == null) return;
    _dayCache[key] = [
      for (final m in list)
        if (m.id != added.id) m,
      added,
    ]..sort((a, b) => a.eatenAt.compareTo(b.eatenAt));
  }

  /// Önbellekteki öğün (detay ekranı beklemeden dolu açılsın).
  MealRecord? cachedMeal(String id) {
    for (final list in _dayCache.values) {
      for (final m in list) {
        if (m.id == id) return m;
      }
    }
    return null;
  }

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// Tek öğün kaydı (`GET /meals`, `GET/PATCH /meals/:id`).
final class MealRecord implements BaseModel<MealRecord> {
  const MealRecord({
    required this.id,
    required this.eatenAt,
    this.kind,
    this.dietType,
    this.feeling,
    this.title,
    this.notes,
    this.kcal,
    this.photoUrl,
  });

  factory MealRecord.fromJson(Map<String, dynamic> json) {
    final photo = json['photo'];
    final photoMap = photo is Map<String, dynamic> ? photo : null;
    return MealRecord(
      id: json['id'] as String? ?? '',
      eatenAt:
          DateTime.tryParse(json['eatenAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      kind: json['kind'] as String?,
      dietType: json['dietType'] as String?,
      feeling: json['feeling'] as String?,
      title: json['title'] as String?,
      notes: json['notes'] as String?,
      kcal: (json['kcal'] as num?)?.toInt(),
      photoUrl: photoMap?['url'] as String? ?? photoMap?['thumbUrl'] as String?,
    );
  }

  final String id;
  final DateTime eatenAt;
  final String? kind;
  final String? dietType;
  final String? feeling;
  final String? title;
  final String? notes;
  final int? kcal;
  final String? photoUrl;

  @override
  MealRecord fromJson(Map<String, dynamic> json) => MealRecord.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {'id': id};
}

final class MealWriteResult implements BaseModel<MealWriteResult> {
  const MealWriteResult({
    this.meal,
    this.suggestEndFast = false,
    this.activeFastId,
  });

  factory MealWriteResult.fromJson(Map<String, dynamic> json) {
    final raw = json['meal'];
    return MealWriteResult(
      meal: raw is Map<String, dynamic> ? MealRecord.fromJson(raw) : null,
      suggestEndFast: json['suggestEndFast'] as bool? ?? false,
      activeFastId: json['activeFastId'] as String?,
    );
  }

  final MealRecord? meal;
  final bool suggestEndFast;
  final String? activeFastId;

  @override
  MealWriteResult fromJson(Map<String, dynamic> json) =>
      MealWriteResult.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}

final class PhotoAnalysisResult {
  const PhotoAnalysisResult({
    required this.id,
    required this.status,
    this.mealTitle,
    this.kcal,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.photoUrl,
  });

  factory PhotoAnalysisResult.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    final resultMap = result is Map<String, dynamic> ? result : null;
    final photo = json['photo'];
    final photoMap = photo is Map<String, dynamic> ? photo : null;
    return PhotoAnalysisResult(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'failed',
      mealTitle: resultMap?['mealTitle'] as String?,
      kcal: (resultMap?['kcal'] as num?)?.toInt(),
      proteinG: (resultMap?['proteinG'] as num?)?.toDouble(),
      carbsG: (resultMap?['carbsG'] as num?)?.toDouble(),
      fatG: (resultMap?['fatG'] as num?)?.toDouble(),
      photoUrl: photoMap?['url'] as String? ?? photoMap?['thumbUrl'] as String?,
    );
  }

  final String id;
  final String status;
  final String? mealTitle;
  final int? kcal;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final String? photoUrl;

  bool get succeeded => status == 'succeeded';
}

final class _PhotoAnalysisQueued implements BaseModel<_PhotoAnalysisQueued> {
  const _PhotoAnalysisQueued({
    required this.analysisId,
    required this.pollAfterMs,
  });

  factory _PhotoAnalysisQueued.fromJson(Map<String, dynamic> json) =>
      _PhotoAnalysisQueued(
        analysisId: json['analysisId'] as String? ?? '',
        pollAfterMs: (json['pollAfterMs'] as num?)?.toInt() ?? 1500,
      );

  final String analysisId;
  final int pollAfterMs;

  @override
  _PhotoAnalysisQueued fromJson(Map<String, dynamic> json) =>
      _PhotoAnalysisQueued.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}

final class _PhotoAnalysisEnvelope
    implements BaseModel<_PhotoAnalysisEnvelope> {
  const _PhotoAnalysisEnvelope(this.analysis);

  factory _PhotoAnalysisEnvelope.fromJson(Map<String, dynamic> json) {
    final raw = json['analysis'];
    return _PhotoAnalysisEnvelope(
      raw is Map<String, dynamic> ? PhotoAnalysisResult.fromJson(raw) : null,
    );
  }

  final PhotoAnalysisResult? analysis;

  @override
  _PhotoAnalysisEnvelope fromJson(Map<String, dynamic> json) =>
      _PhotoAnalysisEnvelope.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}

final class _MealsPage implements BaseModel<_MealsPage> {
  const _MealsPage({this.items = const []});

  factory _MealsPage.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return _MealsPage(
      items: raw is List
          ? raw
                .whereType<Map<String, dynamic>>()
                .map(MealRecord.fromJson)
                .toList()
          : const [],
    );
  }

  final List<MealRecord> items;

  @override
  _MealsPage fromJson(Map<String, dynamic> json) => _MealsPage.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}

final class _MealEnvelope implements BaseModel<_MealEnvelope> {
  const _MealEnvelope({this.meal});

  factory _MealEnvelope.fromJson(Map<String, dynamic> json) {
    final raw = json['meal'];
    return _MealEnvelope(
      meal: raw is Map<String, dynamic> ? MealRecord.fromJson(raw) : null,
    );
  }

  final MealRecord? meal;

  @override
  _MealEnvelope fromJson(Map<String, dynamic> json) =>
      _MealEnvelope.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}

final class _MealDeleteEnvelope implements BaseModel<_MealDeleteEnvelope> {
  const _MealDeleteEnvelope();

  factory _MealDeleteEnvelope.fromJson(Map<String, dynamic> json) =>
      const _MealDeleteEnvelope();

  @override
  _MealDeleteEnvelope fromJson(Map<String, dynamic> json) =>
      _MealDeleteEnvelope.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}

/// Analiz istemci bekleme süresinde bitmedi; sunucuda sürüyor olabilir.
/// Aynı [analysisId] [MealsRepository.pollAnalysis] ile tekrar yoklanır
/// (yeni hak harcanmaz).
final class PhotoAnalysisPending implements Exception {
  const PhotoAnalysisPending(this.analysisId);

  final String analysisId;
}
