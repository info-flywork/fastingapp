import 'package:equatable/equatable.dart';
import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/data/model/token/token.dart';
import 'package:json_annotation/json_annotation.dart';

part 'auth_data.g.dart';

/// Auth alt verisi (ör. yenilenen token bilgisi).
@JsonSerializable()
final class AuthData extends Equatable implements BaseModel<AuthData> {
  const AuthData({this.token});

  factory AuthData.fromJson(Map<String, dynamic> json) =>
      _$AuthDataFromJson(json);

  final Token? token;

  @override
  AuthData fromJson(Map<String, dynamic> json) => AuthData.fromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AuthDataToJson(this);

  @override
  List<Object?> get props => [token];
}
