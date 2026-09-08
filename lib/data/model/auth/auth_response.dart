import 'package:equatable/equatable.dart';
import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/data/model/token/token.dart';
import 'package:fastingapp/data/model/user/user.dart';
import 'package:json_annotation/json_annotation.dart';

part 'auth_response.g.dart';

/// Giriş/kayıt yanıtı: token + kullanıcı.
@JsonSerializable()
final class AuthResponse extends Equatable
    implements BaseModel<AuthResponse> {
  const AuthResponse({this.token, this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);

  final Token? token;
  final User? user;

  @override
  AuthResponse fromJson(Map<String, dynamic> json) =>
      AuthResponse.fromJson(json);

  @override
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);

  @override
  List<Object?> get props => [token, user];
}
