import 'package:equatable/equatable.dart';
import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

/// Kullanıcı API modeli.
@JsonSerializable()
final class User extends Equatable implements BaseModel<User> {
  const User({
    this.id,
    this.name,
    this.email,
    this.isPremium = false,
    this.isAnsweredQuestions = false,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  final String? id;
  final String? name;
  final String? email;
  final bool isPremium;
  final bool isAnsweredQuestions;

  @override
  User fromJson(Map<String, dynamic> json) => User.fromJson(json);

  @override
  Map<String, dynamic> toJson() => _$UserToJson(this);

  @override
  List<Object?> get props => [id, name, email, isPremium, isAnsweredQuestions];
}
