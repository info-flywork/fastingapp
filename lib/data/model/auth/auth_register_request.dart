import 'package:equatable/equatable.dart';
import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'auth_register_request.g.dart';

/// Sosyal giriş / kayıt isteği.
@JsonSerializable()
final class AuthRegisterRequest extends Equatable
    implements BaseModel<AuthRegisterRequest> {
  const AuthRegisterRequest({this.provider, this.idToken, this.deviceId});

  factory AuthRegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$AuthRegisterRequestFromJson(json);

  final String? provider;
  final String? idToken;
  final String? deviceId;

  @override
  AuthRegisterRequest fromJson(Map<String, dynamic> json) =>
      AuthRegisterRequest.fromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AuthRegisterRequestToJson(this);

  @override
  List<Object?> get props => [provider, idToken, deviceId];
}
