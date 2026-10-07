import 'package:equatable/equatable.dart';
import 'package:fastingapp/core/base/model/base_model.dart';

/// `DELETE /user/me` yanıtı: hesap [scheduledFor] anında kalıcı silinir.
final class AccountDeletion extends Equatable
    implements BaseModel<AccountDeletion> {
  const AccountDeletion({
    required this.scheduledFor,
    this.hasActiveSubscription = false,
  });

  factory AccountDeletion.fromJson(Map<String, dynamic> json) =>
      AccountDeletion(
        scheduledFor: DateTime.parse(json['scheduledFor'] as String),
        hasActiveSubscription: json['hasActiveSubscription'] as bool? ?? false,
      );

  final DateTime scheduledFor;

  /// Mağaza aboneliği uygulamadan iptal edilemez; kullanıcıya söylenir.
  final bool hasActiveSubscription;

  @override
  AccountDeletion fromJson(Map<String, dynamic> json) =>
      AccountDeletion.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {
    'scheduledFor': scheduledFor.toIso8601String(),
    'hasActiveSubscription': hasActiveSubscription,
  };

  @override
  List<Object?> get props => [scheduledFor, hasActiveSubscription];
}
