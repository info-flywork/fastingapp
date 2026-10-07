import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/core/managers/auth_cache_manager.dart';
import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/core/utils/enum/request_type.dart';
import 'package:fastingapp/data/model/onboarding/onboarding_result.dart';
import 'package:fastingapp/domain/auth/auth_repository.dart';
import 'package:fastingapp/domain/onboarding/onboarding_draft.dart';

/// Onboarding cevaplarının gönderimi (`POST /user/onboarding`, tek transaction).
/// Misafir oturumu yoksa önce açılır (onboarding başında açılamadıysa).
final class OnboardingRepository {
  OnboardingRepository(
    this._networkManager,
    this._authCacheManager,
    this._authRepository,
    this.draft,
  );

  final NetworkManager _networkManager;
  final AuthCacheManager _authCacheManager;
  final AuthRepository _authRepository;
  final OnboardingDraft draft;

  /// Son başarılı gönderimin sonucu (projeksiyon ekranı okur).
  OnboardingResult? lastResult;

  /// Onboarding başında misafir oturumu (hata yutulur; gönderimde tekrar denenir).
  Future<void> ensureSession() async {
    if (await _authRepository.isAuthenticated()) return;
    await _authRepository.loginAsGuest();
  }

  Future<OnboardingResult> submit() async {
    final missing = draft.missing;
    if (missing.isNotEmpty) {
      throw StateError('Onboarding eksik: ${missing.join(', ')}');
    }
    await ensureSession();
    final legal = await _legalVersions();
    final result = await _networkManager.send<OnboardingResult>(
      path: '/user/onboarding',
      method: RequestType.post,
      data: draft.toRequest(
        termsVersion: legal.terms,
        privacyVersion: legal.privacy,
      ),
      parserModel: OnboardingResult.fromJson,
    );
    if (result == null) throw StateError('Onboarding yanıtı boş');
    await _authCacheManager.saveUser(result.user);
    return lastResult = result;
  }

  /// Kabul edilen yasal metin sürümleri (`GET /app/config` → `legal`).
  Future<({String terms, String privacy})> _legalVersions() async {
    const fallback = (terms: '2026-10', privacy: '2026-10');
    try {
      final config = await _networkManager.send<_LegalConfig>(
        path: '/app/config',
        method: RequestType.get,
        parserModel: _LegalConfig.fromJson,
      );
      return (
        terms: config?.termsVersion ?? fallback.terms,
        privacy: config?.privacyVersion ?? fallback.privacy,
      );
    } on Exception {
      return fallback;
    }
  }
}

final class _LegalConfig implements BaseModel<_LegalConfig> {
  const _LegalConfig({this.termsVersion, this.privacyVersion});

  factory _LegalConfig.fromJson(Map<String, dynamic> json) {
    final legal = json['legal'] as Map<String, dynamic>? ?? const {};
    return _LegalConfig(
      termsVersion: legal['termsVersion'] as String?,
      privacyVersion: legal['privacyVersion'] as String?,
    );
  }

  final String? termsVersion;
  final String? privacyVersion;

  @override
  _LegalConfig fromJson(Map<String, dynamic> json) =>
      _LegalConfig.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}
