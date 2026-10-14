import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/core/utils/enum/request_type.dart';

/// Challenge'lar (`/v1/challenges/*`). Öne çıkan challenge ana sayfa
/// özetinde gelir (`/user/summary.featuredChallenge`).
final class ChallengesRepository {
  const ChallengesRepository(this._network);

  final NetworkManager _network;

  /// Katılır; premium challenge premium değilken `402 PREMIUM_REQUIRED`.
  Future<Challenge?> join(String code) async {
    final result = await _network.send<_ChallengeEnvelope>(
      path: '/challenges/$code/join',
      method: RequestType.post,
      parserModel: _ChallengeEnvelope.fromJson,
    );
    return result?.challenge;
  }

  /// `POST /challenges/:code/leave`.
  Future<void> leave(String code) async {
    await _network.send<_ChallengeEnvelope>(
      path: '/challenges/$code/leave',
      method: RequestType.post,
      data: const <String, dynamic>{},
      parserModel: _ChallengeEnvelope.fromJson,
    );
  }
}

final class Challenge implements BaseModel<Challenge> {
  const Challenge({
    required this.code,
    required this.title,
    this.subtitle = '',
    this.isPremium = false,
    this.participantsCount = 0,
    this.participantAvatars = const [],
    this.my,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    final myRaw = json['my'];
    final avatars = json['participantAvatars'];
    return Challenge(
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      isPremium: json['isPremium'] as bool? ?? false,
      participantsCount: (json['participantsCount'] as num?)?.toInt() ?? 0,
      participantAvatars: avatars is List
          ? avatars.whereType<String>().toList()
          : const [],
      my: myRaw is Map<String, dynamic>
          ? ChallengeProgress.fromJson(myRaw)
          : null,
    );
  }

  final String code;
  final String title;
  final String subtitle;
  final bool isPremium;
  final int participantsCount;

  /// Katılımcı avatar URL'leri (en fazla birkaç tane).
  final List<String> participantAvatars;

  /// Katıldıysa ilerleme; katılmadıysa null.
  final ChallengeProgress? my;

  bool get joined => my?.status == 'active' || my?.status == 'completed';

  @override
  Challenge fromJson(Map<String, dynamic> json) => Challenge.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {'code': code};
}

final class ChallengeProgress {
  const ChallengeProgress({
    required this.status,
    this.progress = 0,
    this.target = 0,
  });

  factory ChallengeProgress.fromJson(Map<String, dynamic> json) =>
      ChallengeProgress(
        status: json['status'] as String? ?? 'active',
        progress: (json['progress'] as num?)?.toInt() ?? 0,
        target: (json['target'] as num?)?.toInt() ?? 0,
      );

  final String status;
  final int progress;
  final int target;
}

final class _ChallengeEnvelope implements BaseModel<_ChallengeEnvelope> {
  const _ChallengeEnvelope({this.challenge});

  factory _ChallengeEnvelope.fromJson(Map<String, dynamic> json) {
    final raw = json['challenge'];
    return _ChallengeEnvelope(
      challenge: raw is Map<String, dynamic> ? Challenge.fromJson(raw) : null,
    );
  }

  final Challenge? challenge;

  @override
  _ChallengeEnvelope fromJson(Map<String, dynamic> json) =>
      _ChallengeEnvelope.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}
