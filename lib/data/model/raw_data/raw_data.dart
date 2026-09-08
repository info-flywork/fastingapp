import 'package:equatable/equatable.dart';
import 'package:fastingapp/core/base/model/base_model.dart';

/// Şemasız/serbest JSON yanıtları için genel sarmalayıcı.
final class RawData extends Equatable implements BaseModel<RawData> {
  const RawData(this.data);

  factory RawData.fromJson(Map<String, dynamic> json) => RawData(json);

  final Map<String, dynamic> data;

  @override
  RawData fromJson(Map<String, dynamic> json) => RawData.fromJson(json);

  @override
  Map<String, dynamic> toJson() => data;

  @override
  List<Object?> get props => [data];
}
