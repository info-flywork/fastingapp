// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_guest_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthGuestRequest _$AuthGuestRequestFromJson(Map<String, dynamic> json) =>
    AuthGuestRequest(
      installId: json['installId'] as String?,
      platform: json['platform'] as String?,
      locale: json['locale'] as String?,
      appVersion: json['appVersion'] as String?,
      restoreAccount: json['restoreAccount'] as bool?,
    );

Map<String, dynamic> _$AuthGuestRequestToJson(AuthGuestRequest instance) =>
    <String, dynamic>{
      'installId': ?instance.installId,
      'platform': ?instance.platform,
      'locale': ?instance.locale,
      'appVersion': ?instance.appVersion,
      'restoreAccount': ?instance.restoreAccount,
    };
