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
      fullName: (json['fullName'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String?),
      ),
      platform: json['platform'] as String?,
      locale: json['locale'] as String?,
      restoreAccount: json['restoreAccount'] as bool?,
    );

Map<String, dynamic> _$AuthRegisterRequestToJson(
  AuthRegisterRequest instance,
) => <String, dynamic>{
  'provider': ?instance.provider,
  'idToken': ?instance.idToken,
  'deviceId': ?instance.deviceId,
  'fullName': ?instance.fullName,
  'platform': ?instance.platform,
  'locale': ?instance.locale,
  'restoreAccount': ?instance.restoreAccount,
};
