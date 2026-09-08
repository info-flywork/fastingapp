// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_register_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthRegisterRequest _$AuthRegisterRequestFromJson(Map<String, dynamic> json) =>
    AuthRegisterRequest(
      provider: json['provider'] as String?,
      idToken: json['idToken'] as String?,
      deviceId: json['deviceId'] as String?,
    );

Map<String, dynamic> _$AuthRegisterRequestToJson(
  AuthRegisterRequest instance,
) => <String, dynamic>{
  'provider': instance.provider,
  'idToken': instance.idToken,
  'deviceId': instance.deviceId,
};
