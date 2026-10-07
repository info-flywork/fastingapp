import 'package:equatable/equatable.dart';
import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'auth_guest_request.g.dart';

/// Misafir oturumu isteği (`POST /auth/guest`).
@JsonSerializable(includeIfNull: false)
final class AuthGuestRequest extends Equatable
    implements BaseModel<AuthGuestRequest> {
  const AuthGuestRequest({
    this.installId,
    this.platform,
    this.locale,
    this.appVersion,
    this.restoreAccount,
  });

  factory AuthGuestRequest.fromJson(Map<String, dynamic> json) =>
      _$AuthGuestRequestFromJson(json);

  /// Kurulum kimliği (UUID); cihaz başına tek misafir.
  final String? installId;
  final String? platform;
  final String? locale;
  final String? appVersion;

  /// Silme talebi bekleyen hesabı geri aç (409 ACCOUNT_PENDING_DELETION).
  final bool? restoreAccount;

  @override
  AuthGuestRequest fromJson(Map<String, dynamic> json) =>
      AuthGuestRequest.fromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AuthGuestRequestToJson(this);

  @override
  List<Object?> get props => [
    installId,
    platform,
    locale,
    appVersion,
    restoreAccount,
  ];
}
