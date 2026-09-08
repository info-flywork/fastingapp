import 'package:equatable/equatable.dart';
import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_progress.g.dart';

/// Kullanıcı ilerleme verisi.
@JsonSerializable()
final class UserProgress extends Equatable
    implements BaseModel<UserProgress> {
  const UserProgress({
    this.level = 0,
    this.streakDays = 0,
    this.completedFasts = 0,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) =>
      _$UserProgressFromJson(json);

  final int level;
  final int streakDays;
  final int completedFasts;

  @override
  UserProgress fromJson(Map<String, dynamic> json) =>
      UserProgress.fromJson(json);

  @override
  Map<String, dynamic> toJson() => _$UserProgressToJson(this);

  @override
  List<Object?> get props => [level, streakDays, completedFasts];
}
