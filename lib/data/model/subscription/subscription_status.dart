import 'package:fastingapp/core/base/model/base_model.dart';

/// `GET /v1/subscription` ve `POST /v1/subscription/sync` yanıtı
/// (`data.subscription`). Premium kararı sunucunundur.
final class SubscriptionStatus implements BaseModel<SubscriptionStatus> {
  const SubscriptionStatus({
    required this.isPremium,
    this.status,
    this.productId,
    this.willRenew = false,
    this.expiresAt,
    this.managementUrl,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    final s = json['subscription'] as Map<String, dynamic>? ?? const {};
    final expires = s['expiresAt'];
    return SubscriptionStatus(
      isPremium: s['isPremium'] as bool? ?? false,
      status: s['status'] as String?,
      productId: s['productId'] as String?,
      willRenew: s['willRenew'] as bool? ?? false,
      expiresAt: expires is String
          ? DateTime.tryParse(expires)?.toLocal()
          : null,
      managementUrl: s['managementUrl'] as String?,
    );
  }

  final bool isPremium;

  /// `active`, `billing_issue`, `in_grace`, `expired`, `refunded` ya da null.
  final String? status;
  final String? productId;
  final bool willRenew;
  final DateTime? expiresAt;
  final String? managementUrl;

  @override
  SubscriptionStatus fromJson(Map<String, dynamic> json) =>
      SubscriptionStatus.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {
    'subscription': {
      'isPremium': isPremium,
      'status': status,
      'productId': productId,
      'willRenew': willRenew,
      'expiresAt': expiresAt?.toUtc().toIso8601String(),
      'managementUrl': managementUrl,
    },
  };
}
