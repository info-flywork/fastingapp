import 'package:equatable/equatable.dart';
import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/data/model/user/user.dart';
import 'package:fastingapp/data/model/user/user_progress.dart';
import 'package:json_annotation/json_annotation.dart';

part 'summary_response.g.dart';

/// Kullanıcı özeti: profil + ilerleme birleşimi.
@JsonSerializable()
final class SummaryResponse extends Equatable
    implements BaseModel<SummaryResponse> {
  const SummaryResponse({this.user, this.progress});

  factory SummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$SummaryResponseFromJson(json);

  final User? user;
  final UserProgress? progress;

  @override
  SummaryResponse fromJson(Map<String, dynamic> json) =>
      SummaryResponse.fromJson(json);

  @override
  Map<String, dynamic> toJson() => _$SummaryResponseToJson(this);

  @override
  List<Object?> get props => [user, progress];
}
