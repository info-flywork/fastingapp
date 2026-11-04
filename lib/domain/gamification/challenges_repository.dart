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

  /// `GET /challenges/:code` → sayfa için güncel detay.
  Future<Challenge?> get(String code) async {
    final result = await _network.send<_ChallengeEnvelope>(
      path: '/challenges/$code',
      method: RequestType.get,
      parserModel: _ChallengeEnvelope.fromJson,
    );
    return result?.challenge;
  }

  /// `GET /challenges/:code/participants` → ilerlemeye göre ilk 50. Rıza
  /// vermeyenlerin adı/avatarı gelmez (anonim gösterilir).
  Future<ChallengeParticipants> participants(String code) async {
    final result = await _network.send<ChallengeParticipants>(
      path: '/challenges/$code/participants',
      method: RequestType.get,
      parserModel: ChallengeParticipants.fromJson,
    );
    return result ?? const ChallengeParticipants();
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
    this.description,
    this.targetCount = 0,
    this.durationDays = 0,
    this.rewardXp = 0,
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
      description: json['description'] as String?,
      targetCount: (json['targetCount'] as num?)?.toInt() ?? 0,
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 0,
      rewardXp: (json['rewardXp'] as num?)?.toInt() ?? 0,
      isPremium: json['isPremium'] as bool? ?? false,
      participantsCount: (json['participantsCount'] as num?)?.toInt() ?? 0,
      participantAvatars: ChallengeAvatarPreview.listFrom(avatars),
      my: myRaw is Map<String, dynamic>
          ? ChallengeProgress.fromJson(myRaw)
          : null,
    );
  }

  final String code;
  final String title;
  final String subtitle;
  final String? description;
  final int targetCount;
  final int durationDays;
  final int rewardXp;
  final bool isPremium;
  final int participantsCount;

  /// Ana sayfa yüzüğü (en fazla 3): fotoğraf ve/veya baş harf.
  final List<ChallengeAvatarPreview> participantAvatars;

  /// Katıldıysa ilerleme; katılmadıysa null.
  final ChallengeProgress? my;

  bool get joined => my?.status == 'active' || my?.status == 'completed';

  @override
  Challenge fromJson(Map<String, dynamic> json) => Challenge.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {'code': code};
}

/// Ana sayfa yüzüğündeki bir yüz: fotoğraf ve/veya baş harf.
final class ChallengeAvatarPreview {
  const ChallengeAvatarPreview({this.url, this.initials});

  factory ChallengeAvatarPreview.fromJson(Map<String, dynamic> json) =>
      ChallengeAvatarPreview(
        url: json['url'] as String?,
        initials: json['initials'] as String?,
      );

  /// Eski `string[]` ve yeni `{url, initials}[]` yanıtlarını tolere eder.
  static List<ChallengeAvatarPreview> listFrom(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is String && item.isNotEmpty)
          ChallengeAvatarPreview(url: item)
        else if (item is Map<String, dynamic>)
          ChallengeAvatarPreview.fromJson(item),
    ];
  }

  final String? url;
  final String? initials;
}

final class ChallengeProgress {
  const ChallengeProgress({
    required this.status,
    this.progress = 0,
    this.target = 0,
    this.windowEnd,
  });

  factory ChallengeProgress.fromJson(Map<String, dynamic> json) =>
      ChallengeProgress(
        status: json['status'] as String? ?? 'active',
        progress: (json['progress'] as num?)?.toInt() ?? 0,
        target: (json['target'] as num?)?.toInt() ?? 0,
        windowEnd: DateTime.tryParse(
          json['windowEnd'] as String? ?? '',
        )?.toLocal(),
      );

  final String status;
  final int progress;
  final int target;

  /// Katılım penceresinin sonu (bu tarihe kadar tamamlanmalı).
  final DateTime? windowEnd;

  bool get completed => status == 'completed';
}

/// Katılımcı listesindeki bir satır. Kullanıcı kimliği hiç gelmez.
final class ChallengeParticipant {
  const ChallengeParticipant({
    required this.rank,
    this.isMe = false,
    this.displayName,
    this.avatarUrl,
    this.progress = 0,
    this.target = 0,
    this.completed = false,
  });

  factory ChallengeParticipant.fromJson(Map<String, dynamic> json) =>
      ChallengeParticipant(
        rank: (json['rank'] as num?)?.toInt() ?? 0,
        isMe: json['isMe'] as bool? ?? false,
        displayName: json['displayName'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        progress: (json['progress'] as num?)?.toInt() ?? 0,
        target: (json['target'] as num?)?.toInt() ?? 0,
        completed: json['status'] == 'completed',
      );

  final int rank;
  final bool isMe;

  /// Rıza yoksa null → anonim ("Mochi kullanıcısı") gösterilir.
  final String? displayName;
  final String? avatarUrl;
  final int progress;
  final int target;
  final bool completed;
}

final class ChallengeParticipants implements BaseModel<ChallengeParticipants> {
  const ChallengeParticipants({this.total = 0, this.items = const []});

  factory ChallengeParticipants.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    return ChallengeParticipants(
      total: (json['total'] as num?)?.toInt() ?? 0,
      items: items is List
          ? items
                .whereType<Map<String, dynamic>>()
                .map(ChallengeParticipant.fromJson)
                .toList()
          : const [],
    );
  }

  final int total;
  final List<ChallengeParticipant> items;

  @override
  ChallengeParticipants fromJson(Map<String, dynamic> json) =>
      ChallengeParticipants.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {'total': total};
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
