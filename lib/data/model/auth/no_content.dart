import 'package:equatable/equatable.dart';
import 'package:fastingapp/core/base/model/base_model.dart';

/// Boş (204 / veri içermeyen) response modeli. (Doküman 6)
final class NoContent extends Equatable implements BaseModel<NoContent> {
  const NoContent();

  // ignore: avoid_unused_constructor_parameters
  factory NoContent.fromJson(Map<String, dynamic> json) => const NoContent();

  @override
  NoContent fromJson(Map<String, dynamic> json) => const NoContent();

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  List<Object?> get props => [];
}
