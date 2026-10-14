import 'dart:async';
import 'dart:convert';

import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/core/managers/shared_pref_manager.dart';
import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/core/utils/enum/request_type.dart';
import 'package:fastingapp/data/model/user/home_summary.dart';
import 'package:fastingapp/data/model/user/user.dart';

/// Profil güncelleme, premium sync, hesap silme. (Doküman 7)
final class UserRepository {
  UserRepository(this._networkManager);

  final NetworkManager _networkManager;

  Future<User> getCurrentUser() async {
    final result = await _networkManager.send<User>(
      path: '/user/me',
      method: RequestType.get,
      parserModel: User.fromJson,
    );
    return result ?? const User();
  }

  /// Ana sayfa özeti (tek çağrı). Yanıt cihaza da yazılır: bir sonraki
  /// açılışta ana sayfa ağı beklemeden çizilir ([cachedSummary]).
  Future<HomeSummary> getSummary() async {
    Map<String, dynamic>? raw;
    final result = await _networkManager.send<HomeSummary>(
      path: '/user/summary',
      method: RequestType.get,
      parserModel: (json) {
        raw = json;
        return HomeSummary.fromJson(json);
      },
    );
    if (result == null) throw StateError('Özet boş');
    final body = raw;
    if (body != null) {
      final copy = Map<String, dynamic>.of(body)..remove('serverTime');
      final encoded = jsonEncode(copy);
      lastSummaryUnchanged = encoded == _lastSummaryJson;
      _lastSummaryJson = encoded;
      if (!lastSummaryUnchanged) unawaited(_persist(encoded));
    }
    return result;
  }

  String? _lastSummaryJson;

  /// Son [getSummary] yanıtı (saat hariç) bir öncekiyle aynı mı: aynıysa
  /// ana sayfa yeniden çizilmez.
  bool lastSummaryUnchanged = false;

  /// Bugün alınmış ve [userId]'ye ait saklı özet; yoksa null.
  /// Saat bilgisi (`serverTime`) atılmıştır: eski fark canlı sayaçları kaydırmasın.
  HomeSummary? cachedSummary(String? userId) {
    if (userId == null || userId.isEmpty) return null;
    try {
      final saved = SharedPrefManager.instance.homeSummary;
      if (saved == null || saved.day != _today()) return null;
      final summary = HomeSummary.fromJson(
        jsonDecode(saved.json) as Map<String, dynamic>,
      );
      return summary.user.id == userId ? summary : null;
    } on Object {
      return null;
    }
  }

  Future<void> _persist(String encoded) async {
    try {
      await SharedPrefManager.instance.setHomeSummary(encoded, _today());
    } on Object {
      // Önbellek yazılamazsa sorun değil.
    }
  }

  static String _today() {
    final d = DateTime.now();
    return '${d.year}-${d.month}-${d.day}';
  }

  Future<bool> isPremium() async {
    final user = await getCurrentUser();
    return user.isPremium;
  }

  /// Yasal metin sürümü değiştiyse yeniden onay gereken türler
  /// (`GET /user/me` → `requiredConsents`, ör. `['terms', 'privacy']`).
  Future<List<String>> requiredConsents() async {
    final result = await _networkManager.send<_ConsentState>(
      path: '/user/me',
      method: RequestType.get,
      parserModel: _ConsentState.fromJson,
    );
    return result?.required ?? const [];
  }

  /// Güncel sürümlere onay (`POST /user/consents`, `source: prompt`).
  Future<void> acceptConsents(List<String> types) async {
    final legal = await _networkManager.send<_LegalVersions>(
      path: '/app/config',
      method: RequestType.get,
      parserModel: _LegalVersions.fromJson,
    );
    for (final type in types) {
      final version = type == 'terms' ? legal?.terms : legal?.privacy;
      if (version == null) continue;
      await _networkManager.send<_ConsentState>(
        path: '/user/consents',
        method: RequestType.post,
        data: {
          'type': type,
          'version': version,
          'granted': true,
          'source': 'prompt',
        },
        parserModel: (_) => const _ConsentState(),
      );
    }
  }
}

final class _ConsentState implements BaseModel<_ConsentState> {
  const _ConsentState({this.required = const []});

  factory _ConsentState.fromJson(Map<String, dynamic> json) => _ConsentState(
    required: [
      for (final t in json['requiredConsents'] as List? ?? const [])
        if (t is String) t,
    ],
  );

  final List<String> required;

  @override
  _ConsentState fromJson(Map<String, dynamic> json) =>
      _ConsentState.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {'requiredConsents': required};
}

final class _LegalVersions implements BaseModel<_LegalVersions> {
  const _LegalVersions({this.terms, this.privacy});

  factory _LegalVersions.fromJson(Map<String, dynamic> json) {
    final legal = json['legal'] as Map<String, dynamic>? ?? const {};
    return _LegalVersions(
      terms: legal['termsVersion'] as String?,
      privacy: legal['privacyVersion'] as String?,
    );
  }

  final String? terms;
  final String? privacy;

  @override
  _LegalVersions fromJson(Map<String, dynamic> json) =>
      _LegalVersions.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}
