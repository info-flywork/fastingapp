import 'package:equatable/equatable.dart';
import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'token.g.dart';

/// JWT access/refresh token çifti.
@JsonSerializable()
final class Token extends Equatable implements BaseModel<Token> {
  const Token({this.accessToken, this.refreshToken});

  factory Token.fromJson(Map<String, dynamic> json) => _$TokenFromJson(json);

  final String? accessToken;
  final String? refreshToken;

  @override
  Token fromJson(Map<String, dynamic> json) => Token.fromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TokenToJson(this);

  @override
  List<Object?> get props => [accessToken, refreshToken];
}
