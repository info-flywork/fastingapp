import 'package:equatable/equatable.dart';
import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'auth_register_request.g.dart';

/// Sosyal giriş / kayıt isteği (`POST /auth/register`).
@JsonSerializable(includeIfNull: false)
final class AuthRegisterRequest extends Equatable
    implements BaseModel<AuthRegisterRequest> {
  const AuthRegisterRequest({
    this.provider,
    this.idToken,
    this.deviceId,
    this.fullName,
    this.platform,
    this.locale,
    this.restoreAccount,
  });

  factory AuthRegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$AuthRegisterRequestFromJson(json);

  /// `firebase` (Apple/Google) ya da `guest`.
  final String? provider;

  /// Firebase ID token.
  final String? idToken;

  /// Kurulum kimliği (UUID).
  final String? deviceId;

  /// `{givenName, familyName}`; Apple adı yalnızca ilk girişte gelir.
  final Map<String, String?>? fullName;
  final String? platform;
  final String? locale;

  /// Silme talebi bekleyen hesabı geri aç (409 ACCOUNT_PENDING_DELETION).
  final bool? restoreAccount;

  @override
  AuthRegisterRequest fromJson(Map<String, dynamic> json) =>
      AuthRegisterRequest.fromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AuthRegisterRequestToJson(this);

  @override
  List<Object?> get props => [
    provider,
    idToken,
    deviceId,
    fullName,
    platform,
    locale,
    restoreAccount,
  ];
}
