import 'package:equatable/equatable.dart';
import 'package:fastingapp/core/base/model/base_model.dart';

/// API yanıt sarmalayıcısı: `{ status, message, data }`.
///
/// [data] parse'ı, çağıran tarafın verdiği [parser] fonksiyonu ile yapılır.
final class BaseResponse<T extends BaseModel<T>> extends Equatable {
  const BaseResponse({this.status, this.message, this.data});

  factory BaseResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) parser,
  ) {
    final rawData = json['data'];
    return BaseResponse<T>(
      status: json['status'] as String?,
      message: json['message'] as String?,
      data: rawData is Map<String, dynamic> ? parser(rawData) : null,
    );
  }

  final String? status;
  final String? message;
  final T? data;

  @override
  List<Object?> get props => [status, message, data];
}
